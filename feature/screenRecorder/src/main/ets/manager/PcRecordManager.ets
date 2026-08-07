/*
 * Copyright (c) Huawei Device Co., Ltd. 2026. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* instrument ignore file */
import { GlobalThisUtil, LogUtil } from '@ohos/common';
import lazy { HashMap } from '@kit.ArkTS';
import lazy { display, screen } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import common from '@ohos.app.ability.common';
import { DisplayId } from '@ohos/common/src/main/ets/util/DisplayUtil';
import { ExpansionScreenUtil } from '../util/ExpansionScreenUtil';
import { PcRecorderConfig } from './config/PcRecorderConfigImpl';
import { PcWindowManager } from './PcWindowManager';
import { RecorderFileManager } from './RecorderFileManager';
import { RecordManager } from './RecordManager';
import { CURRENT_SELECTED_DISPLAY, MASKING_READY_TASK_ID, SCREENRECORDER_CURSOR, SELECT_DISPLAY_ID } from './types';

/* instrument ignore file */
const TAG = 'PcRecordManager';

/**
 * Recording management tool class
 *
 * @since 2025-07-03
 */
export class PcRecordManager extends RecordManager {
  private static pcInstance: PcRecordManager;
  private pcDisplayScreenModeMap: HashMap<number | undefined, number | undefined> = new HashMap();
  private pcGlobalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private isBcRecorderTemp: boolean = false;
  private pcWindowManagerInstance: PcWindowManager;

  constructor(recorderFileManager: RecorderFileManager, pcWindowManagerInstance: PcWindowManager) {
    super(recorderFileManager, pcWindowManagerInstance, new PcRecorderConfig());
    this.pcWindowManagerInstance = pcWindowManagerInstance;
  }

  public static getInstance(): PcRecordManager {
    if (!PcRecordManager.pcInstance) {
      PcRecordManager.pcInstance =
        new PcRecordManager(RecorderFileManager.getInstance(), PcWindowManager.getInstance());
      RecordManager.instance = PcRecordManager.pcInstance;
    }
    return PcRecordManager.pcInstance;
  }

  /**
   * 是否是全屏录屏
   *
   * @returns true 全屏录屏
   */
  public isBCRecord(): boolean {
    return this.isBcRecorderTemp;
  }

  async trigger(triggerType: string, selectId: number | undefined, isBCRecord: boolean): Promise<void> {
    if (super.getIsRecording()) {
      await this.triggerAgain(triggerType);
      return;
    }
    (this.getRecorderConfig() as PcRecorderConfig).setIsBcRecorder(isBCRecord);

    // 获取屏幕信息
    let displays = await ExpansionScreenUtil.getAllDisplays();
    if (displays.length === 0) {
      return;
    }
    this.initData();

    // PC普通录屏
    if (displays.length === 1) {
      await this.startTrigger(displays[0].id);
      return;
    }

    // 是否是BC录屏
    let isNormalHalfFolded: boolean = ExpansionScreenUtil.isNormalHalfFoldedWithoutExpansion(displays);
    if (selectId !== undefined || isNormalHalfFolded) {
      this.isBcRecorderTemp = isBCRecord ? isBCRecord : selectId === undefined;
      this.isBcRecorderTemp = this.isBcRecorderTemp && isNormalHalfFolded;
      (this.getRecorderConfig() as PcRecorderConfig).setIsBcRecorder(this.isBcRecorderTemp);
      selectId = selectId !== undefined ? selectId : 0;
      this.startTrigger(selectId);
      this.registerMaskDisplayListener();
      return;
    }

    this.registerMaskDisplayListener();
    // 处理扩展屏蒙层初始化流程
    await this.pcWindowManagerInstance.destroyMaskWindow();
    for (let display of displays) {
      LogUtil.info(TAG, `trigger init display: ${display.id}-${display.name}`);
      await this.pcWindowManagerInstance.initMaskWindow(display.id);
    }
    displays.sort((display1, display2) => {
      return display2.id - display1.id;
    }).forEach(value => {
      this.pcWindowManagerInstance!.setWindowPontStyle(value.id, SCREENRECORDER_CURSOR);
    })

    // 注册屏幕change监听器
    screen.on('change', this.handleScreenChange);
  }

  /**
   * 处理屏幕变化
   *
   * @param displayId 屏幕id
   */
  private async handleScreenChange(displayId: number) {
    LogUtil.warn(TAG,
      `handleScreenChange displayId: ${displayId} displayScreenModeMap size: ${this.pcDisplayScreenModeMap.length}`);
    const selectDisplayId = this.pcGlobalThisInstance.getObject(SELECT_DISPLAY_ID);

    try {
      const screens = await screen.getAllScreens();
      for (const screen of screens) {
        const screenId = screen.id;
        if (!this.pcDisplayScreenModeMap.hasKey(screenId)) {
          continue;
        }
        const oldSourceMode = this.pcDisplayScreenModeMap.get(screenId);
        if (oldSourceMode !== screen.sourceMode && selectDisplayId === displayId) {
          this.pcGlobalThisInstance.setObject(SELECT_DISPLAY_ID, undefined);
          this.setStopTime(Date.now());
          await this.stop();
          break;
        }
      }
      LogUtil.info('handleScreenChange Succeeded in getting all screens.');
    } catch (err) {
      LogUtil.error(`handleScreenChange Failed to get all screens. Cause: ${JSON.stringify(err.message)}`);
    }
  }

