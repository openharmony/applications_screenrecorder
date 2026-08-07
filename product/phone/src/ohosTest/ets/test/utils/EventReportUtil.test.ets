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
  EventReportUtil,
  LogUtil,
  RuntimeError,
  SetSwitchResult,
  SetSwitchType,
  StartChoosePanelType,
  StartRecordTriggerResult,
  StartRecordTriggerType,
  StopRecordTriggerResult,
  StopRecordTriggerType,
  UNKNOWN_REASON
} from '@ohos/common';
import { describe, expect, it, MockKit, when } from '@ohos/hypium';

export function EventReportUtilTest() {
  describe('getStartType_test', () => {
    it("getStartType_test_number", 0, () => {
      let getStartType = EventReportUtil.getStartType();
      expect(getStartType).assertInstanceOf('Number');
    });

    it("getStartType_test_equal_one", 0, () => {
      let getStartType = EventReportUtil.getStartType();
      expect(getStartType).assertEqual(StartRecordTriggerType.TRIGGERED_TYPE_BY_CONTROL_CENTER);
    });

    it("getStartType_test_equal_two", 0, () => {
      EventReportUtil.setStartType(StartRecordTriggerType.TRIGGERED_TYPE_BY_SHORTCUT_KEY);
      let getStartType = EventReportUtil.getStartType();
      expect(getStartType).assertEqual(StartRecordTriggerType.TRIGGERED_TYPE_BY_SHORTCUT_KEY);
    });

    it("getStartType_test_equal_three", 0, () => {
      EventReportUtil.setStartType(StartRecordTriggerType.TRIGGERED_TYPE_BY_KNUCKLE);
      let getStartType = EventReportUtil.getStartType();
      expect(getStartType).assertEqual(StartRecordTriggerType.TRIGGERED_TYPE_BY_KNUCKLE);
    });

    it("getStartType_test_equal_four", 0, () => {
      EventReportUtil.setStartType(StartRecordTriggerType.TRIGGERED_TYPE_BY_AI);
      let getStartType = EventReportUtil.getStartType();
      expect(getStartType).assertEqual(StartRecordTriggerType.TRIGGERED_TYPE_BY_AI);
    });

    it("getStartType_test_not_equal_one", 0, () => {
      EventReportUtil.setStartType(StartRecordTriggerType.TRIGGERED_TYPE_BY_CONTROL_CENTER);
      let getStartType = EventReportUtil.getStartType();
      expect(getStartType).assertEqual(StartRecordTriggerType.TRIGGERED_TYPE_BY_CONTROL_CENTER);
    });

    it("getStartType_test_not_equal_two", 0, () => {
      EventReportUtil.setStartType(StartRecordTriggerType.TRIGGERED_TYPE_BY_KNUCKLE);
      let getStartType = EventReportUtil.getStartType();
      expect(getStartType).assertEqual(StartRecordTriggerType.TRIGGERED_TYPE_BY_KNUCKLE);
    });
  });

  describe('getStartResult_test', () => {
    it("setChoosePanelType_test_number", 0, () => {
      EventReportUtil.setChoosePanelType(StartChoosePanelType.RECORD_TYPE_BY_FULL_SCREEN);
      let getChoosePanelType = EventReportUtil.getChoosePanelType();
      expect(getChoosePanelType).assertInstanceOf('Number');
    });

    it("reportStartRecordEvent_test_number", 0, () => {
      try {
        EventReportUtil.setStartType(StartRecordTriggerType.TRIGGERED_TYPE_BY_PANEL);
        EventReportUtil.reportStartRecordEvent(100);
      }catch (e) {
        expect().assertFail();
      }
    });

    it("getStartResult_test_number", 0, () => {
      let getStartResult = EventReportUtil.getStartResult();
      expect(getStartResult).assertInstanceOf('Number');
    });

    it("getStartResult_test_equal_one", 0, () => {
      let getStartResult = EventReportUtil.getStartResult();
      expect(getStartResult).assertEqual(StartRecordTriggerResult.RESULT_SUCCESS);
    });

    it("getStartResult_test_equal_two", 0, () => {
      EventReportUtil.setStartResult(StartRecordTriggerResult.RESULT_ERROR_BY_VIDEO_SERVICE_UNAVAILABLE);
      let getStartResult = EventReportUtil.getStartResult();
      expect(getStartResult).assertEqual(StartRecordTriggerResult.RESULT_ERROR_BY_VIDEO_SERVICE_UNAVAILABLE);
    });

    it("getStartResult_test_equal_three", 0, () => {
      EventReportUtil.setStartResult(StartRecordTriggerResult.RESULT_ERROR_BY_MEDIA_LIBRARY_UNAVAILABLE);
      let getStartResult = EventReportUtil.getStartResult();
      expect(getStartResult).assertEqual(StartRecordTriggerResult.RESULT_ERROR_BY_MEDIA_LIBRARY_UNAVAILABLE);
    });

    it("getStartResult_test_equal_four", 0, () => {
      EventReportUtil.setStartResult(StartRecordTriggerResult.RESULT_ERROR_BY_INSUFFICIENT_VIDEO_SERVICE_RESOURCES);
      let getStartResult = EventReportUtil.getStartResult();
      expect(getStartResult).assertEqual(StartRecordTriggerResult.RESULT_ERROR_BY_INSUFFICIENT_VIDEO_SERVICE_RESOURCES);
    });

    it("getStartResult_test_equal_five", 0, () => {
      EventReportUtil.setStartResult(StartRecordTriggerResult.RESULT_ERROR_BY_CALLING);
      let getStartResult = EventReportUtil.getStartResult();
      expect(getStartResult).assertEqual(StartRecordTriggerResult.RESULT_ERROR_BY_CALLING);
    });

    it("getStartResult_test_equal_six", 0, () => {
      EventReportUtil.setStartResult(StartRecordTriggerResult.RESULT_ERROR_BY_LOW_STORAGE);
      let getStartResult = EventReportUtil.getStartResult();
      expect(getStartResult).assertEqual(StartRecordTriggerResult.RESULT_ERROR_BY_LOW_STORAGE);
    });

    it("getStartResult_test_equal_seven", 0, () => {
      EventReportUtil.setStartResult(StartRecordTriggerResult.RESULT_MICROPHONE_PREEMPTED);
      let getStartResult = EventReportUtil.getStartResult();
      expect(getStartResult).assertEqual(StartRecordTriggerResult.RESULT_MICROPHONE_PREEMPTED);
    });

    it("getStartFaultReason_test_equal_eight", 0, () => {
      EventReportUtil.setStartResult(StartRecordTriggerResult.RESULT_ERROR_BY_FILE_MANAGER_UNAVAILABLE);
      let getStartResult = EventReportUtil.getStartResult();
      expect(getStartResult).assertEqual(StartRecordTriggerResult.RESULT_ERROR_BY_FILE_MANAGER_UNAVAILABLE);
    });
  });

  describe('getStartFaultReason_test', () => {
    it("getStartFaultReason_test_string", 0, () => {
      let getStartFaultReason = EventReportUtil.getStartFaultReason();
      expect(getStartFaultReason).assertInstanceOf('String');
    });

    it("getStartFaultReason_test_equal_one", 0, () => {
      let getStartFaultReason = EventReportUtil.getStartFaultReason();
      expect(getStartFaultReason).assertEqual('');
    });

    it("getStartFaultReason_test_equal_two", 0, () => {
      const ERROR_MESSAGE = 'ERROR';
      EventReportUtil.setStartFaultReason(ERROR_MESSAGE);
      let getStartFaultReason = EventReportUtil.getStartFaultReason();
      expect(getStartFaultReason).assertEqual(ERROR_MESSAGE);
    });

    it("getStartFaultReason_test_equal_three", 0, () => {
      const ERROR_MESSAGE = 'ERROR';
      EventReportUtil.setStartFaultReason(ERROR_MESSAGE);
      let getStartFaultReason = EventReportUtil.getStartFaultReason();
      expect(getStartFaultReason).assertEqual('ERROR');
    });
  });

  describe('getSwitchMicType_test', () => {
    it("getSwitchMicType_test_number", 0, () => {
      let getSwitchMicType = EventReportUtil.getSwitchMicType();
      expect(getSwitchMicType).assertInstanceOf('Number');
    });

    it("getSwitchMicType_test_equal_one", 0, () => {
      EventReportUtil.setSwitchMicType(SetSwitchType.TRIGGERED_TYPE_SWITCH_ON);
      let getSwitchMicType = EventReportUtil.getSwitchMicType();
      expect(getSwitchMicType).assertEqual(SetSwitchType.TRIGGERED_TYPE_SWITCH_ON);
    });

    it("getSwitchMicType_test_equal_two", 0, () => {
      EventReportUtil.setSwitchMicType(SetSwitchType.TRIGGERED_TYPE_SWITCH_OFF);
      let getSwitchMicType = EventReportUtil.getSwitchMicType();
      expect(getSwitchMicType).assertEqual(SetSwitchType.TRIGGERED_TYPE_SWITCH_OFF);
    });

    it("getSwitchMicType_test_not_equal_one", 0, () => {
      EventReportUtil.setSwitchMicType(SetSwitchType.TRIGGERED_TYPE_SWITCH_ON);
      let getSwitchMicType = EventReportUtil.getSwitchMicType();
      expect(getSwitchMicType).assertEqual(SetSwitchType.TRIGGERED_TYPE_SWITCH_ON);
    });

    it('getSwitchMicType_test_check_valid_value_list', 0, () => {
      let switchMicType = EventReportUtil.getSwitchMicType();
      expect([SetSwitchType.TRIGGERED_TYPE_SWITCH_OFF, SetSwitchType.TRIGGERED_TYPE_SWITCH_ON])
        .assertContain(switchMicType);
    });
  });

  describe('getSwitchMicResult_test', () => {
    it("getSwitchMicResult_test_number", 0, () => {
      let switchMicResult = EventReportUtil.getSwitchMicResult();
      expect(switchMicResult).assertInstanceOf('Number');
    });

    it("getSwitchMicResult_test_equal_default_value", 0, () => {
      let switchMicResult = EventReportUtil.getSwitchMicResult();
      expect(switchMicResult).assertEqual(SetSwitchResult.RESULT_SUCCESS);
    });

    it("getSwitchMicResult_test_equal_result_failed", 0, () => {
      EventReportUtil.setSwitchMicResult(SetSwitchResult.RESULT_FAILED);
      let switchMicResult = EventReportUtil.getSwitchMicResult();
      expect(switchMicResult).assertEqual(SetSwitchResult.RESULT_FAILED);
    });

    it("getSwitchMicResult_test_equal_result_success", 0, () => {
      EventReportUtil.setSwitchMicResult(SetSwitchResult.RESULT_SUCCESS);
      let switchMicResult = EventReportUtil.getSwitchMicResult();
      expect(switchMicResult).assertEqual(SetSwitchResult.RESULT_SUCCESS);
    });

    it('getSwitchMicResult_test_check_valid_value_list', 0, () => {
      let switchMicResult = EventReportUtil.getSwitchMicResult();
      expect([SetSwitchResult.RESULT_SUCCESS, SetSwitchResult.RESULT_FAILED]).assertContain(switchMicResult);
    });
  });

  describe('getSwitchTrackType_TestSuite', () => {
    it('getSwitchTrackType_test_check_instance', 0, () => {
      let switchTrackType: number = EventReportUtil.getSwitchTrackType();
      expect(switchTrackType).assertInstanceOf("Number");
    });

    it('getSwitchTrackType_test_type_switch_off', 0, () => {
      EventReportUtil.setSwitchTrackType(SetSwitchType.TRIGGERED_TYPE_SWITCH_OFF);
      let switchTrackType: number = EventReportUtil.getSwitchTrackType();
      expect(switchTrackType).assertEqual(SetSwitchType.TRIGGERED_TYPE_SWITCH_OFF);
    });

    it('getSwitchTrackType_test_type_switch_on', 0, () => {
      EventReportUtil.setSwitchTrackType(SetSwitchType.TRIGGERED_TYPE_SWITCH_ON);
      let switchTrackType: number = EventReportUtil.getSwitchTrackType();
      expect(switchTrackType).assertEqual(SetSwitchType.TRIGGERED_TYPE_SWITCH_ON);
    });

    it('getSwitchTrackType_test_check_valid_value_list', 0, () => {
      let switchTrackType: number = EventReportUtil.getSwitchTrackType();
      expect([SetSwitchType.TRIGGERED_TYPE_SWITCH_ON, SetSwitchType.TRIGGERED_TYPE_SWITCH_OFF])
        .assertContain(switchTrackType);
    });
  });

  describe('getSwitchTrackResult_TestSuite', () => {
    it('getSwitchTrackResult_test_check_instance', 0, () => {
      let switchTrackResult: number = EventReportUtil.getSwitchTrackResult();
      expect(switchTrackResult).assertInstanceOf("Number");
    });

    it('getSwitchTrackResult_test_check_default_value', 0, () => {
      let switchTrackResult: number = EventReportUtil.getSwitchTrackResult();
      expect(switchTrackResult).assertEqual(SetSwitchResult.RESULT_SUCCESS);
    });

    it('getSwitchTrackResult_test_check_assigned_value', 0, () => {
      EventReportUtil.setSwitchTrackResult(SetSwitchResult.RESULT_FAILED);
      let switchTrackResult: number = EventReportUtil.getSwitchTrackResult();
      expect(switchTrackResult).assertEqual(SetSwitchResult.RESULT_FAILED);
    });

    it('getSwitchTrackResult_test_check_valid_value_list', 0, () => {
      let switchTrackResult: number = EventReportUtil.getSwitchTrackResult();
      expect([SetSwitchResult.RESULT_FAILED, SetSwitchResult.RESULT_SUCCESS]).assertContain(switchTrackResult);
    });
  });

  describe('getStopType_TestSuite', () => {
    it('getStopType_test_check_instance', 0, () => {
      let stopType: number = EventReportUtil.getStopType();
      expect(stopType).assertInstanceOf("Number");
    });

    it('getStopType_test_check_type_stop_button', 0, () => {
      EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_STOP_BUTTON);
      let stopType: number = EventReportUtil.getStopType();
      expect(stopType).assertEqual(StopRecordTriggerType.TRIGGERED_TYPE_BY_STOP_BUTTON);
    });

    it('getStopType_test_check_type_cellular_call', 0, () => {
      EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_CELLULAR_CALL);
      let stopType: number = EventReportUtil.getStopType();
      expect(stopType).assertEqual(StopRecordTriggerType.TRIGGERED_TYPE_BY_CELLULAR_CALL);
    });

    it('getStopType_test_check_type_other_recording', 0, () => {
      EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_OTHER_RECORDING);
      let stopType: number = EventReportUtil.getStopType();
      expect(stopType).assertEqual(StopRecordTriggerType.TRIGGERED_TYPE_BY_OTHER_RECORDING);
    });

    it('getStopType_test_check_type_low_storage', 0, () => {
      EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_LOW_STORAGE);
      let stopType: number = EventReportUtil.getStopType();
      expect(stopType).assertEqual(StopRecordTriggerType.TRIGGERED_TYPE_BY_LOW_STORAGE);
    });

    it('getStopType_test_check_type_screen_off', 0, () => {
      EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_SCREEN_OFF);
      let stopType: number = EventReportUtil.getStopType();
      expect(stopType).assertEqual(StopRecordTriggerType.TRIGGERED_TYPE_BY_SCREEN_OFF);
    });

    it('getStopType_test_check_type_control_center', 0, () => {
      EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_CONTROL_CENTER);
      let stopType: number = EventReportUtil.getStopType();
      expect(stopType).assertEqual(StopRecordTriggerType.TRIGGERED_TYPE_BY_CONTROL_CENTER);
    });

    it('getStopType_test_check_type_knuckle', 0, () => {
      EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_KNUCKLE);
      let stopType: number = EventReportUtil.getStopType();
      expect(stopType).assertEqual(StopRecordTriggerType.TRIGGERED_TYPE_BY_KNUCKLE);
    });

    it('getStopType_test_check_type_hot_key', 0, () => {
      EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_HOT_KEY);
      let stopType: number = EventReportUtil.getStopType();
      expect(stopType).assertEqual(StopRecordTriggerType.TRIGGERED_TYPE_BY_HOT_KEY);
    });

    it('getStopType_test_check_type_file_change', 0, () => {
      EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_FILE_CHANGED);
      let stopType: number = EventReportUtil.getStopType();
      expect(stopType).assertEqual(StopRecordTriggerType.TRIGGERED_TYPE_BY_FILE_CHANGED);
    });
  });

  describe('getStopResult_TestSuite', () => {
    it('getStopResult_test_check_instance', 0, () => {
      let stopResult = EventReportUtil.getStopResult();
      expect(stopResult).assertInstanceOf("Number");
    });

    it('getStopResult_test_check_result_success', 0, () => {
      EventReportUtil.setStopResult(StopRecordTriggerResult.RESULT_SUCCESS);
      let stopResult = EventReportUtil.getStopResult();
      expect(stopResult).assertEqual(StopRecordTriggerResult.RESULT_SUCCESS);
    });

    it('getStopResult_test_check_result_fail_when_server_fault', 0, () => {
      EventReportUtil.setStopResult(StopRecordTriggerResult.RESULT_ERROR_BY_RECORDING_SERVICE_FAULT);
      let stopResult = EventReportUtil.getStopResult();
      expect(stopResult).assertEqual(StopRecordTriggerResult.RESULT_ERROR_BY_RECORDING_SERVICE_FAULT);
    });

    it('getStopResult_test_check_result_fail_when_save_error', 0, () => {
      EventReportUtil.setStopResult(StopRecordTriggerResult.RESULT_ERROR_BY_VIDEO_SAVING_EXCEPTION);
      let stopResult = EventReportUtil.getStopResult();
      expect(stopResult).assertEqual(StopRecordTriggerResult.RESULT_ERROR_BY_VIDEO_SAVING_EXCEPTION);
    });

    it('getStopResult_test_check_result_fail_when_thumbnail_exception', 0, () => {
      EventReportUtil.setStopResult(StopRecordTriggerResult.RESULT_ERROR_BY_THUMBNAIL_EXCEPTION);
      let stopResult = EventReportUtil.getStopResult();
      expect(stopResult).assertEqual(StopRecordTriggerResult.RESULT_ERROR_BY_THUMBNAIL_EXCEPTION);
    });
  });

  describe('getStopFaultReason_TestSuite', () => {
    it('getStopFaultReason_test_check_instance', 0, () => {
      let stopFaultReason = EventReportUtil.getStopFaultReason();
      expect(stopFaultReason).assertInstanceOf("String");
    });

    it('getStopFaultReason_test_check_result_when_set_nothing', 0, () => {
      EventReportUtil.setStopFaultReason();
      let stopFaultReason = EventReportUtil.getStopFaultReason();
      expect(stopFaultReason).assertEqual('');
    });

    it('getStopFaultReason_test_check_result_when_set_string', 0, () => {
      let errorMsg: string = 'error message';
      EventReportUtil.setStopFaultReason(errorMsg);
      let stopFaultReason = EventReportUtil.getStopFaultReason();
      expect(stopFaultReason).assertEqual(errorMsg);
    });
  });

  describe('getErrorReason_TestSuite', () => {
    it('getErrorReason_test_check_instance', 0, () => {
      let errorReason = EventReportUtil.getErrorReason();
      expect(errorReason).assertInstanceOf("Number");
    });

    it('getErrorReason_test_check_result_when_server_fault', 0, () => {
      EventReportUtil.setErrorReason(RuntimeError.ERROR_REASON_RECORDING_SERVICE_FAULT);
      let errorReason = EventReportUtil.getErrorReason();
      expect(errorReason).assertEqual(RuntimeError.ERROR_REASON_RECORDING_SERVICE_FAULT);
    });

    it('getErrorReason_test_check_result_unkown', 0, () => {
      EventReportUtil.setErrorReason(UNKNOWN_REASON);
      let errorReason = EventReportUtil.getErrorReason();
      expect(errorReason).assertEqual(UNKNOWN_REASON);
    });
  });

  describe('getTriggerTypeCodeByReason_test', () => {
    it("getTriggerTypeCodeByReason_test_number", 0, () => {
      let getTriggerTypeCodeByReason = EventReportUtil.getTriggerTypeCodeByReason('');
      expect(getTriggerTypeCodeByReason).assertInstanceOf('Number');
    });

    it("getTriggerTypeCodeByReason_test_equal_one", 0, () => {
      const REASON = 'hot-key';
      let getTriggerTypeCodeByReason = EventReportUtil.getTriggerTypeCodeByReason(REASON);
      expect(getTriggerTypeCodeByReason).assertEqual(StartRecordTriggerType.TRIGGERED_TYPE_BY_SHORTCUT_KEY);
    });

    it("getTriggerTypeCodeByReason_test_equal_two", 0, () => {
      const REASON = 'knuckle';
      let getTriggerTypeCodeByReason = EventReportUtil.getTriggerTypeCodeByReason(REASON);
      expect(getTriggerTypeCodeByReason).assertEqual(StartRecordTriggerType.TRIGGERED_TYPE_BY_KNUCKLE);
    });

    it("getTriggerTypeCodeByReason_test_equal_three", 0, () => {
      const REASON = 'default_trigger_type';
      let getTriggerTypeCodeByReason = EventReportUtil.getTriggerTypeCodeByReason(REASON);
      expect(getTriggerTypeCodeByReason).assertEqual(StartRecordTriggerType.TRIGGERED_TYPE_BY_CONTROL_CENTER);
    });

    it("getTriggerTypeCodeByReason_test_not_equal_one", 0, () => {
      const REASON = 'hot-key';
      let getTriggerTypeCodeByReason = EventReportUtil.getTriggerTypeCodeByReason(REASON);
      expect(getTriggerTypeCodeByReason).assertEqual(StartRecordTriggerType.TRIGGERED_TYPE_BY_SHORTCUT_KEY);
    });

    it("getTriggerTypeCodeByReason_test_not_equal_two", 0, () => {
      const REASON = 'default_trigger_type';
      let getTriggerTypeCodeByReason = EventReportUtil.getTriggerTypeCodeByReason(REASON);
      expect(getTriggerTypeCodeByReason).assertEqual(StartRecordTriggerType.TRIGGERED_TYPE_BY_CONTROL_CENTER);
    });
  });

  describe('writeSysEvent_test', () => {
    it("writeSysEvent_test_error", 0, () => {
      let mocker: MockKit = new MockKit();
      EventReportUtil.reportStartRecordEvent(-1);
      EventReportUtil.reportStopRecordEvent(-1);
      let mockFunc: Function = mocker.mockFunc(LogUtil, LogUtil.info);
      when(mockFunc)().afterThrow('error');
      let result = EventReportUtil.writeOldStopEvent(1, 1, {});
      expect(result).assertPromiseIsResolved();
    });
  });
}