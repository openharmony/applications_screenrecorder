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
  ALIVE_EVENT_INFO,
  CommonUtil,
  DisplayUtil,
  EVENT_NAME,
  EventReportUtil,
  GlobalThisUtil,
  INSUFFICIENT_VIDEO_SERVICE_RESOURCES_CODE,
  LogUtil,
  PreferencesKey,
  PreferenceUtils,
  RuntimeError,
  SendableObject,
  StartRecordTriggerResult,
  StopRecordTriggerResult,
  StopRecordTriggerType,
  StringUtil,
  Trace,
  TraceConst,
  UNKNOWN_REASON,
  WorkerType
} from '@ohos/common';
import { sendableContextManager } from '@kit.AbilityKit';
import lazy { Decimal, worker } from '@kit.ArkTS';
import { audio } from '@kit.AudioKit';
import lazy { workScheduler } from '@kit.BackgroundTasksKit';
import { hiSysEvent } from '@kit.PerformanceAnalysisKit';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import lazy commonEventManager from '@ohos.commonEventManager';
import dataPreferences from '@ohos.data.preferences';
import display from '@ohos.display';
import storageManager from '@ohos.file.statvfs';
import media from '@ohos.multimedia.media';
import lazy promptAction from '@ohos.promptAction';
import lazy screenLock from '@ohos.screenLock';
import settings from '@ohos.settings';
import { MicManager, RecorderFileManager, RecorderToast } from '.';
import { RecorderUtil } from '../util/RecorderUtil';
import { PadRecorderConfig } from './config/PadRecorderConfigImpl';
import { PhoneRecorderConfig } from './config/PhoneRecorderConfigImpl';
import { RecorderConfigInterface } from './config/RecorderConfigInterface';
import { NotificationManager } from './NotificationManager';
import {
  CONTROL_PANEL_FADE_OUT_TIME,
  DEFAULT_TRIGGER_TYPE,
  MIN_FREE_SPACE_IN_BYTE,
  TIME_TO_PREPARE_DATA
} from './types';
import { WindowManager } from './WindowManager';

const TAG = 'RecordManager';

const PREFERENCES_NAME = 'myPreferences';

const SCREEN_RECORDER_MIN_DISPLAYID = 1000;
// 兼容适配框架未转换的错误码
const MEDIA_AVERRORCODE_AVERR_SERVICE_DIED = 331350529;

/**
 * Recording management tool class
 *
 * @since 2022-09-03
 */
export class RecordManager {
  private isRecording: boolean = false;
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  public static instance: RecordManager;
  private isCapsuleStarted: boolean = false;
  private notificationManager: NotificationManager = NotificationManager.getInstance();
  private dataPreferences: PreferenceUtils = new PreferenceUtils();
  private initChecked: boolean = true;
  private startTime: number = 0;
  private stopTime: number = 0;
  private startRecordTime: number = 0;
  private screenStartTimeoutId: number | null = null;
  private isScreenRecorderStart: boolean = false;
  private isStartAfterTimeout: boolean = false;
  private preferenceListen: dataPreferences.Preferences | null = null;
  private workThread: worker.ThreadWorker | null = null;
  private recorderTimes: number = 1;
  private firstTime: number = 0;
  private recorderFileManagerInstance: RecorderFileManager;
  private micManagerInstance: MicManager = MicManager.getInstance();
  private windowManagerInstance: WindowManager;
  private recorderConfig: RecorderConfigInterface;
  public static initBubbleInSettings: boolean | undefined = undefined;
  public aliveSub = async () => {
    try {
      LogUtil.info(TAG, `sub JUDGE_ALIVE_EVENT`);
      commonEventManager.publish(EVENT_NAME.IS_ALIVE_EVENT,
        { bundleName: ALIVE_EVENT_INFO.BUNDLE_NAME, subscriberPermissions: [ALIVE_EVENT_INFO.PERMISSIONS] },
        (err: BusinessError) => {
          if (err) {
            LogUtil.error(`Failed to publish common event. Code is ${err.code}, message is ${err.message}`);
            return;
          }
          LogUtil.info(TAG, `publish recorderIsAlive success`);
        });
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(`Failed to publish common event. Code is ${err.code}, message is ${err.message}`);
    }
  };

