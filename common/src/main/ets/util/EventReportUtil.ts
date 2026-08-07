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

import bundleManager from '@ohos.bundle.bundleManager';
import type { ValueType } from '@ohos.data.ValuesBucket';
import hiSysEvent from '@ohos.hiSysEvent';

import { LogUtil } from './LogUtil';

const TAG = 'EventReportUtil';
const DOMAIN = 'SCREENRECORD_UE';
const OLD_DOMAIN = 'SCREEN_RECORDER';

export declare type BigDataMsg = Record<string, ValueType>;

// Event name: start screen record
export const EVENT_NAME_START_SCREENRECORD = 'START_SCREENRECORD';

// Event name: switch microPhone
export const EVENT_NAME_SET_SCREENRECORD_MIC = 'SET_SCREENRECORD_MIC';

// Event name: switch track
export const EVENT_NAME_SET_SCREENRECORD_TRACK = 'SET_SCREENRECORD_TRACK';

// Event name: stop record
export const EVENT_NAME_STOP_SCREENRECORD = 'STOP_SCREENRECORD';

// Event name: share screen record
export const EVENT_NAME_SHARE_SCREENRECORD = 'SHARE_SCREENRECORD';

// Event name: preview screen record
export const EVENT_NAME_PREVIEW_SCREENRECORD = 'PREVIEW_SCREENRECORD';

// Event name: hide screenrecord thumbnail
export const EVENT_NAME_HIDE_SCREENRECORD_THUMB = 'HIDE_SCREENRECORD_THUMB';

// Event name: screenrecord runtime error
const EVENT_NAME_SCREENRECORD_RUNTIME_ERROR = 'SCREENRECORD_RUNTIME_ERROR';

const KEY_TYPE = 'TYPE';

const KEY_CHOOSE = 'CHOOSE';

const KEY_RESULT = 'RESULT';

const KEY_DELAY = 'DELAY';

const KEY_DURATION = 'DURATION';

const KEY_REASON = 'REASON';

const KEY_PNAMEID = 'PNAMEID';

const KEY_PVERSIONID = 'PVERSIONID';

const KEY_SETBY = 'SET_BY';

export const ACTION_CLICK = 'click';

export const INSUFFICIENT_VIDEO_SERVICE_RESOURCES_CODE = 5400101;

// Other unknown reason code
export const UNKNOWN_REASON = 255;

export enum StartRecordTriggerType {
  //0: Control center
  TRIGGERED_TYPE_BY_CONTROL_CENTER,
  //1: Shortcut key
  TRIGGERED_TYPE_BY_SHORTCUT_KEY,
  //2: KNUCKLE
  TRIGGERED_TYPE_BY_KNUCKLE,
  //3: AI
  TRIGGERED_TYPE_BY_AI,
  //4: PC PANEL
  TRIGGERED_TYPE_BY_PANEL
}

export enum StartChoosePanelType {
  //0: FULL_SCREEN
  RECORD_TYPE_BY_FULL_SCREEN,
  //1: UP_SCREEN
  RECORD_TYPE_BY_UP_SCREEN,
  //2: DOWN_SCREEN
  RECORD_TYPE_BY_DOWN_SCREEN
}

export enum StartRecordTriggerResult {
  //0: Success
  RESULT_SUCCESS,
  //1: The video service is unavailable
  RESULT_ERROR_BY_VIDEO_SERVICE_UNAVAILABLE,
  //2: The media library is unavailable
  RESULT_ERROR_BY_MEDIA_LIBRARY_UNAVAILABLE,
  //3: Insufficient video service resources
  RESULT_ERROR_BY_INSUFFICIENT_VIDEO_SERVICE_RESOURCES,
  //4: cellular call in progress
  RESULT_ERROR_BY_CALLING,
  //5: Insufficient storage space
  RESULT_ERROR_BY_LOW_STORAGE,
  //6: Microphone is preempted
  RESULT_MICROPHONE_PREEMPTED,
  //7: The file manager is unavailable
  RESULT_ERROR_BY_FILE_MANAGER_UNAVAILABLE
}

export enum StopRecordTriggerType {
  //0: Stop button
  TRIGGERED_TYPE_BY_STOP_BUTTON,
  //1: cellular call in progress
  TRIGGERED_TYPE_BY_CELLULAR_CALL,
  //2: Interrupted by another screen recording
  TRIGGERED_TYPE_BY_OTHER_RECORDING,
  //3: Insufficient storage space
  TRIGGERED_TYPE_BY_LOW_STORAGE,
  //4: Screen off
  TRIGGERED_TYPE_BY_SCREEN_OFF,
  //5: Control center
  TRIGGERED_TYPE_BY_CONTROL_CENTER,
  //6: Knuckle
  TRIGGERED_TYPE_BY_KNUCKLE,
  //7: HOT_KEY
  TRIGGERED_TYPE_BY_HOT_KEY,
  //8: FILE_CHANGED
  TRIGGERED_TYPE_BY_FILE_CHANGED,
  //9: InsightIntentExecutor
  TRIGGERED_TYPE_BY_INSIGHT_INTENT_EXECUTOR
}

