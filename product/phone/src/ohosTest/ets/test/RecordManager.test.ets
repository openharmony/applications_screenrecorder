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

import { CCMUtil, CommonUtil, EventReportUtil, GlobalThisUtil, LogUtil } from '@ohos/common';
import {
  NotificationManager,
  RecordManager,
  SupportResolution,
  MicManager,
  RecorderToast
} from '@ohos/screen-recorder';
import { promptAction } from '@kit.ArkUI';
import { audio } from '@kit.AudioKit';
import { call } from '@kit.TelephonyKit';
import { Driver } from '@ohos.UiTest';
import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { Constants } from '../Constants';
import { controlCenterScreenRecord, notificationStop } from './common';
import { COMMON_DELAY, MOVING_DELAY, SWIPE_FAST, SWIPE_X, SWIPE_Y, SWIPE_Y_END } from './types';

const TAG = 'RecordManagerTest';

/**
 * Record manager testcases
 *
 * @since 2023-07-15
 */
export default function RecordManagerTest() {
  describe('ActsRecordManagerTest', () => {
    const driver = Driver.create();

    it('testTrigger', 0, async () => {
      try {
        await driver.delayMs(COMMON_DELAY);
        LogUtil.info(TAG, 'Triggering a screen recording event first');
        await controlCenterScreenRecord(driver);
        LogUtil.info(TAG, 'driver start screen record');
        await driver.delayMs(MOVING_DELAY);
        // Stop recording
        LogUtil.info(TAG, 'Triggering a screen recording event second');
        await controlCenterScreenRecord(driver);
      } catch (e) {
        expect().assertFail()
      }
    });
  });

  describe('dealWithStateChangeStopByCall_test', () => {
    const driver = Driver.create();

    beforeEach(async () => {
      await driver.delayMs(MOVING_DELAY);
      await controlCenterScreenRecord(driver);
      await driver.delayMs(COMMON_DELAY);
    });

    it('error_changeToLightMode', 0, async () => {
      LogUtil.info(TAG, 'Click stop button');
      await driver.delayMs(COMMON_DELAY);

      let isSupport = call.hasVoiceCapability();
      if (isSupport) {
        try {
          // 如果设备支持呼叫能力，则继续跳转到拨号界面，并显示拨号的号码
          await call.makeCall(Constants.PHONE_NUMBER);
          await driver.delayMs(COMMON_DELAY);
          await driver.click(Constants.PHONE_CALL_BUTTON_X, Constants.PHONE_CALL_BUTTON_Y);
          await driver.delayMs(COMMON_DELAY);
          await driver.click(Constants.HAND_UP_BUTTON_X, 1400);
          await driver.delayMs(200);
          await notificationStop(driver);
          await driver.click(Constants.HAND_UP_BUTTON_X, Constants.HAND_UP_BUTTON_Y);
          await driver.delayMs(COMMON_DELAY);
          await driver.swipe(SWIPE_X, SWIPE_Y, SWIPE_X, SWIPE_Y_END, SWIPE_FAST);
        } catch (e) {
          expect().assertFail()
        }
      }
    });
  })

  describe('showToastTest', () => {
    const driver = Driver.create();

    it('showToast_test', 0, async () => {
      try {
        await driver.delayMs(COMMON_DELAY);
        await controlCenterScreenRecord(driver);
        await driver.delayMs(MOVING_DELAY);
        RecorderToast.getInstance().showToast('hw_video_without_voice_2', promptAction.ToastShowMode.SYSTEM_TOP_MOST);
        await driver.delayMs(MOVING_DELAY);
        await controlCenterScreenRecord(driver);
      } catch (e) {
        expect().assertFail()
      }
    });
  });

  describe('triggerAgain_test', () => {
    let recordManager: RecordManager = RecordManager.getInstance();
    let mocker: MockKit = new MockKit();
    it('triggerAgain_test_when_triggerType_is_default_trigger_type', 0, async () => {
      let mockSetStopType: Function = mocker.mockFunc(EventReportUtil, EventReportUtil.setStopType);
      when(mockSetStopType)(ArgumentMatchers.any).afterReturnNothing();
      let result = recordManager.triggerAgain('default_trigger_type');
      expect(result).assertPromiseIsResolved();
      mocker.ignoreMock(EventReportUtil, EventReportUtil.setStopType);
    });

    it('triggerAgain_test_when_triggerType_is_knuckle', 0, async () => {
      let mockSetStopType: Function = mocker.mockFunc(EventReportUtil, EventReportUtil.setStopType);
      when(mockSetStopType)(ArgumentMatchers.any).afterReturnNothing();
      let result = recordManager.triggerAgain('knuckle');
      expect(result).assertPromiseIsResolved();
      mocker.ignoreMock(EventReportUtil, EventReportUtil.setStopType);
    });

    it('triggerAgain_test_when_triggerType_is_hot_key', 0, async () => {
      let mockSetStopType: Function = mocker.mockFunc(EventReportUtil, EventReportUtil.setStopType);
      when(mockSetStopType)(ArgumentMatchers.any).afterReturnNothing();
      let result = recordManager.triggerAgain('hot-key');
      expect(result).assertPromiseIsResolved();
      mocker.ignoreMock(EventReportUtil, EventReportUtil.setStopType);
    });

    it('triggerAgain_test_when_triggerType_is_any_type', 0, async () => {
      let mockSetStopTime: Function = mocker.mockFunc(recordManager, recordManager.setStopTime);
      when(mockSetStopTime)(ArgumentMatchers.any).afterReturnNothing();
      let result = recordManager.triggerAgain('default_trigger_type');
      expect(result).assertPromiseIsResolved();
      mocker.ignoreMock(recordManager, recordManager.setStopTime);
    });

    it('triggerAgain_test_when_triggerType_is_default_trigger_type_one', 0, async () => {
      let result = recordManager.triggerAgain('default_trigger_type');
      expect(result).assertPromiseIsResolved();
    });

    it('triggerAgain_test_should_stop_recording_when_triggerType_is_any_type', 0, async () => {
      let mockStop: Function = mocker.mockFunc(recordManager, recordManager.stop);
      when(mockStop)(ArgumentMatchers.any).afterReturn(Promise.resolve());
      let result = recordManager.triggerAgain('default_trigger_type');
      expect(result).assertPromiseIsResolved();
      mocker.ignoreMock(recordManager, recordManager.stop);
    });

    it('setPreferenceListen_test_when_device_is_PC', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockGetDeviceType: Function = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPC);
      when(mockGetDeviceType)().afterReturn(true);
      let result = recordManager.setPreferenceListen();
      expect(result).assertPromiseIsResolved();
      mocker.ignoreMock(CommonUtil, CommonUtil.checkIfDeviceIsPC);
    });

    it('cancelPreferenceListen_test_when_device_is_PC', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockGetDeviceType: Function = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPC);
      when(mockGetDeviceType)().afterReturn(true);
      let result = recordManager.cancelPreferenceListen();
      expect(result).assertPromiseIsResolved();
      mocker.ignoreMock(CommonUtil, CommonUtil.checkIfDeviceIsPC);
    });
  });

  describe('setPreferenceListen_test', () => {
    let recordManager: RecordManager = RecordManager.getInstance();
    it('setPreferenceListen_test_should_return_immediately_when_device_is_PC', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPC);
      when(mockFunc)().afterReturn(true);
      let result = recordManager.setPreferenceListen();
      expect(result).assertPromiseIsResolved();
      mocker.ignoreMock(CommonUtil, CommonUtil.checkIfDeviceIsPC);
    });

    it('should_handle_error_when_device_is_not_PC', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPC);
      when(mockFunc)().afterReturn(false);
      let result = recordManager.setPreferenceListen();
      expect(result).assertPromiseIsResolved();
      mocker.ignoreMock(CommonUtil, CommonUtil.checkIfDeviceIsPC);
    });
  });

  describe('cancelPreferenceListen_test', () => {
    let recordManager: RecordManager = RecordManager.getInstance();
    it('cancelPreferenceListen_test_should_return_immediately_when_device_is_PC', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPC);
      when(mockFunc)().afterReturn(true);
      let result = recordManager.cancelPreferenceListen();
      expect(result).assertPromiseIsResolved();
      mocker.ignoreMock(CommonUtil, CommonUtil.checkIfDeviceIsPC);
    });

    it('cancelPreferenceListen_test_when_device_is_not_PC', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPC);
      when(mockFunc)().afterReturn(false);
      let result = recordManager.cancelPreferenceListen();
      expect(result).assertPromiseIsResolved();
      mocker.ignoreMock(CommonUtil, CommonUtil.checkIfDeviceIsPC);
    });
  })

  describe('setNotificationSubscriber_test', () => {
    let notificationManager: NotificationManager = NotificationManager.getInstance();
    it('should_set_notification_subscriber_when_not_subscribed', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockSetNotificationSubscriber: Function =
        mocker.mockFunc(notificationManager, notificationManager.setNotificationSubscriber);
      when(mockSetNotificationSubscriber)([]).afterReturnNothing();
      let globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
      let mockGetObject: Function = mocker.mockFunc(globalThisInstance, globalThisInstance.getObject);
      when(mockGetObject)(['isNotificationSubscribed']).afterReturn(false);
      let result = notificationManager.createNotification();
      expect(result).assertPromiseIsResolved();
      mocker.ignoreMock(notificationManager, notificationManager.setNotificationSubscriber);
      mocker.ignoreMock(globalThisInstance, globalThisInstance.getObject);
    });

    it('should_send_notification_request_when_subscribed', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockSetNotificationSubscriber: Function =
        mocker.mockFunc(notificationManager, notificationManager.setNotificationSubscriber);
      when(mockSetNotificationSubscriber)([]).afterReturnNothing();
      let globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
      let mockGetObject: Function = mocker.mockFunc(globalThisInstance, globalThisInstance.getObject);
      when(mockGetObject)(['isNotificationSubscribed']).afterReturn(true);
      let result = notificationManager.createNotification();
      expect(result).assertPromiseIsResolved();
      mocker.ignoreMock(notificationManager, notificationManager.setNotificationSubscriber);
      mocker.ignoreMock(globalThisInstance, globalThisInstance.getObject);
    });
  })

  describe('setPcMicEnableState_test', () => {
    let micManager: MicManager = MicManager.getInstance();
    it('should_set_pcMicEnableState_to_true_when_microphone_is_not_muted', 0, async () => {
      let audioManager: audio.AudioManager = audio.getAudioManager();
      const groupid = audio.DEFAULT_VOLUME_GROUP_ID;
      const audioVolumeGroupManager: audio.AudioVolumeGroupManager
        = await audioManager.getVolumeManager().getVolumeGroupManager(groupid);
      let pcMicEnableState = false;
      audioVolumeGroupManager.isMicrophoneMute().then((value) => {
        pcMicEnableState = value;
      });
      await micManager.checkPcMicState();
      expect(pcMicEnableState).assertEqual(false);
    });

    it('should_set_pcMicEnableState_to_false_when_microphone_is_muted', 0, async () => {
      let audioManager: audio.AudioManager = audio.getAudioManager();
      const groupid = audio.DEFAULT_VOLUME_GROUP_ID;
      const audioVolumeGroupManager: audio.AudioVolumeGroupManager
        = await audioManager.getVolumeManager().getVolumeGroupManager(groupid);
      let pcMicEnableState = true;
      audioVolumeGroupManager.isMicrophoneMute().then((value) => {
        pcMicEnableState = value;
      });
      await micManager.checkPcMicState();
      expect(pcMicEnableState).assertInstanceOf("Boolean");
    });
  })

  describe('setInitChecked_test', () => {
    it('should_set_initChecked_to_true_when_initChecked_is_undefined', 0, async () => {
      let recordManager: RecordManager = RecordManager.getInstance();
      let mocker: MockKit = new MockKit();
      let globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
      let mockfunc: Function = mocker.mockFunc(globalThisInstance, globalThisInstance.getObject);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturn(undefined);
      let mockfunc2: Function = mocker.mockFunc(globalThisInstance, globalThisInstance.setObject);
      when(mockfunc2)(ArgumentMatchers.anyString, ArgumentMatchers.anyObj).afterReturnNothing();
      try {
        await recordManager.getTraceBeforeRecorder();
      } catch (e) {
        expect().assertFail();
      }
      mocker.ignoreMock(globalThisInstance, globalThisInstance.getObject);
      mocker.ignoreMock(globalThisInstance, globalThisInstance.setObject);
    });

    it('should_set_initChecked_to_false_when_initChecked_is_defined', 0, async () => {
      let recordManager: RecordManager = RecordManager.getInstance();
      let mocker: MockKit = new MockKit();
      let globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
      let mockfunc: Function = mocker.mockFunc(globalThisInstance, globalThisInstance.getObject);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturn(false);
      let mockfunc2: Function = mocker.mockFunc(globalThisInstance, globalThisInstance.setObject);
      when(mockfunc2)(ArgumentMatchers.anyString, ArgumentMatchers.anyObj).afterReturnNothing();
      try {
        await recordManager.getTraceBeforeRecorder();
      } catch (e) {
        expect().assertFail();
      }
      mocker.ignoreMock(globalThisInstance, globalThisInstance.getObject);
      mocker.ignoreMock(globalThisInstance, globalThisInstance.setObject);
    });
  })

  describe('setStartTimeCorrectly_test', () => {
    it('should_return_false_when_isRecording_is_false', 0, () => {
      let recordManager: RecordManager = RecordManager.getInstance();
      expect(recordManager.getIsRecording()).assertEqual(false);
    });

    it('should_set_start_time_correctly', 0, () => {
      let recordManager: RecordManager = RecordManager.getInstance();
      recordManager.setStartTime(123456789);
      expect(recordManager.getStartTime()).assertEqual(123456789);
    });
  })

  describe('setIsMicUnavailable_test', () => {
    let micManager: MicManager = MicManager.getInstance();
    it('should_return_false_when_isMicUnavailable_is_false', 0, () => {
      micManager.setIsMicUnavailable(false);
      expect(micManager.getIsMicUnavailable()).assertEqual(false);
    });

    it('should_return_true_when_isMicUnavailable_is_true', 0, () => {
      micManager.setIsMicUnavailable(true);
      expect(micManager.getIsMicUnavailable()).assertEqual(true);
    });

    it('should_return_false_when_pcMicEnableState_is_false', 0, () => {
      micManager.setPcMicEnableState(false)
      expect(micManager.getPcMicEnableState()).assertEqual(false);
    });

    it('should_return_true_when_pcMicEnableState_is_true', 0, () => {
      micManager.setPcMicEnableState(true)
      expect(micManager.getPcMicEnableState()).assertEqual(true);
    });
  })

  describe('stop_recorder_test', () => {
    it('atc_should_return_true_and_call_stop_when_isRecording_is_true', 0, () => {
      let mocker: MockKit = new MockKit();
      let recordManager: ESObject = RecordManager.getInstance();
      recordManager.isRecording = true;
      let mockStopFunc: Function = mocker.mockFunc(recordManager, recordManager.stop);
      when(mockStopFunc)().afterReturnNothing();

      const result: ESObject = recordManager.stopRecorder();

      expect(result).assertTrue();
    });

    it('atc_should_return_false_and_not_call_stop_when_isRecording_is_false', 0, () => {
      let mocker: MockKit = new MockKit();
      let recordManager: ESObject = RecordManager.getInstance();
      recordManager.isRecording = false;
      let mockStopFunc: Function = mocker.mockFunc(recordManager, recordManager.stop);
      when(mockStopFunc)().afterReturnNothing();

      const result: ESObject = recordManager.stopRecorder();

      expect(result).assertFalse();
    });
  });
}