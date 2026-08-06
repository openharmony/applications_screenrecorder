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
  CommonUtil,
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
  SELECT_DISPLAY_ID,
  PcRecordManager,
  PcWindowManager,
  RecorderFileManager,
  RecorderToast
} from '@ohos/screen-recorder';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { Configuration } from '@ohos.app.ability.Configuration';
import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';
import Want from '@ohos.app.ability.Want';
import { BusinessError } from '@ohos.base';
import display from '@ohos.display';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import screenLock from '@ohos.screenLock';
import { ExpansionScreenUtil, ScreenData } from '@ohos/screen-recorder';
import { JSON } from '@kit.ArkTS';


const TAG = 'ExtAbilityProxy';
const TRIGGER_TYPE = 'trigger_type';
const DEFAULT_TRIGGER_TYPE = 'default_trigger_type';
const SCREEN_LOCK_DURATION = 200;
const DELAY_DURATION = 500;
const MIN_INTERVAL_FOR_TWO_REQUESTS = 1500; // Minimum interval between two screen recording requests
const MULTIMODAL_INPUT_UID = 6696;
const SHELL_UID = 2000;
const SHELL_UID_ROOT = 0;
const FILENAME_MAX = 255;
const FILENAME_REGEX_CHECK: RegExp = new RegExp('[\\[\\]:?*"`\\\'{}\\\\|<>/]');
const FILENAME_SUFFIX = '.mp4';
const FILENAME_KEY = 'CustomizedFileName';
const SCENEBOARD_NAME = 'com.ohos.sceneboard';
const SCREENRECORDER_NAME = 'com.ohos.screenrecorder';
const CALLER_NATIVE_NAME_KEY = 'ohos.aafwk.param.callerNativeName';

// instrument ignore file
export default class ExtAbilityProxy {
  private recordManager: PcRecordManager = PcRecordManager.getInstance();
  private windowManagerInstance: PcWindowManager = new PcWindowManager();
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private notificationManager: NotificationManager = NotificationManager.getInstance();
  private initDisplayWidth?: number;
  private initDisplayHeight?: number;
  private screenOffTime: number = 0;
  private timeDiff: number = 0;
  private context: common.ServiceExtensionContext;
  private dataPreferences: PreferenceUtils = new PreferenceUtils();
  private navbarEvent: CommonEventUtil =
    new CommonEventUtil([EVENT_NAME.NAVBAR_EVENT], this.windowManagerInstance.dismissShareWindow);
  private screenOffEvent: CommonEventUtil =
    new CommonEventUtil(EVENT_SUBSCRIBER_INFO.events, this.screenOffStopRecording.bind(this));
  private onExpandModeChange: Callback<number> = async () => {
    await this.stopIfExpandModeChanged();
  };
  /**
   * 所有镜像屏的screen的mode集合
   */
  private modeMap: Map<number, ScreenData> = new Map<number, ScreenData>();
  private foldListener: () => Promise<void> = async () => {
  };

  constructor(context: common.ServiceExtensionContext) {
    this.context = context;
  }

  async onCreate(): Promise<void> {
    LogUtil.warn(TAG, 'ExtAbilityProxy onCreate');
    this.globalThisInstance!.setObject('screenRecorderContext', this.context);
    this.globalThisInstance!.setObject('windowId', 0);
    this.globalThisInstance!.setObject('preWindowId', 0);
    this.globalThisInstance!.setObject('isPreViewWindowExisting', false);
    this.globalThisInstance!.setObject('previewTimeoutId', undefined);
    this.globalThisInstance!.setObject('darkMode', this.context.config.colorMode);
    this.globalThisInstance!.setObject('isMicClicked', false);
    this.globalThisInstance!.setObject('isTrackClicked', false);
    this.globalThisInstance!.setObject('pcLastRequestTime', 0);

    AppStorage.SetOrCreate<boolean>('isDarkMode',
      this.context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    AppStorage.SetOrCreate<String | undefined>('languageCode', this.context.config.language);
    Environment.envProp('fontSizeScaleCode', this.context.config.fontSizeScale);

    this.applyEfficiencyResources();
    this.screenOffEvent.subscribe();
    this.navbarEvent.subscribe();
    this.setFoldListener();
    await NotificationManager.enableNotificationOnce(this.context);
  }

  /**
   * Subscribe to the screen-off event and shut-down event
   * and stop screen recording when the screen is off or the power is off.
   */
  async screenOffStopRecording() {
    try {
      this.setScreenOffTime(Date.now());
      this.timeDiff = this.screenOffTime - this.recordManager.getStartTime()
      if (!this.recordManager!.getIsStart()) {
        await this.errorPhotoHandle();
      }
      if (this.globalThisInstance!.getObject('isProcessing')) {
        LogUtil.info(TAG, 'Last event is processing, return');
        return;
      }
      this.globalThisInstance!.setObject('isProcessing', true);
      if (this.timeDiff <= SCREEN_LOCK_DURATION) {
        await this.errorPhotoHandle();
      } else if (this.recordManager!.getIsRecording() && this.recordManager!.getIsStart()) {
        EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_SCREEN_OFF)
        this.recordManager.setStopTime(Date.now());
        await this.recordManager!.stop(true);
        await new Promise<number>(resolve => setTimeout(resolve, DELAY_DURATION));
        await this.notificationManager!.sendLockNotification();
        // Error happened when recording, report the runtime error reason
        EventReportUtil.setErrorReason(UNKNOWN_REASON);
        EventReportUtil.reportErrorEvent({
          'REASON': EventReportUtil.getErrorReason()
        })
      }
      this.globalThisInstance!.setObject('isProcessing', false);
      this.context.terminateSelf();
    } catch (error) {
      LogUtil.error(TAG, 'ExtAbilityProxy createSubscriber failed:', (error as BusinessError).message);
    }
  }

