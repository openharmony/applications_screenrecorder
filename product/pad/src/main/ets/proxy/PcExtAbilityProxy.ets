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

import {
  CommonEventUtil,
  EVENT_NAME,
  EVENT_SUBSCRIBER_INFO,
  EventReportUtil,
  GlobalThisUtil,
  LogUtil,
  PreferencesKey,
  PreferenceUtils,
  StartChoosePanelType,
  StartRecordTriggerType,
  StopRecordTriggerType,
  UNKNOWN_REASON
} from '@ohos/common';
import {
  NotificationManager,
  PcRecordManager,
  PcWindowManager,
  RecorderFileManager,
  RecorderToast
} from '@ohos/screen-recorder';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { Configuration } from '@ohos.app.ability.Configuration';
import Want from '@ohos.app.ability.Want';
import { BusinessError } from '@ohos.base';
import display from '@ohos.display';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import ExtAbilityProxyUtil from './ExtAbilityProxyUtil';


const TAG = 'ExtAbilityProxy';
const TRIGGER_TYPE = 'trigger_type';
const DEFAULT_TRIGGER_TYPE = 'default_trigger_type';
const SCREEN_LOCK_DURATION = 200;
const DELAY_DURATION = 500;
const MIN_INTERVAL_FOR_TWO_REQUESTS = 1500;
const FILENAME_KEY = 'CustomizedFileName';
const CALLER_NATIVE_NAME_KEY = 'ohos.aafwk.param.callerNativeName';

export class PcExtAbilityProxy {
  private pcRecorderManager: PcRecordManager;
  private windowManagerInstance: PcWindowManager = new PcWindowManager();
  private notificationManager: NotificationManager = NotificationManager.getInstance();
  private dataPreferences: PreferenceUtils = new PreferenceUtils();
  private context: common.ServiceExtensionContext;
  private pcGlobalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private navbarEvent: CommonEventUtil =
    new CommonEventUtil([EVENT_NAME.NAVBAR_EVENT], this.windowManagerInstance.dismissShareWindow);
  private screenOffEvent: CommonEventUtil =
    new CommonEventUtil(EVENT_SUBSCRIBER_INFO.events, this.screenOffStopRecording.bind(this));
  private modeChangeEvent: CommonEventUtil =
    new CommonEventUtil(['CUSTOM_HYBRID_PAD_MODE_CHANGE'], this.screenOffStopRecording.bind(this));
  private lastRequestTime: number = 0;
  private extAbilityProxyUtil: ExtAbilityProxyUtil;

  constructor(context: common.ServiceExtensionContext) {
    this.context = context;
    this.pcRecorderManager = PcRecordManager.getInstance();
    this.extAbilityProxyUtil = new ExtAbilityProxyUtil(context);
  }

  async onCreate(): Promise<void> {
    this.extAbilityProxyUtil.initData();
    this.extAbilityProxyUtil.applyEfficiencyResources();
    this.screenOffEvent.subscribe();
    this.navbarEvent.subscribe();
    this.modeChangeEvent.subscribe();
    Environment.envProp('fontSizeScaleCode', this.context.config.fontSizeScale);
    await NotificationManager.enableNotificationOnce(this.context);
  }