  async startTrigger(displayId: number | undefined = undefined): Promise<void> {
    this.pcGlobalThisInstance.setObject(SELECT_DISPLAY_ID, displayId);
    await this.pcWindowManagerInstance.destroyMaskWindow();
    this.unRegisterMaskDisplayListener();
    LogUtil.warn(TAG, `startTrigger displayId: ${displayId}`);
    super.startTrigger(displayId);
  }

  async triggerAgain(triggerType: string): Promise<void> {
    super.triggerAgain(triggerType);
  }

  async stop(isAutomaticStop?: boolean, width?: number, height?: number): Promise<void> {
    LogUtil.info(TAG, 'to stop recording')
    try {
      display.off('remove', this.displayRemoveListener);
      screen.off('change', this.handleScreenChange.bind(this));
    } catch (error) {
      LogUtil.error(TAG, 'RecordManager off display remove failed', (error as BusinessError).message);
    }

    await super.stop(isAutomaticStop, width, height);
    this.pcGlobalThisInstance!.setObject('pcLastRequestTime', 0);
  }

  /**
   * 显示器移除监听器，需要停止录屏
   */
  public displayRemoveListener = async (displayId: number) => {
    //接了扩展屏，启动录屏应用选择被录制屏幕时拔掉扩展屏，录屏终止
    let isSelectingDisplay: boolean = !super.getIsRecording();
    LogUtil.warn(TAG, `isSelectingDisplay:${isSelectingDisplay} displayId:${displayId}`);
    if (isSelectingDisplay) {
      setTimeout(async () => {
        const context =
          GlobalThisUtil.getInstance()!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
        context!.terminateSelf();
      }, 500);
      return;
    }
    // 录B+C ,或上半屏，或下半屏。开始录屏后，展开了屏幕，或呼出了键盘，或放置了磁吸键盘。录屏都要结束。
    // 这三种情况，都会触发remove下半屏id是999的事件。
    // Hopper悬停态接扩展屏，录扩展屏，Hopper折展，放键盘，呼出键盘，都继续录屏。
    let isRemoveLowerDisplay: boolean =
      displayId === DisplayId.LOWER_OF_FOLD_DEVICE && this.isRecorderFoldDisplay();
    // 接的扩展屏，录的也是扩展屏，移除的也是那个扩展屏。录屏停止。
    let isRecordingDisplayRemoved: boolean =
      this.pcGlobalThisInstance.getObject(SELECT_DISPLAY_ID) as number === displayId;
    LogUtil.warn(TAG,
      `stop recorder isRemoveLowerDisplay: ${isRemoveLowerDisplay}, isRecordingDisplayRemoved: ${isRecordingDisplayRemoved}, `);
    if (isRemoveLowerDisplay || isRecordingDisplayRemoved) {
      this.pcGlobalThisInstance.setObject(SELECT_DISPLAY_ID, undefined);
      this.setStopTime(Date.now());
      await this.stop();
    }
  }

  /**
   * 录屏录制的折叠屏的上屏，下屏，或者全屏。
   *
   * @returns true满足条件
   */
  public isRecorderFoldDisplay() {
    if (GlobalThisUtil.getInstance().getObject(SELECT_DISPLAY_ID) === undefined) {
      return false;
    }
    let recorderId: number = GlobalThisUtil.getInstance().getObject(SELECT_DISPLAY_ID) as number;
    return recorderId === DisplayId.DEFAULT || recorderId === DisplayId.LOWER_OF_FOLD_DEVICE;
  }

  /**
   * 注册普通全局录屏显示器变动监听
   */
  async registerMaskDisplayListener(): Promise<void> {
    LogUtil.info(TAG, `registerMaskDisplayListener.`);
    try {
      display.on('add', this.pcWindowManagerInstance?.displayMaskAddListener);
      display.on('remove', this.pcWindowManagerInstance?.displayMaskRemoveListener);
      display.on('remove', this.displayRemoveListener);
    } catch (e) {
      LogUtil.error(TAG, `registerMaskDisplayListener failed code: ${e?.code}, message: ${e?.message}`);
    }
  }

  /**
   * 移除普通全局录屏显示器变动监听
   */
  async unRegisterMaskDisplayListener(): Promise<void> {
    LogUtil.info(TAG, `unRegisterMaskDisplayListener.`);
    try {
      display.off('add', this.pcWindowManagerInstance?.displayMaskAddListener);
      display.off('remove', this.pcWindowManagerInstance?.displayMaskRemoveListener);
    } catch (e) {
      LogUtil.error(TAG, `unRegisterMaskDisplayListener failed code: ${e?.code}, message: ${e?.message}`);
    }
  }

  initData() {
    AppStorage.setOrCreate(CURRENT_SELECTED_DISPLAY, undefined);
    AppStorage.setOrCreate(MASKING_READY_TASK_ID, undefined);
    this.pcDisplayScreenModeMap.clear();
  }
}