  async onRequest(want: Want, selectId: number | undefined, isBCRecord: boolean): Promise<void> {
    this.setModeChangeListener();
    // Save the start time
    this.recordManager.init();
    this.recordManager.setStartTime(Date.now());
    const killProcessTimeoutId = this.globalThisInstance!.getObject('killProcessTimeoutId') as number;
    killProcessTimeoutId && clearTimeout(killProcessTimeoutId);

    let isPermission: boolean = this.checkAbilityPermission(want);
    const isProcessing = this.globalThisInstance!.getObject('isProcessing') as boolean;
    if (!isPermission || isProcessing) {
      LogUtil.error(TAG, `isPermission: ${isPermission}, isProcessing: ${isProcessing}`);
      return;
    }
    this.globalThisInstance!.setObject('isProcessing', true);

    try {
      let isOobeState: boolean = CommonUtil.checkOobeState();
      let isLocked: boolean = screenLock.isLocked();
      let isInStartupAnimation: boolean = CommonUtil.getSystemParameter('bootevent.boot.completed') !== 'true';
      if (isOobeState || isLocked || isInStartupAnimation) {
        LogUtil.warn(TAG,
          `isOobeStatus: ${isOobeState}, isLocked: ${isLocked}, getSystemParameter:${isInStartupAnimation}`);
        return;
      }
      // Traffic limiting is performed when screen recording requests are too frequent.
      const lastRequestTime = this.globalThisInstance!.getObject('pcLastRequestTime') as number;
      const currentTime = Date.now();
      if (currentTime - lastRequestTime < MIN_INTERVAL_FOR_TWO_REQUESTS) {
        LogUtil.warn(TAG, 'this record is short interval from last request, ignore this request!');
        return;
      }
      this.globalThisInstance!.setObject('pcLastRequestTime', currentTime);

      await this.triggerRecorder(want, selectId, isBCRecord);
    } catch (error) {
      LogUtil.error(TAG, 'Request recorder failed because: ', (error as BusinessError).message);
    } finally {
      this.globalThisInstance!.setObject('isProcessing', false);
    }
  }

  async triggerRecorder(want: Want, selectId: number | undefined, isBCRecord: boolean) {
    try {
      this.setStartType(want, selectId, isBCRecord);
      this.setChoosePanelType(selectId, isBCRecord);
      const triggerType = want?.parameters?.[TRIGGER_TYPE] || DEFAULT_TRIGGER_TYPE;
      const fileName = want?.parameters?.[FILENAME_KEY] as string || undefined;
      LogUtil.info(TAG, 'ExtAbilityProxy onRequest with fileName: ' + fileName);
      if (!ExtAbilityProxy.checkFileName(fileName)) {
        LogUtil.error(TAG, 'ExtAbilityProxy onRequest file name not legal, stop recording');
        RecorderToast.getInstance().showToast('file_name_illegal', promptAction.ToastShowMode.SYSTEM_TOP_MOST);
        return;
      }
      this.globalThisInstance.setObject('fileName', fileName);
      if (display.isFoldable()) {
        let initDisplay = display.getDefaultDisplaySync();
        this.initDisplayWidth = initDisplay.width;
        this.initDisplayHeight = initDisplay.height;
      }
      await this.recordManager!.trigger(triggerType.toString(), selectId, isBCRecord);
      this.modeMap = await ExpansionScreenUtil.getScreenModeMap(selectId ?? 0);
    } catch (error) {
      LogUtil.error(TAG, 'triggerRecorder request failed because: ', (error as BusinessError).message);
    }
  }