  async onRequest(want: Want, selectId: number | undefined, isBCRecord: boolean): Promise<void> {
    // Save the start time
    this.pcRecorderManager.init();

    let isPermission: boolean = ExtAbilityProxyUtil.checkAbilityPermission(want);
    if (!isPermission || ExtAbilityProxyUtil.isNeedStopRequest()) {
      LogUtil.info(TAG, `isPermission: ${isPermission}`)
      return;
    }

    const currentTime = Date.now();
    // 若当前处于录屏初始化阶段，且离上一次请求间隔小于最小请求间隔，中断请求
    if (this.pcRecorderManager!.getIsRecording() &&
      currentTime - this.lastRequestTime < MIN_INTERVAL_FOR_TWO_REQUESTS) {
      LogUtil.warn(TAG, 'this record is short interval from last request, ignore this request!');
      return;
    }

    this.pcGlobalThisInstance!.setObject('isProcessing', true);
    this.lastRequestTime = currentTime;

    const triggerType = want?.parameters?.[TRIGGER_TYPE] || DEFAULT_TRIGGER_TYPE;
    const callerNativeName = want?.parameters?.[CALLER_NATIVE_NAME_KEY];
    /* instrument ignore if */
    if (selectId !== undefined) {
      EventReportUtil.setStartType(StartRecordTriggerType.TRIGGERED_TYPE_BY_PANEL);
      if (isBCRecord) {
        EventReportUtil.setChoosePanelType(StartChoosePanelType.RECORD_TYPE_BY_FULL_SCREEN);
      } else if (selectId === 0) {
        EventReportUtil.setChoosePanelType(StartChoosePanelType.RECORD_TYPE_BY_UP_SCREEN);
      } else {
        EventReportUtil.setChoosePanelType(StartChoosePanelType.RECORD_TYPE_BY_DOWN_SCREEN);
      }
      LogUtil.warn(TAG, 'ExtAbilityProxy onRequest with triggerType: panel');
    } else {
      EventReportUtil.setStartType(EventReportUtil.getTriggerTypeCodeByReason(triggerType.toString()));
      LogUtil.warn(TAG,
        `ExtAbilityProxy onRequest with triggerType: ${triggerType} callerNativeName: ${callerNativeName}`);
    }

    this.pcGlobalThisInstance.setObject('triggerType', triggerType.toString());
    const fileName = want?.parameters?.[FILENAME_KEY] as string || undefined;
    LogUtil.info(TAG, 'ExtAbilityProxy onRequest with fileName: ' + fileName);
    if (!ExtAbilityProxyUtil.checkFileName(fileName)) {
      LogUtil.error(TAG, 'ExtAbilityProxy onRequest file name not legal, stop recording');
      RecorderToast.getInstance().showToast('file_name_illegal', promptAction.ToastShowMode.SYSTEM_TOP_MOST);
      return;
    }
    this.pcGlobalThisInstance.setObject('fileName', fileName);
    await this.pcRecorderManager.trigger(triggerType.toString(), selectId, isBCRecord);
    this.pcGlobalThisInstance!.setObject('isProcessing', false);
  }

  async onDestroy(): Promise<void> {
    LogUtil.info(TAG, 'ExtAbilityProxy onDestroy');
    backgroundTaskManager.resetAllEfficiencyResources();
    LogUtil.warn(TAG, 'Succeeded in reset applyEfficiencyResources.');
    await this.dataPreferences.setPreferenceKeyValue(PreferencesKey.IS_RECORDING, false);
    try {
      this.navbarEvent.unsubscribe();
      this.screenOffEvent.unsubscribe();
      this.modeChangeEvent.unsubscribe();
    } catch (error) {
      LogUtil.error(TAG, 'ExtAbilityProxy unsubscribe failed:', (error as BusinessError).message);
    }
    this.pcRecorderManager!.release();
    this.pcRecorderManager!.cancelPreferenceListen();

    // 处理PC监听
    this.pcRecorderManager.unRegisterMaskDisplayListener();
    try {
      display.off('remove', this.pcRecorderManager.displayRemoveListener);
    } catch (error) {
      LogUtil.error(TAG, 'ExtAbilityProxy off display remove failed', (error as BusinessError).message);
    }

  }

  onConfigurationUpdate(newConfig: Configuration): void {
      ExtAbilityProxyUtil.needReSendNot(newConfig);
  }

  async screenOffStopRecording() {
    try {
      /* instrument ignore if */
      if (!this.pcRecorderManager!.getIsStart()) {
        await this.errorPhotoHandle();
      }
      if (this.pcGlobalThisInstance!.getObject('isProcessing')) {
        LogUtil.info(TAG, 'Last event is processing, return');
        return;
      }
      this.pcGlobalThisInstance!.setObject('isProcessing', true);

      let timeDiff: number = Date.now() - this.pcRecorderManager.getStartTime()
      if (timeDiff <= SCREEN_LOCK_DURATION) {
        await this.errorPhotoHandle();
      } else if (this.pcRecorderManager!.getIsRecording() && this.pcRecorderManager!.getIsStart()) {
        EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_SCREEN_OFF)
        this.pcRecorderManager.setStopTime(Date.now());
        await this.pcRecorderManager!.stop(true);
        // 延时500毫秒
        await new Promise<number>(resolve => setTimeout(resolve, DELAY_DURATION));
        await this.notificationManager!.sendLockNotification();
        EventReportUtil.setErrorReason(UNKNOWN_REASON);
        EventReportUtil.reportErrorEvent({ 'REASON': EventReportUtil.getErrorReason() })
      }
      this.pcGlobalThisInstance!.setObject('isProcessing', false);
      this.context.terminateSelf();
    } catch (error) {
      LogUtil.error(TAG, 'ExtAbilityProxy createSubscriber failed:', (error as BusinessError).message);
    }
  }

  async errorPhotoHandle() {
    await RecorderFileManager.getInstance().setVideoAssetPending();
    await this.pcRecorderManager!.release();
    this.context.terminateSelf();
  }
};