  public setRecorderConfig(value: RecorderConfigInterface) {
    this.recorderConfig = value;
  }

  protected getRecorderConfig(): RecorderConfigInterface {
    return this.recorderConfig;
  }

  constructor(recorderFileManagerInstance: RecorderFileManager, windowManagerInstance: WindowManager,
    recorderConfig: RecorderConfigInterface) {
    this.recorderFileManagerInstance = recorderFileManagerInstance;
    this.windowManagerInstance = windowManagerInstance;
    this.recorderConfig = recorderConfig;
  }

  public static getInstance(): RecordManager {
    if (!RecordManager.instance) {
      let recorderConfig: RecorderConfigInterface =
        CommonUtil.checkIfDeviceIsPhone() ? new PhoneRecorderConfig() : new PadRecorderConfig();
      RecordManager.instance =
        new RecordManager(RecorderFileManager.getInstance(), WindowManager.getInstance(), recorderConfig);
    }
    return RecordManager.instance;
  }

  async handleError(error: Error, eventName: string, isSkipRelease?: boolean): Promise<void> {
    await this.dataPreferences.setPreferenceKeyValue(PreferencesKey.IS_RECORDING, false);
    LogUtil.error(TAG, eventName, 'failed because: ', error.message);
    !isSkipRelease && await this.release();
    RecorderUtil.postKillProcessMessage();
  }

  /* instrument ignore next */
  private async setAVScreenCaptureCallback() {
    this.recorderFileManagerInstance.getAvScreenCaptureRecorder()!.on('stateChange', async (stateCode) => {
      LogUtil.warn(TAG, 'stateChange occurred during recording' + stateCode);
      switch (stateCode) {
        case media.AVScreenCaptureStateCode.SCREENCAPTURE_STATE_STARTED:
          Trace.end(TraceConst.START_SCREEN_RECORDING_TRACE_MEDIA);
          if (this.isStartAfterTimeout) {
            break;
          }
          this.isScreenRecorderStart = true;
          clearTimeout(this.screenStartTimeoutId);
          await this.dealWithStateChangeStarted();
          break;
        case media.AVScreenCaptureStateCode.SCREENCAPTURE_STATE_CANCELED:
        case media.AVScreenCaptureStateCode.SCREENCAPTURE_STATE_STOPPED_BY_USER:
          LogUtil.warn(TAG, 'user stop recording');
          EventReportUtil.setErrorReason(UNKNOWN_REASON);
          this.release();
          break;
        case media.AVScreenCaptureStateCode.SCREENCAPTURE_STATE_STOPPED_BY_CALL:
          LogUtil.warn(TAG, 'receive stateChange stop screencapture by call');
          break;
        case media.AVScreenCaptureStateCode.SCREENCAPTURE_STATE_INTERRUPTED_BY_OTHER:
          await this.dealWithStateChangeInterruptByOther();
          break;
        case media.AVScreenCaptureStateCode.SCREENCAPTURE_STATE_MIC_UNAVAILABLE:
          this.micManagerInstance.setIsMicUnavailable(true);
          const audioScene = audio.getAudioManager().getAudioSceneSync();
          LogUtil.info(TAG, `The current audio scene is:${audioScene}`);
          if (audioScene === audio.AudioScene.AUDIO_SCENE_PHONE_CALL) {
            RecorderToast.getInstance()
              .showToast('cannot_record_voice_during_call_toast', promptAction.ToastShowMode.TOP_MOST);
          } else {
            RecorderToast.getInstance()
              .showToast('mic_is_unavailable', promptAction.ToastShowMode.TOP_MOST);
          }
          LogUtil.info(TAG, 'The microphone is preempted.');
          break;
        case media.AVScreenCaptureStateCode.SCREENCAPTURE_STATE_MIC_MUTED_BY_USER:
        case media.AVScreenCaptureStateCode.SCREENCAPTURE_STATE_MIC_UNMUTED_BY_USER:
        case media.AVScreenCaptureStateCode.SCREENCAPTURE_STATE_ENTER_PRIVATE_SCENE:
        case media.AVScreenCaptureStateCode.SCREENCAPTURE_STATE_EXIT_PRIVATE_SCENE:
        default:
          LogUtil.info(TAG, 'showDialog, other stateChange current not supported');
          if (Number(stateCode) === 10) {
            LogUtil.info(TAG, 'private space change, stop recorder');
            this.setStopTime(Date.now());
            await this.stop(true);
            RecorderUtil.postKillProcessMessage();
          }
          break;
      }
    })
  }

