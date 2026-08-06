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
  CommonUtil,
  EVENT_NAME_SET_SCREENRECORD_MIC,
  EventReportUtil,
  GlobalThisUtil,
  LogUtil,
  PixelMapUtil,
  PreferenceUtils,
  SetSwitchResult,
  SetSwitchType,
  SettingDataUtil,
  StopRecordTriggerType,
  StringUtil
} from '@ohos/common';
import lazy { workScheduler } from '@kit.BackgroundTasksKit';
import { BusinessError, systemParameterEnhance } from '@kit.BasicServicesKit';
import common from '@ohos.app.ability.common';
import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';
import Want from '@ohos.app.ability.Want';
import lazy wantAgent from '@ohos.app.ability.wantAgent';
import Base from '@ohos.base';
import dataPreferences from '@ohos.data.preferences';
import notificationManager from '@ohos.notificationManager';
import { MicManager } from './MicManager';
import { RecorderFileManager } from './RecorderFileManager';
import { RecordManager } from './RecordManager';
import { DARK_NOTIFICATION_COLOR, LIGHT_NOTIFICATION_COLOR } from './types';

const TAG = 'NotificationManager';
const SETTINGS_INPUT_SHOW_TOUCH_HINT = 'settings.input.show_touch_hint';
const TRACK_BUTTON = 'id_track_button';
const STOP_BUTTON = 'id_stop_button';
const MIC_BUTTON = 'id_mic_button';
const REQUEST_CODE = 0;
const REQUEST_ID = 1;
const VIEW_DARA_ACTION = 'ohos.want.action.viewData';
const VIDEO_FORMAT = 'video/mp4';
const SYSTEMUI_LIVE2_CONTROL_ENABLE = 'persist.systemui.live2';
// 周期时间 小时*分钟*秒*毫秒
const repeatTime = 2 * 60 * 60 * 1000;

export class NotificationManager {
  private userSetBubbleState : boolean | undefined = undefined;
  private isJudgeBubbleWorkStart : boolean = false;
  private static instance: NotificationManager;
  private capsuleIcon?: PixelMap;
  private trackIconOn?: PixelMap;
  private trackIconOff?: PixelMap;
  private micIconOn?: PixelMap;
  private micIconOff?: PixelMap;
  private micIconDisable?: PixelMap;
  private stopIcon?: PixelMap;
  private liveViewIcon?: PixelMap;
  private isTrackOn: boolean = true;
  private isMicOn: boolean = true;
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private isChecked: boolean = true;
  private dataPreferences: PreferenceUtils = new PreferenceUtils();
  private isTrackClicked: boolean = false;
  private isMicClicked: boolean = false;

  constructor() {
  }

  public static getInstance(): NotificationManager {
    if (!NotificationManager.instance) {
      NotificationManager.instance = new NotificationManager();
    }
    return NotificationManager.instance;
  }

  private getWantData(): Want {
    const wantDate: Want = {
      bundleName: 'com.ohos.photos',
      abilityName: 'com.ohos.photos.MainAbility',
      action: VIEW_DARA_ACTION,
      type: VIDEO_FORMAT,
      uri: AppStorage.Get('videoUri')
    }
    return wantDate;
  }