export enum StopRecordTriggerResult {
  //0: Success
  RESULT_SUCCESS,
  //1: Screen Recording Service Fault
  RESULT_ERROR_BY_RECORDING_SERVICE_FAULT,
  //2: Video saving exception
  RESULT_ERROR_BY_VIDEO_SAVING_EXCEPTION,
  //3: Thumbnail exception
  RESULT_ERROR_BY_THUMBNAIL_EXCEPTION
}

export enum SetSwitchType {
  //0: Switch ON
  TRIGGERED_TYPE_SWITCH_ON,
  //1: Switch OFF
  TRIGGERED_TYPE_SWITCH_OFF
}

export enum SetSwitchResult {
  //0: Success
  RESULT_SUCCESS,
  //1: failed
  RESULT_FAILED
}

export enum RuntimeError {
  //0: Screen Recording Service Fault
  ERROR_REASON_RECORDING_SERVICE_FAULT
}

/**
 * Event Report Util
 *
 * @since 2022-09-03
 */
export class EventReportUtil {
  private static startType: number = StartRecordTriggerType.TRIGGERED_TYPE_BY_CONTROL_CENTER;

  private static choosePanelType: number = StartChoosePanelType.RECORD_TYPE_BY_FULL_SCREEN;

  private static startResult: number = StartRecordTriggerResult.RESULT_SUCCESS;

  private static switchMicType: number = SetSwitchType.TRIGGERED_TYPE_SWITCH_ON;

  private static switchMicResult: number = SetSwitchResult.RESULT_SUCCESS;

  private static switchTrackType: number = SetSwitchType.TRIGGERED_TYPE_SWITCH_ON;

  private static switchTrackResult: number = SetSwitchResult.RESULT_SUCCESS;

  private static stopType: number = UNKNOWN_REASON;

  private static stopResult: number = StopRecordTriggerResult.RESULT_SUCCESS;

  private static errorReason: number = UNKNOWN_REASON;

  private static startFaultReason: string = '';

  private static stopFaultReason: string = '';

  public static setStartType(startType: number): void {
    EventReportUtil.startType = startType;
  }

  public static getStartType(): number {
    return EventReportUtil.startType;
  }

  public static setStartResult(startResult: number): void {
    EventReportUtil.startResult = startResult;
  }

  public static setChoosePanelType(choosePanelType: number): void {
    EventReportUtil.choosePanelType = choosePanelType;
  }

  public static getChoosePanelType(): number {
    return EventReportUtil.choosePanelType;
  }

  public static getStartResult(): number {
    return EventReportUtil.startResult;
  }

  public static setStartFaultReason(startFaultReason: string = ''): void {
    EventReportUtil.startFaultReason = startFaultReason;
  }

  public static getStartFaultReason(): string {
    return EventReportUtil.startFaultReason;
  }

  public static setSwitchMicType(switchMicType: number): void {
    EventReportUtil.switchMicType = switchMicType;
  }

  public static getSwitchMicType(): number {
    return EventReportUtil.switchMicType;
  }

  public static setSwitchMicResult(switchMicResult: number): void {
    EventReportUtil.switchMicResult = switchMicResult;
  }

  public static getSwitchMicResult(): number {
    return EventReportUtil.switchMicResult;
  }

  public static setSwitchTrackType(switchTrackType: number): void {
    EventReportUtil.switchTrackType = switchTrackType;
  }

  public static getSwitchTrackType(): number {
    return EventReportUtil.switchTrackType;
  }

  public static setSwitchTrackResult(switchTrackResult: number): void {
    EventReportUtil.switchTrackResult = switchTrackResult;
  }

  public static getSwitchTrackResult(): number {
    return EventReportUtil.switchTrackResult;
  }

  public static setStopType(stopType: number): void {
    EventReportUtil.stopType = stopType;
  }

  public static getStopType(): number {
    return EventReportUtil.stopType;
  }

  public static setStopResult(stopResult: number): void {
    EventReportUtil.stopResult = stopResult;
  }

  public static getStopResult(): number {
    return EventReportUtil.stopResult;
  }

  public static setStopFaultReason(stopFaultReason: string = ''): void {
    EventReportUtil.stopFaultReason = stopFaultReason;
  }

  public static getStopFaultReason(): string {
    return EventReportUtil.stopFaultReason;
  }

  public static setErrorReason(errorReason: number): void {
    EventReportUtil.errorReason = errorReason;
  }

  public static getErrorReason(): number {
    return EventReportUtil.errorReason;
  }

  private static currentBundleInfo: bundleManager.BundleInfo | undefined = undefined;

  public static reportStartRecordEvent(duration: number = -1): void {
    /* instrument ignore if */
    if (this.getStartType() === StartRecordTriggerType.TRIGGERED_TYPE_BY_PANEL) {
      EventReportUtil.reportEvent(EVENT_NAME_START_SCREENRECORD,
        {
          [KEY_TYPE]: this.getStartType(),
          [KEY_CHOOSE]: this.getChoosePanelType(),
          [KEY_RESULT]: this.getStartResult(),
          [KEY_DELAY]: duration,
          [KEY_REASON]: this.getStartFaultReason()
        });
    } else {
      EventReportUtil.reportEvent(EVENT_NAME_START_SCREENRECORD,
        {
          [KEY_TYPE]: this.getStartType(),
          [KEY_RESULT]: this.getStartResult(),
          [KEY_DELAY]: duration,
          [KEY_REASON]: this.getStartFaultReason()
        });
    }
  }