  private async dealWithStateChangeStarted(): Promise<void> {
    LogUtil.info(TAG, 'screenCaptureRecorder started');
    EventReportUtil.setStartResult(this.micManagerInstance.getIsMicUnavailable() ?
      StartRecordTriggerResult.RESULT_MICROPHONE_PREEMPTED : StartRecordTriggerResult.RESULT_SUCCESS);
    EventReportUtil.setStartFaultReason();
    EventReportUtil.reportStartRecordEvent(Date.now() - this.startTime);
    this.startRecordTime = Date.now();

    const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    CommonUtil.broadcastAccessibilityText(StringUtil.getStringByNameSync('control_start_recording', context));

    // show live notification or capsule.
    if (this.recorderTimes !== 1) {
      await this.windowManagerInstance.showCapsule(this.firstTime, this.dataPreferences);
    } else {
      let currDate = new Date().valueOf();
      LogUtil.info(TAG, `start record time:${currDate}`);
      this.globalThisInstance!.setObject('initTime', currDate);
      await this.windowManagerInstance.showCapsule(currDate, this.dataPreferences);
      this.firstTime = currDate;
    }
    this.isCapsuleStarted = true;
    this.windowManagerInstance.checkHasPrivateWindow();
    this.windowManagerInstance.setPrivacyModeCallback();
    this.setPreferenceListen();
    // Watch the video file
    this.recorderFileManagerInstance.startFileWriteCheckWorker();
  }