  public async sendLockNotification() {
    const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    const wantData = this.getWantData();
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        wantData
      ],
      actionType: wantAgent.OperationType.START_ABILITY,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
      requestCode: REQUEST_CODE,
    };
    let albumAgent = await wantAgent.getWantAgent(wantAgentInfo);
    let notificationRequest: notificationManager.NotificationRequest = {
      id: REQUEST_ID,
      isOngoing: true,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT, // 普通文本类型通知
        normal: {
          title: StringUtil.getStringByNameSync('app_name', context),
          text: StringUtil.getStringByNameSync('notification_text', context),
        }
      },
      smallIcon: this.liveViewIcon,
      notificationSlotType: notificationManager.SlotType.SERVICE_INFORMATION,
      wantAgent: albumAgent,
      extraInfo: {
        'hw_button_state_on': [this.isTrackOn ? 'ON' : 'OFF', this.isMicOn ? 'ON' : 'OFF', '']
      }
    };
    LogUtil.warn(TAG, 'start public notificationRequest');
    notificationManager.publish(notificationRequest, (err: Base.BusinessError) => {
      if (err) {
        LogUtil.info(TAG, `Failed to publish notification. Code is ${err.code}, message is ${err.message}`);
        return;
      }
      LogUtil.info(TAG, 'Succeeded in publishing notification.');
    });
  }

  public getCurrentShowTouchState(): boolean {
    const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    let value = SettingDataUtil.getSettingsDataSync(context, SETTINGS_INPUT_SHOW_TOUCH_HINT, 'false');
    LogUtil.info(TAG, `getCurrentShowTouchState : ${value}`);
    return value === 'true';
  }

  public needUpdateShowTouch(): boolean {
    let observerValue = this.getCurrentShowTouchState();
    LogUtil.warn(TAG, `needUpdateShowTouch current: ${observerValue}, isChecked: ${this.isChecked}`);
    return !(observerValue === this.isChecked);
  }

  public handleCheckedChange(isTriggeredByUser: boolean, isChecked: dataPreferences.ValueType) : boolean {
    LogUtil.info(TAG, `handleChenkedChange isChecked: ${isChecked}`);
    LogUtil.info(TAG, `handleChenkedChange${this.isTrackOn}`);
    let changeSuccessfully : boolean = false;
    const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;

    try {
      if (isChecked) {
        let state: boolean = SettingDataUtil.setSettingDataSync(context, SETTINGS_INPUT_SHOW_TOUCH_HINT, 'true');
        this.isChecked = true;
        LogUtil.info(TAG, `Set ShowTouch on ${state}`);
        this.userSetBubbleState = true;
        // 用户手动打开&&初始状态为false  开启延迟任务
        LogUtil.info(`RecordManager.initBubbleInSettings ${RecordManager.initBubbleInSettings}, this.userSetBubbleState${this.userSetBubbleState},
        this.isJudgeBubbleWorkStart ${this.isJudgeBubbleWorkStart}`);
        if(RecordManager.initBubbleInSettings === false && this.isJudgeBubbleWorkStart === false) {
          this.startJudgeBubbleWorkScheduler(repeatTime);
        }
      } else {
        let state: boolean = SettingDataUtil.setSettingDataSync(context, SETTINGS_INPUT_SHOW_TOUCH_HINT, 'false');
        LogUtil.info(TAG, `Set ShowTouch off ${state}`);
        this.isChecked = false;
      }
      EventReportUtil.setSwitchTrackResult(SetSwitchResult.RESULT_SUCCESS);
      changeSuccessfully = true;
    } catch (error) {
      LogUtil.error(TAG, 'handleCheckedChange error: ' + (error as BusinessError).message);
      EventReportUtil.setSwitchTrackResult(SetSwitchResult.RESULT_FAILED);
    }
    EventReportUtil.reportTrackStateEvent(isTriggeredByUser);
    return changeSuccessfully;
  }

  public async updateShowTouch(value: boolean) {
    this.isTrackOn = value;
    this.isChecked = value;
    await this.sendNotificationRequest();
  }

  public updateShowTouchState(value: boolean) {
    this.isTrackOn = value;
    this.isChecked = value;
  }

  public async setNotificationSubscriber() {
    try {
      const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
      this.isTrackOn = PreferenceUtils.getValueSync(context, 'showTouchState', 'true') === 'true' ? true : false;
      // 小白点用户设置项的初始状态，若为true，且开发者模式没开启小白点，开启延迟任务
      this.userSetBubbleState = this.isTrackOn;
      if (RecordManager.initBubbleInSettings === false && this.userSetBubbleState === true &&
        this.isJudgeBubbleWorkStart === false) {
        this.startJudgeBubbleWorkScheduler(repeatTime);
      }
      this.isChecked = this.isTrackOn;
      await MicManager.getInstance().getMicEnabledState((value) => {
        this.isMicOn = value;
      });
      LogUtil.info(TAG, `get current touch state before setNotificationSubscriber: ${this.isTrackOn}`);
      const systemLiveViewSubscriber: notificationManager.SystemLiveViewSubscriber = {
        onResponse: async (id: Number, option: notificationManager.ButtonOptions) => {
          LogUtil.warn(TAG, `Click notification ${id}, buttion ${option.buttonName}`);
          switch (option.buttonName) {
            case TRACK_BUTTON:
              if (!this.isTrackClicked) {
                this.onTrackButtonClicked();
              }
              break;
            case STOP_BUTTON:
              EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_STOP_BUTTON);
              RecordManager.getInstance().setStopTime(Date.now());
              LogUtil.info(TAG, 'click stop button');
              await this.stopRecording();
              break;
            case MIC_BUTTON:
              this.onMicButtonClicked();
              break;
            default:
              LogUtil.warn(TAG, 'other button clicked, do nothing');
              break;
          }
        }
      }
      await notificationManager.subscribeSystemLiveView(systemLiveViewSubscriber);
      LogUtil.info(TAG, 'subscribeSystemLiveView success');
    } catch (e) {
      LogUtil.error(TAG, `subscribeSystemLiveView failed, error code: ${e?.code}, message: ${e?.message}`);
    }
  }

  public async onTrackButtonClicked(): Promise<void> {
    this.isTrackClicked = true;
    this.globalThisInstance.setObject('isTrackClicked', this.isTrackClicked);
    LogUtil.warn(TAG, 'click operation track');
    this.isTrackOn = !this.isTrackOn;
    if (this.globalThisInstance!.getObject('isRecording')) {
      LogUtil.info(TAG, `Recording refresh track data`);
      await this.sendNotificationRequest();
      this.isChecked = this.isTrackOn;
      EventReportUtil.setSwitchTrackType(this.isChecked ? SetSwitchType.TRIGGERED_TYPE_SWITCH_ON :
        SetSwitchType.TRIGGERED_TYPE_SWITCH_OFF);
      this.handleCheckedChange(true, this.isChecked);
    }
    await this.dataPreferences.setPreferenceKeyValue('showTouchState', JSON.stringify(this.isTrackOn));

    const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    CommonUtil.broadcastAccessibilityText(StringUtil.getStringByNameSync(this.isTrackOn ? 'already_on' : 'already_off',
      context,''));

    setTimeout(() => {
      this.isTrackClicked = false;
      this.globalThisInstance.setObject('isTrackClicked', this.isTrackClicked);
    }, 200);
  }

  public async onMicButtonClicked(): Promise<void> {
    if (!this.isMicClicked) {
      this.isMicClicked = true;
      this.globalThisInstance!.setObject('isMicClicked', true);
      LogUtil.warn(TAG, 'click mic button');
      await this.setMicEnabled(!this.isMicOn);

      const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
      CommonUtil.broadcastAccessibilityText(StringUtil.getStringByNameSync(this.isMicOn ? 'already_on' : 'already_off',
        context,''));

      setTimeout(() => {
        this.isMicClicked = false;
        this.globalThisInstance!.setObject('isMicClicked', false);
      }, 200);
    }
  }

  private async getNotificationButtonArray(): Promise<Array<PixelMap>> {
    LogUtil.info(TAG, 'getNotificationButtonArray start');
    let isLive2Enable: boolean = false;
    try {
      isLive2Enable = systemParameterEnhance.getSync(SYSTEMUI_LIVE2_CONTROL_ENABLE, 'false') === 'true';
    } catch (error) {
      LogUtil.error(TAG, 'getNotificationButtonArray getLiveEnable error : ' +
        (error as BusinessError).code + '; ' + (error as BusinessError).message);
    }
    LogUtil.info(TAG, 'isLive2Enable: ' + isLive2Enable);
    this.capsuleIcon = await PixelMapUtil.getPixelMapByName(isLive2Enable ?
      'capsule_stop_live2.svg' : 'capsule_stop.svg', 16);
    this.liveViewIcon = await PixelMapUtil.getPixelMapByName('live_view_icon.svg', 40);
    let darkMode = this.getDarkMode();
    LogUtil.info(TAG, 'is darkMode: ' + darkMode);
    if (darkMode) {
      this.stopIcon = await PixelMapUtil.getPixelMapByName('dark.svg', 40);
      this.trackIconOn = await PixelMapUtil.getPixelMapByName('trace_open.svg', 40);
      this.trackIconOff = await PixelMapUtil.getPixelMapByName('trace_closed_dark.svg', 40);
      this.micIconOn = await PixelMapUtil.getPixelMapByName('ic_public_voice_filled.svg', 40);
      this.micIconOff = await PixelMapUtil.getPixelMapByName('ic_public_voice_off_filled_dark.svg', 40);
    } else {
      this.stopIcon = await PixelMapUtil.getPixelMapByName('light.svg', 40);
      this.trackIconOn = await PixelMapUtil.getPixelMapByName('trace_open.svg', 40);
      this.trackIconOff = await PixelMapUtil.getPixelMapByName('trace_closed.svg', 40);
      this.micIconOn = await PixelMapUtil.getPixelMapByName('ic_public_voice_filled.svg', 40);
      this.micIconOff = await PixelMapUtil.getPixelMapByName('ic_public_voice_off_filled.svg', 40);
    }
    let trackIcon = this.isTrackOn ? this.trackIconOn : this.trackIconOff;
    let micIcon = this.isMicOn ? this.micIconOn : this.micIconOff;
    let iconArray = [trackIcon!, micIcon!, this.stopIcon!];
    LogUtil.info(TAG, 'getNotificationButtonArray end');
    return iconArray;
  }

  private getDarkMode(): boolean {
    return this.globalThisInstance!.getObject('darkMode') === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  public async getNotificationRequest(startTime?: number): Promise<notificationManager.NotificationRequest> {
    LogUtil.warn(TAG, `getNotificationRequest start`)
    let iconArray = await this.getNotificationButtonArray();
    const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    let accessibilityText = [
      this.getSwitchAccessibilityTextByName('control_track_button'),
      this.getSwitchAccessibilityTextByName('microphone'),
      this.getButtonAccessibilityTextByName('control_stop_recording')
    ]
    let initTime = this.globalThisInstance!.getObject('initTime');
    let notificationRequest: notificationManager.NotificationRequest = {
      notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
      id: 1000,
      largeIcon: this.liveViewIcon,
      smallIcon: this.liveViewIcon,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
        systemLiveView: {

          title: StringUtil.getStringByNameSync('app_name', context),
          text: StringUtil.getStringByNameSync('notification_subtitle', context),
          typeCode: 1,
          button: {
            icons: iconArray,
            names: [TRACK_BUTTON, MIC_BUTTON, STOP_BUTTON]
          },
          capsule: {
            title: 'ScreenRecorderCap',
            icon: this.capsuleIcon,
            backgroundColor: this.getDarkMode() ? DARK_NOTIFICATION_COLOR : LIGHT_NOTIFICATION_COLOR,
          },
          time: startTime ? this.getNotificationTimeWithInitialTime(startTime) :
            this.getNotificationTimeWithoutInitialTime(),
        }
      },
      isRemoveAllowed: false,
      extraInfo: startTime ? {
        'hw_button_state_on': [this.isTrackOn ? 'ON' : 'OFF', this.isMicOn ? 'ON' : 'OFF', ''],
        'hw_button_accessibility_text': accessibilityText,
        'hw_live_view_hidden_when_keyguard': true
      } : {
        'hw_button_state_on': [this.isTrackOn ? 'ON' : 'OFF', this.isMicOn ? 'ON' : 'OFF', ''],
        'hw_button_accessibility_text': accessibilityText,
        'hw_live_view_hidden_when_keyguard': true,
        'initialTime': new Date().valueOf() - (initTime !== undefined ? initTime as number : 0)
      }
    }
    return notificationRequest;
  }

  private getNotificationTimeWithInitialTime(startTime: number) {
    let initialTime = new Date().valueOf() - startTime;
    LogUtil.warn(TAG, 'getNotificationTimeWithInitialTime initialTime = ' + initialTime);
    let notificationTime: notificationManager.NotificationTime = {
      initialTime: initialTime,
      isCountDown: false,
      isInTitle: true,
      isPaused: false
    }
    return notificationTime;
  }

  private getNotificationTimeWithoutInitialTime() {
    LogUtil.warn(TAG, 'getNotificationTimeWithoutInitialTime');
    let notificationTime: notificationManager.NotificationTime = {
      isCountDown: false,
      isInTitle: true,
      isPaused: false
    }
    return notificationTime;
  }

  public async sendNotificationRequest(startTime?: number) {
    try {
      let notificationRequest = await this.getNotificationRequest(startTime);
      await notificationManager.publish(notificationRequest);
      LogUtil.warn(TAG, `startNotification success`);
    } catch (error) {
      LogUtil.error(TAG, 'sendNotificationRequest error:' + (error as BusinessError).message);
    }
  }

  public async cancelNotification() {
    await notificationManager.cancel(1000);
    LogUtil.info(TAG, 'Success to destroy notification Window!');
    // reset isMicOn
    await MicManager.getInstance().getMicEnabledState((value) => {
      this.isMicOn = value;
    });
  }

  private async stopRecording() {
    let recorder = RecordManager.getInstance();
    if (recorder != undefined) {
      await recorder.stop();
    } else {
      LogUtil.error(TAG, 'recorder empty cannot stop');
    }
  }

  private async setMicEnabled(enable: boolean) {
    let recorder = RecordManager.getInstance();
    if (recorder !== undefined) {
      let result = await MicManager.getInstance().setMicEnabled(enable, RecorderFileManager.getInstance());
      if (result) {
        LogUtil.info(TAG, 'setMicEnable success: ' + enable ? 'on' : 'off');
        EventReportUtil.setSwitchMicResult(SetSwitchResult.RESULT_SUCCESS);
        this.isMicOn = enable;
        if (enable && result) {
          MicManager.getInstance().setIsMicUnavailable(false);
        }
        if (this.globalThisInstance.getObject('isRecording')) {
          LogUtil.info(TAG, `Recording refresh mic data`);
          await this.sendNotificationRequest();
        }
      } else {
        LogUtil.error(TAG, 'setMicEnable failed');
        EventReportUtil.setSwitchMicResult(SetSwitchResult.RESULT_FAILED);
      }
      EventReportUtil.reportEvent(EVENT_NAME_SET_SCREENRECORD_MIC,
        {
          'TYPE': EventReportUtil.getSwitchMicType(),
          'RESULT': EventReportUtil.getSwitchMicResult()
        }
      );
    } else {
      LogUtil.error(TAG, 'recorder empty cannot set mic state');
    }
  }

  public async releasePixelMap() {
    LogUtil.info(TAG, 'release PixelMap');
    await this.liveViewIcon?.release();
    await this.capsuleIcon?.release();
    await this.trackIconOn?.release();
    await this.trackIconOff?.release();
    await this.micIconOn?.release();
    await this.micIconOff?.release();
    await this.micIconDisable?.release();
    await this.stopIcon?.release();
  }

  private getButtonAccessibilityTextByName(name: string): string {
    const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    const buttonName = StringUtil.getStringByNameSync(name, context);
    return `${buttonName}`;
  }

  private getSwitchAccessibilityTextByName(name: string): string {
    const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    if (name === 'microphone') {
      const micOnText = StringUtil.getStringByNameSync('notification_mic_accessibility_text_on', context);
      const micOffText = StringUtil.getStringByNameSync('notification_mic_accessibility_text_off', context);
      return this.isMicOn ? micOnText : micOffText;
    } else if (name === 'control_track_button') {
      const traceOnText = StringUtil.getStringByNameSync('notification_trace_accessibility_text_on', context);
      const traceOffText = StringUtil.getStringByNameSync('notification_trace_accessibility_text_off', context);
      return this.isTrackOn ? traceOnText : traceOffText;
    }
    return '';
  }

  public async createNotification(startTime?: number) {
    if (!this.globalThisInstance.getObject('isNotificationSubscribed')) {
      await this.setNotificationSubscriber();
      LogUtil.info(TAG, 'createNotification setNotificationSubscriber success');
      this.globalThisInstance.setObject('isNotificationSubscribed', true);
    } else {
      const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
      let isTrackOn = await PreferenceUtils.getValue(context, 'showTouchState', 'true') === 'true' ? true : false;
      this.updateShowTouchState(isTrackOn)
      LogUtil.info(TAG, `createNotification updateShowTouchState isTrackOn ${isTrackOn}`);
    }
    await this.sendNotificationRequest(startTime);
  }


  /**
   * 开启延迟任务
   *
   * @param repeatTime 任务执行周期
   */
  private  async startJudgeBubbleWorkScheduler(repeatTime: number) {
    LogUtil.warn(TAG, `in startJudgeBubbleWorkScheduler`);
    const workIdJudgeBubble = 1;
    const workInfo: workScheduler.WorkInfo = {
      workId: workIdJudgeBubble,
      bundleName: 'com.ohos.screenrecorder',
      abilityName: 'JudgeBubbleExtensionAbility',
      isRepeat: true,
      repeatCycleTime: repeatTime,
      isPersisted: true
    }
    try {
      workScheduler.startWork(workInfo);
      this.isJudgeBubbleWorkStart = true;
      LogUtil.warn(TAG, `startWork JudgeBubble success`);
    } catch (error) {
      LogUtil.error(TAG, `startWork failed. code is
          ${(error as BusinessError).code} message is ${(error as BusinessError).message}`);
    }
  }

  /**
   * 首次启动时默认打开通知开关，用Preferences记录，仅执行一次。
   * 用户后续在设置中关闭后不再自动打开。
   */
  public static async enableNotificationOnce(context: common.ServiceExtensionContext): Promise<void> {
    const KEY = 'notification_first_enabled';
    try {
      const alreadyEnabled = await PreferenceUtils.getValue(context, KEY, 'false');
      if (alreadyEnabled !== 'true') {
        await notificationManager.setNotificationEnable({
          bundle: 'com.ohos.screenrecorder'
        }, true);
        const prefs = new PreferenceUtils();
        await prefs.setPreferenceKeyValue(KEY, 'true');
        LogUtil.warn(TAG, 'First-time notification enablement success');
      }
    } catch (e) {
      LogUtil.error(TAG, `Enable notification once failed: ${JSON.stringify(e)}`);
    }
  }
}