  public static reportStopRecordEvent(duration: number = -1, recordDuration: number = 0): void {
    EventReportUtil.reportEvent(EVENT_NAME_STOP_SCREENRECORD,
      {
        [KEY_TYPE]: this.getStopType(),
        [KEY_RESULT]: this.getStopResult(),
        [KEY_DELAY]: duration,
        [KEY_DURATION]: recordDuration,
        [KEY_REASON]: this.getStopFaultReason()
      });
  }

  public static reportTrackStateEvent(isTriggeredByUser: boolean): void {
    EventReportUtil.reportEvent(EVENT_NAME_SET_SCREENRECORD_TRACK,
      {
        [KEY_TYPE]: EventReportUtil.getSwitchTrackType(),
        [KEY_RESULT]: EventReportUtil.getSwitchTrackResult(),
        [KEY_SETBY]: isTriggeredByUser ? 'USER' : 'SYS'
      });
  }

  public static reportEvent(eventName, params?: object | BigDataMsg): void {
    this.constructEventMsg(params).then((msg: object): void => {
      this.writeSysEvent(eventName, hiSysEvent.EventType.BEHAVIOR, msg);
    });
  }

  public static reportErrorEvent(params): void {
    this.constructEventMsg(params).then((msg: object): void => {
      this.writeSysEvent(EVENT_NAME_SCREENRECORD_RUNTIME_ERROR, hiSysEvent.EventType.FAULT, msg);
    });
  }

  public static getTriggerTypeCodeByReason(reason: string): number {
    let triggerType: number = StartRecordTriggerType.TRIGGERED_TYPE_BY_CONTROL_CENTER;
    switch (reason) {
      case 'hot-key': {
        triggerType = StartRecordTriggerType.TRIGGERED_TYPE_BY_SHORTCUT_KEY;
        break;
      }
      case 'knuckle': {
        triggerType = StartRecordTriggerType.TRIGGERED_TYPE_BY_KNUCKLE;
        break;
      }
      case 'default_trigger_type': {
        triggerType = StartRecordTriggerType.TRIGGERED_TYPE_BY_CONTROL_CENTER;
        break;
      }
      default: {
        LogUtil.info(TAG, `the reason is outliers, return control center`);
        triggerType = StartRecordTriggerType.TRIGGERED_TYPE_BY_CONTROL_CENTER;
        break;
      }
    }
    return triggerType;
  }

  public static async writeOldStopEvent(eventName, eventType, params): Promise<void> {
    try {
      hiSysEvent.write({
        domain: OLD_DOMAIN,
        name: eventName,
        eventType: eventType,
        params: params
      }, () => {
        LogUtil.info(TAG, `record stop domain: ${OLD_DOMAIN}, name: ${eventName}, eventType: ${eventType}`);
      });
      LogUtil.info(TAG, 'success to write sys event');
    } catch (error) {
      LogUtil.error(TAG, 'failed to write sys event because: ', error.message);
    }
  }

  private static async writeSysEvent(eventName, eventType, params): Promise<void> {
    try {
      hiSysEvent.write({
        domain: DOMAIN,
        name: eventName,
        eventType: eventType,
        params: params
      }).then(
        (val) => {
          LogUtil.info(TAG,
            `success to writeSysEvent event, domain: ${DOMAIN}, eventName: ${eventName}, eventType: ${eventType}, eventInfo: ${JSON.stringify(params)}`);
        }
      ).catch(
        (err) => {
          LogUtil.info(TAG, `domain: ${DOMAIN}, eventName: ${eventName} error because: ${err.message}`);
        }
      );
    } catch (error) {
      LogUtil.error(TAG, 'failed to writeSysEvent sys event because: ', error.message);
    }
  }

  private static async constructEventMsg(eventMsg?: object | BigDataMsg): Promise<object> {
    let bundleInfo = await this.loadBundleInfo();
    if (!bundleInfo) {
      return eventMsg;
    }

    let packInfo = {
      [KEY_PNAMEID]: bundleInfo.name,
      [KEY_PVERSIONID]: bundleInfo.versionName
    };
    let msg = eventMsg ? Object.assign({}, packInfo, eventMsg) : packInfo;
    return msg;
  }

  private static async loadBundleInfo(): Promise<bundleManager.BundleInfo | undefined> {
    if (this.currentBundleInfo) {
      return this.currentBundleInfo;
    }
    try {
      let bundleFlag = bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT;
      this.currentBundleInfo = bundleManager.getBundleInfoForSelfSync(bundleFlag);
      return this.currentBundleInfo;
    } catch (e) {
      LogUtil.error(TAG, `loadBundleInfo failed, error code: ${e?.code} message: ${e?.message}`);
    }
    return undefined;
  }
}