  private setStartType(want: Want, selectId: number | undefined, isBCRecord: boolean) {
    const triggerType = want?.parameters?.[TRIGGER_TYPE] || DEFAULT_TRIGGER_TYPE;
    const callerNativeName = want?.parameters?.[CALLER_NATIVE_NAME_KEY];
    if (selectId !== undefined) {
      EventReportUtil.setStartType(StartRecordTriggerType.TRIGGERED_TYPE_BY_PANEL);
    } else {
      EventReportUtil.setStartType(EventReportUtil.getTriggerTypeCodeByReason(triggerType.toString()));
      LogUtil.warn(TAG,
        `ExtAbilityProxy onRequest with triggerType: ${triggerType} callerNativeName: ${callerNativeName}`);
    }
    this.globalThisInstance.setObject('triggerType', triggerType.toString());
  }

  private setChoosePanelType(selectId: number | undefined, isBCRecord: boolean) {
    if (selectId !== undefined) {
      if (isBCRecord) {
        EventReportUtil.setChoosePanelType(StartChoosePanelType.RECORD_TYPE_BY_FULL_SCREEN);
      } else if (selectId === 0) {
        EventReportUtil.setChoosePanelType(StartChoosePanelType.RECORD_TYPE_BY_UP_SCREEN);
      } else {
        EventReportUtil.setChoosePanelType(StartChoosePanelType.RECORD_TYPE_BY_DOWN_SCREEN);
      }
      LogUtil.warn(TAG, 'ExtAbilityProxy onRequest with triggerType: panel');
    }
  }