  private async dealWithStateChangeInterruptByOther(): Promise<void> {
    LogUtil.warn(TAG, 'record stopped interrupted by other');
    EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_OTHER_RECORDING);
    this.setStopTime(Date.now());
    await this.stop();
    RecorderUtil.postKillProcessMessage();
  }

  /* instrument ignore next */
  private async setAVScreenCaptureErrorCallback() {
    this.recorderFileManagerInstance.getAvScreenCaptureRecorder()!.on('error', async (error) => {
      LogUtil.warn(TAG, 'error occurred during recording by: ', error.message);
      switch (error.code) {
        case MEDIA_AVERRORCODE_AVERR_SERVICE_DIED:
        case media.AVErrorCode.AVERR_SERVICE_DIED: {
          EventReportUtil.setErrorReason(RuntimeError.ERROR_REASON_RECORDING_SERVICE_FAULT);
          await this.recorderFileManagerInstance.setVideoAssetPending();
          await this.release();
          this.stop(true);
          break;
        }
        default: {
          EventReportUtil.setErrorReason(UNKNOWN_REASON);
          break;
        }
      }
      EventReportUtil.reportErrorEvent({ 'REASON': EventReportUtil.getErrorReason() })
      EventReportUtil.setStopType(UNKNOWN_REASON);
    })
  }

  private async initPreparedVideoRecorder(): Promise<void> {
    if (!this.recorderFileManagerInstance.getVideoFd()) {
      LogUtil.info(TAG, `current fd is ${this.recorderFileManagerInstance.getVideoFd()}`)
      LogUtil.error(TAG, 'Please create a video asset and open the file first.')
      return;
    }
    try {
      this.recorderFileManagerInstance.setAvScreenCaptureRecorder(await media.createAVScreenCaptureRecorder());
      this.setAVScreenCaptureCallback();
      this.setAVScreenCaptureErrorCallback();
      await this.micManagerInstance.getMicEnabledState(async (enabled) => {
        LogUtil.info(TAG, 'isMicOn = ' + enabled);
        await this.micManagerInstance.setMicEnabled(enabled, this.recorderFileManagerInstance);
      });
      const config = await this.recorderConfig.getVideoConfig(this.recorderFileManagerInstance.getVideoFd(),
        this.globalThisInstance.getObject('selectDisplayId') as number);
      LogUtil.warn(TAG, `VideoRecordConfig--fd: ${config.fd} frameWidth: ${config.frameWidth}
        frameHeight: ${config.frameHeight} displayId:${config.displayId}`);
      await this.recorderFileManagerInstance.getAvScreenCaptureRecorder()!.init(config);
      LogUtil.info(TAG, 'avScreenCaptureRecorder init finished');
    } catch (error) {
      await this.handleError(error, 'create_video_recorder_and_prepare', true);
      await this.recorderFileManagerInstance.setVideoAssetPending();
      this.release();
      await this.stop(true);
    }
  }

  /* instrument ignore next */
  async dealByType(type: WorkerType) {
    switch (type) {
      case WorkerType.VIDEO_FILE_CHANGE:
        await this.stopWhenFileChange();
        break;
      case WorkerType.CHECK_FREE_SPACE:
        await this.stopWhenLackSpace();
        break;
      case WorkerType.CHECK_VIDEO_SIZE:
        await this.createNewVideoFile();
        break;
      default:
        LogUtil.info(TAG, 'The callback type of the file write check is incorrect');
    }
  }

  /* instrument ignore next */
  private async stopWhenFileChange() {
    LogUtil.warn(TAG, 'The video file had been changed or removed, stop recording');
    EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_FILE_CHANGED);
    this.setStopTime(Date.now());
    RecorderToast.getInstance().showToast('stop_reason_file_changed_toast');
    await this.stop(true);
    RecorderUtil.postKillProcessMessage();
    return;
  }

  private async stopWhenLackSpace() {
    LogUtil.warn(TAG, 'The free space is less than 128 MB, stop recording.');
    EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_LOW_STORAGE);
    this.stop(true);
    RecorderToast.getInstance().showToast('stop_reason_phone_memory_full_toast');
    return;
  }

  private async createNewVideoFile() {
    LogUtil.warn(TAG, 'The video file size reaches the maximum. Switch to a new video file.');
    EventReportUtil.setStopType(UNKNOWN_REASON);
    await this.recorderFileManagerInstance.getAvScreenCaptureRecorder()!.stopRecording();
    await this.release();
    this.recorderTimes += 1;
    this.setStartTime(Date.now());
    this.recordingNewVideoFile();
    return;
  }

  private async recordingNewVideoFile(isFirstTime?: boolean): Promise<void> {
    let eventName = '';
    try {
      await this.recorderFileManagerInstance.createVideoAsset(this.recorderTimes);
      this.setKeyObserver();
    } catch (error) {
      await this.handleError(error, eventName, true);
      await this.recorderFileManagerInstance.setVideoAssetPending();
      await this.release();
      this.recorderFileManagerInstance.setAvScreenCaptureRecorder(undefined);
      await this.stop(true);
      return;
    }
    try {
      // Initialize Video Recorder
      clearTimeout(this.screenStartTimeoutId);
      await this.initPreparedVideoRecorder();
      LogUtil.info(TAG, 'Begin to videoRecorder.start!');
      Trace.begin(TraceConst.START_SCREEN_RECORDING_TRACE_MEDIA);
      this.recordStartTimer();
      this.decorateStartRecording(() => {
        if (!this.recorderFileManagerInstance.getAvScreenCaptureRecorder()) {
          LogUtil.warn(TAG, `AvScreenCaptureRecorder is invalid`);
          return;
        }
        this.recorderFileManagerInstance.getAvScreenCaptureRecorder()?.startRecording().catch((e: BusinessError) => {
          LogUtil.error(TAG, `AvScreenCaptureRecorder startRecording, error code: ${e?.code}, message: ${e?.message}`);
        });
      }, isFirstTime);
    } catch (error) {
      LogUtil.error(TAG, 'the error will handle in on error callback. error info = ' + JSON.stringify(error));
      clearTimeout(this.screenStartTimeoutId);
      await this.handleError(error, 'start_video_recorder', true);
      await this.recorderFileManagerInstance.setVideoAssetPending();
      await this.release();
      await this.stop(true);
      this.handleStartResultException(error);
    }
  }

  private decorateStartRecording(startTask: () => void, isFirstTime?: boolean) {
    const decorateStartTask = () => {
      try {
        startTask()
      } catch (e) {
        LogUtil.error(TAG, `startTask execute failed, error code: ${e?.code}, message: ${e?.message}`);
      }
    }
    let triggerType = this.globalThisInstance.getObject('triggerType') as string;
    // 首次控制中心录屏延迟200ms
    if (triggerType === DEFAULT_TRIGGER_TYPE && isFirstTime) {
      LogUtil.info(TAG, 'trigger type control center, need delay');
      setTimeout(decorateStartTask, TIME_TO_PREPARE_DATA);
    } else {
      decorateStartTask();
    }
  }

  /* instrument ignore next */
  private handleStartResultException(error: BusinessError): void {
    switch (error.code) {
      case media.AVErrorCode.AVERR_SERVICE_DIED: {
        EventReportUtil.setStartResult(StartRecordTriggerResult.RESULT_ERROR_BY_VIDEO_SERVICE_UNAVAILABLE);
        break;
      }
      case INSUFFICIENT_VIDEO_SERVICE_RESOURCES_CODE: {
        EventReportUtil.setStartResult(StartRecordTriggerResult.RESULT_ERROR_BY_INSUFFICIENT_VIDEO_SERVICE_RESOURCES);
        break;
      }
      default: {
        EventReportUtil.setStartResult(UNKNOWN_REASON);
        break;
      }
    }
    EventReportUtil.setStartFaultReason(error.message);
    EventReportUtil.reportStartRecordEvent();
  }

  /**
   * Release resources used for screen recording
   */
  async release(isClose?: boolean): Promise<void> {
    await this.recorderFileManagerInstance.releaseScreenCaptureRecorder();
    await this.recorderFileManagerInstance.releaseVideoAsset(isClose);
    await this.recorderFileManagerInstance.releaseFileWatcher();
  }

  /**
   * get trace state before recording
   */
  getTraceBeforeRecorder() {
    try {
      let initCheckedListen = this.globalThisInstance!.getObject('initChecked') as boolean;
      if (initCheckedListen !== undefined) {
        this.initChecked = initCheckedListen;
        LogUtil.info(TAG, `current in same process: ${this.initChecked}`);
      } else {
        LogUtil.info(TAG, `current in new process: ${initCheckedListen}`);
        this.initChecked = this.notificationManager.getCurrentShowTouchState();
      }
      this.globalThisInstance!.setObject('initChecked', this.initChecked);
      LogUtil.warn(TAG, `trace before start recorder ${this.initChecked}`);
      RecordManager.initBubbleInSettings = this.initChecked;
    } catch (e) {
      LogUtil.error(TAG, `trace recorder fail, error code: ${e?.code}, message: ${e?.message}`);
    }
  }

  /**
   * Stop screen recording when triggered again
   */
  async triggerAgain(triggerType: string): Promise<void> {
    LogUtil.warn(TAG, 'Screen recording needs to be stopped when screen recording is triggered for the second time.');
    switch (triggerType) {
      case 'default_trigger_type': {
        EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_CONTROL_CENTER);
        break;
      }
      case 'knuckle': {
        EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_KNUCKLE);
        break;
      }
      case 'hot-key': {
        EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_HOT_KEY);
        break;
      }
    }
    this.setStopTime(Date.now());
    /* instrument ignore if */
    if (triggerType === DEFAULT_TRIGGER_TYPE) {
      //Wait for control-center fading out.
      await new Promise<number>(resolve => setTimeout(resolve, CONTROL_PANEL_FADE_OUT_TIME));
    }
    await this.stop();
  }

  /**
   * Triggering a Screen Recording Event
   *
   * Screen recording starts when the first trigger is triggered.
   * Screen recording ends when the second trigger is triggered.
   */
  async trigger(triggerType: string, selectId: number | undefined, isBCRecord: boolean): Promise<void> {
    // 若正在录屏，则触发停止录屏
    if (this.isRecording) {
      await this.triggerAgain(triggerType);
      return;
    }

    // 获取屏幕信息
    let displays: display.Display[] = await this.getDisplays();
    if (displays.length === 0) {
      return;
    }

    // 触发设备录屏
    await this.startTrigger((displays[0] as display.Display).id);
  }

  async getDisplays(): Promise<display.Display[]> {
    // 获取屏幕信息
    let displays: display.Display[] = await DisplayUtil.getAllDisplays();
    displays = displays.filter(display => display.id < SCREEN_RECORDER_MIN_DISPLAYID);

    if (!displays || displays.length === 0) {
      LogUtil.error(TAG, `screen record displays is invalid.`);
      return [];
    }
    return displays;
  }

  /**
   * Triggering a Screen Recording Event
   *
   * Screen recording starts when the first trigger is triggered.
   * Screen recording ends when the second trigger is triggered.
   */
  /* instrument ignore next */
  async startTrigger(displayId: number | undefined = undefined): Promise<void> {
    try {
      this.getTraceBeforeRecorder();
      const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
      const freeSpace = storageManager.getFreeSizeSync(context!.filesDir);
      if (freeSpace <= MIN_FREE_SPACE_IN_BYTE) {
        RecorderToast.getInstance().showToast('storageFull_changeto_sdcard_new');
        EventReportUtil.setStartResult(StartRecordTriggerResult.RESULT_ERROR_BY_LOW_STORAGE);
        EventReportUtil.setStartFaultReason();
        EventReportUtil.reportStartRecordEvent();
        RecorderUtil.postKillProcessMessage();
        return;
      }
    } catch (error) {
      LogUtil.error(TAG, 'Failed to register callback. Code: ' + JSON.stringify(error));
    }

    this.isRecording = true;
    LogUtil.info(TAG, 'Start recording!');
    this.globalThisInstance!.setObject('isRecording', true);
    this.dataPreferences.setPreferenceKeyValueSync('isRecording', true);
    this.setRecorderTimer();
    try {
      await this.recordingNewVideoFile(true);
    } catch (error) {
      EventReportUtil.setStopType(UNKNOWN_REASON);
      await this.handleError(error, 'recorder new video file');
      await this.stop();
    }
  }

  /* instrument ignore next */
  private setRecorderTimer() {
    try {
      if (this.workThread) {
        LogUtil.warn(TAG, 'the workThread object already exists');
        this.workThread.terminate();
      }
      this.workThread = new worker.ThreadWorker('../worker/TimestampWorker');
      const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
      const sendableContext: sendableContextManager.SendableContext =
        sendableContextManager.convertFromContext(context);
      const sendableObject: SendableObject = new SendableObject(sendableContext, WorkerType.SET_TIMER);
      this.workThread.postMessageWithSharedSendable(sendableObject);
    } catch (error) {
      LogUtil.info(TAG, `an error occurred in the setRecorderTimer method` + error);
    }
  }

  /* instrument ignore next */
  private async recordStartTimer() {
    this.isScreenRecorderStart = false;
    this.screenStartTimeoutId = setTimeout(async () => {
      if (!this.isScreenRecorderStart) {
        LogUtil.warn(TAG, `Starting screen recording timed out.`);
        RecorderToast.getInstance().showToast('recorder_file_failed_toast');
        await this.recorderFileManagerInstance.setVideoAssetPending();
        this.isStartAfterTimeout = true;
        this.killProcess();
      }
    }, 5000);
  }

  private killProcess() {
    setTimeout(async () => {
      const context =
        GlobalThisUtil.getInstance()!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
      context!.terminateSelf();
    }, 1500);
  }

  /**
   * Stop recording
   *
   * @params isAutomaticStop Indicates whether the automatic stop is performed.
   * @return Status of the video recorder after this function is executed
   */
  async stop(isAutomaticStop?: boolean, width?: number, height?: number): Promise<void> {
    LogUtil.warn(TAG, 'Stop recording!');
    this.windowManagerInstance.initPreviewImage();
    this.resetData();
    this.releaseRecordingTimer();
    this.cancelPrivacyModeCallback();
    const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    let ret =
      settings.unregisterKeyObserver(context, `settings.input.show_touch_hint`, settings.domainName.DEVICE_SHARED);
    LogUtil.info(TAG, `unregister setting listener ${ret}`);
    CommonUtil.clearPreviewTimeout();
    this.micManagerInstance.setIsMicUnavailable(false);
    LogUtil.info(TAG,
      '!this.avScreenCaptureRecorder = ' + !this.recorderFileManagerInstance.getAvScreenCaptureRecorder());
    /* instrument ignore if */
    if (!this.recorderFileManagerInstance.getAvScreenCaptureRecorder()) {
      LogUtil.warn(TAG, 'Recording is already stopped or not even started!');
      await this.windowManagerInstance.cancelCapsule(this.isCapsuleStarted);
      this.isCapsuleStarted = false;
      await this.windowManagerInstance.destroyCapsule();
      // 录屏停止，恢复设置项成功后关闭延迟任务
      if (this.notificationManager.handleCheckedChange(false, this.initChecked)) {
        try {
          workScheduler.stopAndClearWorks();
          LogUtil.warn(TAG, 'stopAndClearWorks');
        } catch (error) {
          LogUtil.error(TAG, 'stopAndClearWorks failed, error: ' + error.message);
        }
      }
      this.isRecording = false;
      RecorderToast.getInstance().showToast('recorder_file_failed_toast');
      return;
    }
    try {
      await this.windowManagerInstance.cancelCapsule(this.isCapsuleStarted);
      this.isCapsuleStarted = false;
      // 录屏停止，恢复设置项成功后关闭延迟任务
      if (this.notificationManager.handleCheckedChange(false, this.initChecked)) {
        try {
          workScheduler.stopAndClearWorks();
          LogUtil.warn(TAG, 'stopAndClearWorks');
        } catch (error) {
          LogUtil.error(TAG, 'stopAndClearWorks failed, error: ' + error.message);
        }
      }
      await Promise.all([
        this.decorateStopRecording(),
        this.decorateInitPreviewWindowWhenStop(width, height)
      ])
      await this.windowManagerInstance.destroyCapsule();
      const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
      CommonUtil.broadcastAccessibilityText(StringUtil.getStringByNameSync('control_stop_recording', context));
      let isLocked: boolean = screenLock.isLocked();
      LogUtil.info(TAG, 'recording stop, current Locked state is ' + isLocked);
      if (!isAutomaticStop && !isLocked) {
        this.windowManagerInstance.showPreviewWindowWhenStop(width, height);
        CommonUtil.broadcastAccessibilityText(StringUtil.getStringByNameSync('preview_image_accessibility_text',
          context), true)
      }
    } catch (error) {
      await this.handleError(error, 'stop recording');
      EventReportUtil.setStopResult(UNKNOWN_REASON);
      EventReportUtil.setStopFaultReason(error.message);
      EventReportUtil.reportStopRecordEvent();
    }
  }

  async decorateStopRecording(): Promise<void> {
    await this.recorderFileManagerInstance.getAvScreenCaptureRecorder()?.stopRecording().then(async () => {
      LogUtil.info(TAG, 'avScreenCaptureRecorder stop success');
      let duration: Decimal = new Decimal((this.stopTime - this.startRecordTime) / 1000).ceil();
      EventReportUtil.setStopResult(StopRecordTriggerResult.RESULT_SUCCESS);
      EventReportUtil.setStopFaultReason();
      EventReportUtil.reportStopRecordEvent(Date.now() - this.stopTime, duration.toNumber());
      await this.dataPreferences.setPreferenceKeyValue('isRecording', false);
      await this.release();
      this.isRecording = false;
      EventReportUtil.writeOldStopEvent('RECORDER_STOP', hiSysEvent.EventType.BEHAVIOR, null);
    }).catch(async (error: BusinessError) => {
      LogUtil.error(TAG, 'avScreenCaptureRecorder stop failed, error: ' + error.message);
      await this.handleError(error, 'release resources');
      this.handleStopResultException(error);
    })
  }

  async decorateInitPreviewWindowWhenStop(width?: number, height?: number): Promise<void> {
    try {
      if (this.globalThisInstance!.getObject('isPreViewWindowExisting') as boolean) {
        await this.windowManagerInstance.destroyPreWindow();
      }
      CommonUtil.clearPreviewTimeout();
      await this.windowManagerInstance.initPreviewWindowWhenStop(width, height);
    } catch (e) {
      LogUtil.error(TAG, `decorateInitPreviewWindowWhenStop failed, code: ${e?.code} error: ${e?.message}`);
    }
  }

  async resetData(): Promise<void> {
    this.recorderFileManagerInstance.setTimeStamp('');
    this.recorderTimes = 1;
    this.firstTime = 0;
    this.globalThisInstance!.setObject('isRecording', false);
    await this.dataPreferences.setPreferenceKeyValue(PreferencesKey.IS_RECORDING, false);
  }

  releaseRecordingTimer() {
    try {
      if (!this.workThread) {
        LogUtil.info(TAG, 'the workThread object does not exist.');
      } else {
        this.workThread.terminate();
        this.workThread = null;
        LogUtil.info(TAG, 'releaseRecordingTimer success');
      }
    } catch (error) {
      LogUtil.info(TAG, 'releaseRecordingTimer error' + error);
    }
  }

  cancelPrivacyModeCallback() {
    try {
      display.off('privateModeChange');
    } catch (err) {
      LogUtil.error(TAG, 'setPrivacyModeCallback setListener, err: ' + (err as BusinessError).message);
    }
  }

  /* instrument ignore next */
  private handleStopResultException(error: BusinessError): void {
    switch (error.code) {
      case media.AVErrorCode.AVERR_SERVICE_DIED: {
        EventReportUtil.setStopResult(StopRecordTriggerResult.RESULT_ERROR_BY_RECORDING_SERVICE_FAULT);
        break;
      }
      default: {
        EventReportUtil.setStopResult(UNKNOWN_REASON);
        break;
      }
    }
    EventReportUtil.setStopFaultReason(error.message);
    EventReportUtil.reportStopRecordEvent();
  }

  /**
   * Check if screen recording is in progress
   *
   * @return If screen recording is in progress
   */
  getIsRecording(): boolean {
    return this.isRecording;
  }

  setStartTime(startTime: number): void {
    this.startTime = startTime;
  }

  setStopTime(stopTime: number): void {
    this.stopTime = stopTime;
  }

  getIsStart(): boolean {
    return this.isScreenRecorderStart;
  }

  getStartTime(): number {
    return this.startTime;
  }

  setKeyObserver() {
    const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    settings.registerKeyObserver(context, `settings.input.show_touch_hint`, settings.domainName.DEVICE_SHARED,
      async () => {
        if (this.notificationManager.needUpdateShowTouch()) {
          let value = this.notificationManager.getCurrentShowTouchState();
          LogUtil.info(TAG, `setKeyObserver getCurrentState ->${value}`);
          await this.notificationManager.updateShowTouch(value)
          return;
        }
      });
  }

  async setPreferenceListen() {
    if (CommonUtil.checkIfDeviceIsPC()) {
      LogUtil.info(TAG, 'no need to setListener');
      return;
    }
    LogUtil.info(TAG, `set multiProcess preferences watch`);
    const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    try {
      this.preferenceListen = await dataPreferences.getPreferences(context, PREFERENCES_NAME);
    } catch (err) {
      LogUtil.error(TAG, 'setPreferenceListen getPreferences fail, err ' + (err as BusinessError).message);
      return;
    }
    let observer = (key: string) => {
      if (key === 'isMicEnabled' && this.globalThisInstance!.getObject('isMicClicked') === false) {
        LogUtil.warn(TAG, `mic changed`);
        this.notificationManager.onMicButtonClicked();
      }
      if (key === 'showTouchState' && this.globalThisInstance!.getObject('isTrackClicked') === false) {
        LogUtil.warn(TAG, `track changed`);
        this.notificationManager.onTrackButtonClicked();
      }
    }
    this.preferenceListen.on('multiProcessChange', observer);
  }

  async cancelPreferenceListen() {
    if (CommonUtil.checkIfDeviceIsPC()) {
      LogUtil.info(TAG, 'no need to cancelListener');
      return;
    }
    LogUtil.info(TAG, `cancel multiProcess preferences watch`);
    const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    try {
      this.preferenceListen = await dataPreferences.getPreferences(context, PREFERENCES_NAME);
    } catch (err) {
      LogUtil.error(TAG, 'cancelPreferenceListen getPreferences fail, err ' + (err as BusinessError).message);
      return;
    }
    let observer = (key: string) => {
      LogUtil.info(TAG, `The key ${key} is changed`);
    }
    this.preferenceListen.off('multiProcessChange', observer);
  }

  /**
   * 用于重置部分成员变量
   */
  init(): void {
    this.isStartAfterTimeout = false;
    this.setStartTime(Date.now());
    const killProcessTimeoutId = this.globalThisInstance?.getObject('killProcessTimeoutId') as number;
    killProcessTimeoutId && clearTimeout(killProcessTimeoutId);
  }

  /**
   * 停止录屏:如果正在录屏,则停止录屏
   *
   * @returns true:已停止;false:未启动录屏
   */
  public stopRecorder(): boolean {
    if (this.isRecording) {
      this.stop();
      return true;
    }
    return false;
  }
}