  async onDestroy(): Promise<void> {
    LogUtil.info(TAG, 'ExtAbilityProxy onDestroy');
    backgroundTaskManager.resetAllEfficiencyResources();
    LogUtil.warn(TAG, 'Succeeded in reset applyEfficiencyResources.');
    await this.dataPreferences.setPreferenceKeyValue(PreferencesKey.IS_RECORDING, false);
    try {
      this.navbarEvent.unsubscribe();
      this.screenOffEvent.unsubscribe();
    } catch (error) {
      LogUtil.error(TAG, 'ExtAbilityProxy unsubscribe failed:', (error as BusinessError).message);
    }
    this.recordManager!.release();
    this.recordManager!.cancelPreferenceListen();
    await this.notificationManager!.releasePixelMap();
    this.recordManager.unRegisterMaskDisplayListener();
    try {
      display.off('remove', this.recordManager.displayRemoveListener);
      display.off('foldStatusChange', this.foldListener);
      display.off('change', this.onExpandModeChange);
    } catch (error) {
      LogUtil.error(TAG, 'ExtAbilityProxy off display remove failed', (error as BusinessError).message);
    }
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    LogUtil.info(TAG, 'onConfigurationUpdate:' + JSON.stringify(newConfig));
    const currentLanguage = AppStorage.Get<String>('languageCode');
    const currentFontSize = AppStorage.Get<Number>('fontSizeScaleCode');
    LogUtil.info(TAG, `currentLanguage ${currentLanguage}`);
    if (currentLanguage !== newConfig.language) {
      AppStorage.setOrCreate<String | undefined>('languageCode', newConfig.language);
      LogUtil.info(TAG, 'Language changed', newConfig.language!);
      if (!CommonUtil.checkIfDeviceIsPC() && this.recordManager!.getIsRecording()) {
        this.notificationManager.sendNotificationRequest();
      }
    }
    if (currentFontSize !== newConfig.fontSizeScale) {
      AppStorage.setOrCreate<Number | undefined>('fontSizeScaleCode', newConfig.fontSizeScale);
      LogUtil.info(TAG, 'fontSize changed: ' + newConfig.fontSizeScale);
    }
    const currentDarkMode = this.globalThisInstance!.getObject('darkMode') as ConfigurationConstant.ColorMode;
    if (currentDarkMode != newConfig.colorMode) {
      this.globalThisInstance!.setObject('darkMode', newConfig.colorMode);
      AppStorage.setOrCreate<boolean>('isDarkMode',
        newConfig.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
      if (!CommonUtil.checkIfDeviceIsPC() && this.recordManager!.getIsRecording()) {
        this.notificationManager.sendNotificationRequest();
      }
      LogUtil.info(TAG, 'DarkMode change to ' + newConfig.colorMode);
    }
  }

  /**
   * 如果扩展模式改变，停止录屏
   */
  async stopIfExpandModeChanged() {
    let recorderId: number = GlobalThisUtil.getInstance().getObject(SELECT_DISPLAY_ID) as number;
    let newModeMap: Map<number, ScreenData> = await ExpansionScreenUtil.getScreenModeMap(recorderId);
    if (ExpansionScreenUtil.checkModeChanged(recorderId, this.modeMap, newModeMap)) {
      this.stopRecorder();
    }
    this.modeMap = newModeMap;
  }

  /**
   * 如果录屏的display是上半屏，或者下半屏，就结束录屏，如果不是，就继续录屏
   */
  private async stopIfFoldChanged() {
    if (PcRecordManager.getInstance().isRecorderFoldDisplay()) {
      LogUtil.info(TAG, 'stopIfFoldChanged');
      EventReportUtil.setStopType(UNKNOWN_REASON);
      await this.stopRecorder();
    }
  }

  /**
   * 停止录屏
   */
  private async stopRecorder() {
    LogUtil.info(TAG, 'stop recorder');
    try {
      display.off('change', this.onExpandModeChange);
      display.off('foldStatusChange', this.foldListener);
    } catch (error) {
      LogUtil.error(TAG, 'Failed to register callback. Code: ' + JSON.stringify(error));
    }
    GlobalThisUtil.getInstance().setObject(SELECT_DISPLAY_ID, undefined);
    PcRecordManager.getInstance().setStopTime(Date.now());
    await PcRecordManager.getInstance().stop();
  }

  setModeChangeListener() {
    this.modeMap.clear();
    try {
      display.on('change', this.onExpandModeChange);
    } catch (error) {
      LogUtil.error(TAG, 'ExtAbilityProxy, display on change error:', (error as BusinessError).message);
    }
  }

  setFoldListener() {
    try {
      if (!display.isFoldable()) {
        return;
      }
      let initDisplay = display.getDefaultDisplaySync();
      this.initDisplayWidth = initDisplay.width;
      this.initDisplayHeight = initDisplay.height;
      this.foldListener = async () => {
        LogUtil.info(TAG, 'The folded state changes');
        // 刷新折叠状态
        this.globalThisInstance!.setObject('isProcessing', true);
        if (this.recordManager!.getIsRecording()) {
          LogUtil.warn(TAG, 'The folded state changes, stop recording');
          if (CommonUtil.checkIfDeviceIsPC()) {
            await this.stopIfFoldChanged();
          } else {
            EventReportUtil.setStopType(UNKNOWN_REASON);
            await this.recordManager!.stop(false, this.initDisplayWidth, this.initDisplayHeight);
          }
        }
        this.globalThisInstance!.setObject('isProcessing', false);
      };
      display.on('foldStatusChange', this.foldListener)
    } catch (error) {
      LogUtil.error(TAG, 'ExtAbilityProxy folded state changes failed:', (error as BusinessError).message);
    }
  }

  /**
   * 校验权限
   *
   * @param want 参数
   * @returns 校验结果
   */
  checkAbilityPermission(want: Want): boolean {
    if (!want?.parameters?.['ohos.aafwk.param.callerBundleName']) {
      let bundleUid = want?.parameters?.['ohos.aafwk.param.callerUid'] as number;
      return bundleUid === MULTIMODAL_INPUT_UID || bundleUid === SHELL_UID || bundleUid === SHELL_UID_ROOT;
    }
    let callerBundleName = want?.parameters?.['ohos.aafwk.param.callerBundleName'];
    if (typeof callerBundleName === 'string' && CommonUtil.isSystemApp(callerBundleName)) {
      return callerBundleName === SCENEBOARD_NAME || callerBundleName === SCREENRECORDER_NAME;
    }
    return false;
  }

  applyEfficiencyResources(): void {
    let request: backgroundTaskManager.EfficiencyResourcesRequest = {
      resourceTypes: backgroundTaskManager.ResourceType.CPU,
      isApply: true,
      timeOut: 0,
      reason: 'screenrecord',
      isPersist: true,
      isProcess: false,
    };
    backgroundTaskManager.applyEfficiencyResources(request);
    LogUtil.info(TAG, 'Succeeded in invoking applyEfficiencyResources.');
  }

  static checkFileName(name: string | undefined): boolean {
    if (name === undefined) {
      LogUtil.info(TAG, 'fileName is undefined');
      return true;
    }

    if (name.length > FILENAME_MAX) {
      LogUtil.error(TAG, 'fileName exceed max length');
      return false;
    }

    if (name.charAt(0) === '.') {
      LogUtil.error(TAG, 'fileName with illegal start');
      return false;
    }

    try {
      if (name.match(FILENAME_REGEX_CHECK)) {
        LogUtil.error(TAG, 'fileName illegal');
        return false;
      }

      if (!name.endsWith(FILENAME_SUFFIX)) {
        LogUtil.error(TAG, 'fileName with illegal end');
        return false;
      }
    } catch (err) {
      LogUtil.error(TAG, 'regex check error: ' + (err as BusinessError).message);
    }

    return true;
  }

  setScreenOffTime(screenOffTime: number): void {
    this.screenOffTime = screenOffTime;
  }

  async errorPhotoHandle() {
    await RecorderFileManager.getInstance().setVideoAssetPending();
    await this.recordManager!.release();
    this.context.terminateSelf();
  }
}