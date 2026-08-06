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

import { EventReportUtil, GlobalThisUtil, SetSwitchResult } from '@ohos/common';
import { DARK_NOTIFICATION_COLOR, LIGHT_NOTIFICATION_COLOR, NotificationManager } from '@ohos/screen-recorder';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { notificationManager } from '@kit.NotificationKit';
import common from '@ohos.app.ability.common';
import { afterEach, ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';

export default function NotificationManagerTest() {
  describe('handleCheckedChange_testSuite', () => {

    beforeEach(() => {

    });
    afterEach(() => {

    });

    it('handleCheckedChange_testSuite_when_is_checked_is_true', 0, async () => {
      let notificationManager: NotificationManager = NotificationManager.getInstance();
      let mocker: MockKit = new MockKit();
      let globalThisUtil: GlobalThisUtil = GlobalThisUtil.getInstance();
      let mockfunc: Function = mocker.mockFunc(globalThisUtil, globalThisUtil.getObject);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturn({} as common.ServiceExtensionContext);

      notificationManager.handleCheckedChange(true, true);
      expect(EventReportUtil.getSwitchTrackResult()).assertEqual(SetSwitchResult.RESULT_SUCCESS);
      mocker.ignoreMock(globalThisUtil, globalThisUtil.getObject);
    });

    it('handleCheckedChange_testSuite_when_is_checked_is_false', 0, async () => {
      let notificationManager: NotificationManager = NotificationManager.getInstance();
      let mocker: MockKit = new MockKit();
      let globalThisUtil: GlobalThisUtil = GlobalThisUtil.getInstance();
      let mockfunc: Function = mocker.mockFunc(globalThisUtil, globalThisUtil.getObject);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturn({} as common.ServiceExtensionContext);

      notificationManager.handleCheckedChange(true, false);
      expect(EventReportUtil.getSwitchTrackResult()).assertEqual(SetSwitchResult.RESULT_SUCCESS);
      mocker.ignoreMock(globalThisUtil, globalThisUtil.getObject);
    });

    it('handleCheckedChange_testSuite_when_is_triggered_by_user_is_true', 0, async () => {
      let notificationManager: NotificationManager = NotificationManager.getInstance();
      let mocker: MockKit = new MockKit();
      let globalThisUtil: GlobalThisUtil = GlobalThisUtil.getInstance();
      let mockfunc: Function = mocker.mockFunc(globalThisUtil, globalThisUtil.getObject);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturn({} as common.ServiceExtensionContext);

      notificationManager.handleCheckedChange(true, true);

      expect(EventReportUtil.getSwitchTrackResult()).assertEqual(SetSwitchResult.RESULT_SUCCESS);
      mocker.ignoreMock(globalThisUtil, globalThisUtil.getObject);
    });

    it('handleCheckedChange_testSuite_when_is_triggered_by_user_is_false', 0, async () => {
      let notificationManager: NotificationManager = NotificationManager.getInstance();
      let mocker: MockKit = new MockKit();
      let globalThisUtil: GlobalThisUtil = GlobalThisUtil.getInstance();
      let mockfunc: Function = mocker.mockFunc(globalThisUtil, globalThisUtil.getObject);
      when(mockfunc)(ArgumentMatchers.anyString).afterReturn({} as common.ServiceExtensionContext);

      notificationManager.handleCheckedChange(false, true);

      expect(EventReportUtil.getSwitchTrackResult()).assertEqual(SetSwitchResult.RESULT_SUCCESS);
      mocker.ignoreMock(globalThisUtil, globalThisUtil.getObject);
    });
  });

  describe('getCurrentShowTouchState_TestSuite', () => {
    it('getCurrentShowTouchState_test_check_instance', 0, () => {
      let notificationManager: NotificationManager = NotificationManager.getInstance();
      let touchState = notificationManager.getCurrentShowTouchState();
      expect(touchState).assertInstanceOf('Boolean');
    });

    it('getCurrentShowTouchState_test_check_valid_value_list', 0, () => {
      let notificationManager: NotificationManager = NotificationManager.getInstance();
      let touchState = notificationManager.getCurrentShowTouchState();
      expect([true, false]).assertContain(touchState);
    });

    it('getCurrentShowTouchState_test_return_true_when_handleCheckedChange_is_checked', 0, () => {
      let notificationManager: NotificationManager = NotificationManager.getInstance();
      notificationManager.handleCheckedChange(false, true);
      let touchState = notificationManager.getCurrentShowTouchState();
      expect(touchState).assertEqual(true);
    });

    it('getCurrentShowTouchState_test_return_false_when_handleCheckedChange_not_checked', 0, () => {
      let notificationManager: NotificationManager = NotificationManager.getInstance();
      notificationManager.handleCheckedChange(false, false);
      let touchState = notificationManager.getCurrentShowTouchState();
      expect(touchState).assertEqual(false);
    });
  });

  describe('needUpdateShowTouch_TestSuite', () => {
    it('needUpdateShowTouch_test_check_instance', 0, () => {
      let notificationManager: NotificationManager = NotificationManager.getInstance();
      let isNeedUpdate = notificationManager.needUpdateShowTouch();
      expect(isNeedUpdate).assertInstanceOf('Boolean');
    });

    it('needUpdateShowTouch_test_check_value_list', 0, () => {
      let notificationManager: NotificationManager = NotificationManager.getInstance();
      let isNeedUpdate = notificationManager.needUpdateShowTouch();
      expect([true, false]).assertContain(isNeedUpdate);
    });

    it('needUpdateShowTouch_test_return_true_when_check_value_not_equal', 0, () => {
      let notificationManager: NotificationManager = NotificationManager.getInstance();
      let isChecked: boolean = false;
      notificationManager.handleCheckedChange(false, isChecked);
      let touchState: boolean = notificationManager.getCurrentShowTouchState();
      let isNeedUpdate: boolean = notificationManager.needUpdateShowTouch();
      expect(isNeedUpdate).assertEqual(!(isChecked === touchState));
    });

    it('needUpdateShowTouch_test_return_true_when_mock_value_not_equal', 0, () => {
      let notificationManager: NotificationManager = NotificationManager.getInstance();
      let isChecked: boolean = false;
      notificationManager.handleCheckedChange(false, isChecked);

      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(notificationManager, notificationManager.getCurrentShowTouchState);
      when(mockFunc)().afterReturn(true);

      let isNeedUpdate = notificationManager.needUpdateShowTouch();
      expect(isNeedUpdate).assertTrue();
      mocker.ignoreMock(notificationManager, notificationManager.getCurrentShowTouchState);
    });

    it('needUpdateShowTouch_test_return_false_when_mock_value_equal', 0, () => {
      let notificationManager: NotificationManager = NotificationManager.getInstance();
      let isChecked: boolean = false;
      notificationManager.handleCheckedChange(false, isChecked);

      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(notificationManager, notificationManager.getCurrentShowTouchState);
      when(mockFunc)().afterReturn(false);

      let isNeedUpdate = notificationManager.needUpdateShowTouch();
      expect(isNeedUpdate).assertFalse();
      mocker.ignoreMock(notificationManager, notificationManager.getCurrentShowTouchState);
    });
  });

  describe('updateShowTouch_TestSuite', () => {
    it('updateShowTouch_test_check_call_send_notification_request_when_should_show', 0, async () => {
      let mocker: MockKit = new MockKit();
      let notificationManager: NotificationManager = NotificationManager.getInstance();
      let mockFunc: Function = mocker.mockFunc(notificationManager, notificationManager.sendNotificationRequest);
      when(mockFunc)().afterReturnNothing();

      let result = notificationManager.updateShowTouch(true);
      expect(result).assertPromiseIsResolved();
      mocker.verify('sendNotificationRequest', []).once();
      mocker.ignoreMock(notificationManager, notificationManager.sendNotificationRequest);
    });

    it('updateShowTouch_test_check_call_send_notification_request_when_should_not_show', 0, async () => {
      let mocker: MockKit = new MockKit();
      let notificationManager: NotificationManager = NotificationManager.getInstance();
      let mockFunc: Function = mocker.mockFunc(notificationManager, notificationManager.sendNotificationRequest);
      when(mockFunc)().afterReturnNothing();

      let result = notificationManager.updateShowTouch(false);
      expect(result).assertPromiseIsResolved();
      mocker.verify('sendNotificationRequest', []).once();
      mocker.ignoreMock(notificationManager, notificationManager.sendNotificationRequest);
    });
  });

  describe('getNotificationRequest_TestSuite', () => {
    const context = GlobalThisUtil.getInstance()!.getObject('screenRecorderContext') as common.UIAbilityContext;

    it('getNotificationRequest_test_check_instance', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      expect(notificationRequest).assertInstanceOf('Object');
    });

    it('getNotificationRequest_test_check_slot_type', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      expect(notificationRequest.notificationSlotType).assertEqual(notificationManager.SlotType.LIVE_VIEW);
    });

    it('getNotificationRequest_test_check_id', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      expect(notificationRequest.id).assertEqual(1000);
    });

    it('getNotificationRequest_test_check_content_type', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      expect(notificationRequest.content.notificationContentType)
        .assertEqual(notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW);
    });

    it('getNotificationRequest_test_check_live_view_title', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;
      expect(liveView?.title).assertEqual(context.resourceManager.getStringByNameSync('app_name'));
    });

    it('getNotificationRequest_test_check_live_view_text', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;
      expect(liveView?.text).assertEqual(context.resourceManager.getStringByNameSync('notification_subtitle'));
    });

    it('getNotificationRequest_test_check_live_view_type_code', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;
      expect(liveView?.typeCode).assertEqual(1);
    });

    it('getNotificationRequest_test_check_live_view_button_icons', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;
      expect(liveView?.button?.icons?.length).assertLarger(0);
    });

    it('getNotificationRequest_test_check_live_view_button_name', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;
      expect(liveView?.button?.names?.length).assertLarger(0);
    });

    it('getNotificationRequest_test_check_live_view_button_icon_name_length_equal', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;
      expect(liveView?.button?.names?.length).assertEqual(liveView?.button?.icons?.length);
    });

    it('getNotificationRequest_test_check_live_view_first_button_name', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;
      let btnNames: string[] = liveView?.button?.names as string[];
      expect(btnNames[0]).assertEqual('id_track_button');
    });

    it('getNotificationRequest_test_check_live_view_second_button_name', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;
      let btnNames: string[] = liveView?.button?.names as string[];
      expect(btnNames[1]).assertEqual('id_mic_button');
    });

    it('getNotificationRequest_test_check_live_view_third_button_name', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;
      let btnNames: string[] = liveView?.button?.names as string[];
      expect(btnNames[2]).assertEqual('id_stop_button');
    });

    it('getNotificationRequest_test_check_live_view_capsule_title', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;
      expect(liveView?.capsule?.title).not().assertUndefined();
    });

    it('getNotificationRequest_test_check_live_view_capsule_icon', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;
      expect(liveView?.capsule?.icon).not().assertUndefined();
    });

    it('getNotificationRequest_test_check_live_view_capsule_background_when_dark', 0, async () => {
      let mocker: MockKit = new MockKit();
      let globalInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
      let mockFunc: Function = mocker.mockFunc(globalInstance, globalInstance.getObject);
      when(mockFunc)('darkMode').afterReturn(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
      when(mockFunc)('screenRecorderContext').afterReturn(context);

      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;

      expect(liveView?.capsule?.backgroundColor).assertEqual(DARK_NOTIFICATION_COLOR);
      mocker.ignoreMock(globalInstance, globalInstance.getObject);
    });

    it('getNotificationRequest_test_check_live_view_capsule_background_when_light', 0, async () => {
      let mocker: MockKit = new MockKit();
      let globalInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
      let mockFunc: Function = mocker.mockFunc(globalInstance, globalInstance.getObject);
      when(mockFunc)('darkMode').afterReturn(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
      when(mockFunc)('screenRecorderContext').afterReturn(context);

      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;

      expect(liveView?.capsule?.backgroundColor).assertEqual(LIGHT_NOTIFICATION_COLOR);
      mocker.ignoreMock(globalInstance, globalInstance.getObject);
    });

    it('getNotificationRequest_test_check_live_view_capsule_background_when_not_set', 0, async () => {
      let mocker: MockKit = new MockKit();
      let globalInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
      let mockFunc: Function = mocker.mockFunc(globalInstance, globalInstance.getObject);
      when(mockFunc)('darkMode').afterReturn(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      when(mockFunc)('screenRecorderContext').afterReturn(context);

      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;

      expect(liveView?.capsule?.backgroundColor).assertEqual(LIGHT_NOTIFICATION_COLOR);
      mocker.ignoreMock(globalInstance, globalInstance.getObject);
    });

    it('getNotificationRequest_test_check_live_view_time_when_assign_time', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest(1000);
      let liveView = notificationRequest.content.systemLiveView;
      expect(liveView?.time?.initialTime).not().assertUndefined();
    });

    it('getNotificationRequest_test_check_live_view_time_when_not_assign_time', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;
      expect(liveView?.time?.initialTime).assertUndefined();
    });

    it('getNotificationRequest_test_check_live_view_time_countdown', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;
      expect(liveView?.time?.isCountDown).assertFalse();
    });

    it('getNotificationRequest_test_check_live_view_time_in_title', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;
      expect(liveView?.time?.isInTitle).assertTrue();
    });

    it('getNotificationRequest_test_check_live_view_time_pause', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let liveView = notificationRequest.content.systemLiveView;
      expect(liveView?.time?.isPaused).assertFalse();
    });

    it('getNotificationRequest_test_check_remove_allow', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      expect(notificationRequest.isRemoveAllowed).assertFalse();
    });

    it('getNotificationRequest_test_check_extraInfo_instance', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      expect(notificationRequest.extraInfo).assertInstanceOf("Object");
    });

    it('getNotificationRequest_test_check_extraInfo_button_state', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      expect(notificationRequest.extraInfo?.hw_button_state_on.length).assertLargerOrEqual(3);
    });

    it('getNotificationRequest_test_check_extraInfo_first_button_state_value_list', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let buttonState: string[] = notificationRequest.extraInfo?.hw_button_state_on;
      expect(['ON', 'OFF', '']).assertContain(buttonState[0]);
    });

    it('getNotificationRequest_test_check_extraInfo_second_button_state_value_list', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let buttonState: string[] = notificationRequest.extraInfo?.hw_button_state_on;
      expect(['ON', 'OFF', '']).assertContain(buttonState[1]);
    });

    it('getNotificationRequest_test_check_extraInfo_third_button_state_value_list', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let buttonState: string[] = notificationRequest.extraInfo?.hw_button_state_on;
      expect(['ON', 'OFF', '']).assertContain(buttonState[2]);
    });

    it('getNotificationRequest_test_check_extraInfo_button_accessibility_text', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      expect(notificationRequest.extraInfo?.hw_button_accessibility_text.length).assertLarger(0);
    });

    it('getNotificationRequest_test_check_extraInfo_button_state_accessibility_text_length_equal', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      expect(notificationRequest.extraInfo?.hw_button_state_on.length)
        .assertEqual(notificationRequest.extraInfo?.hw_button_accessibility_text.length);
    });

    it('getNotificationRequest_test_check_extraInfo_first_button_accessibility_text', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let accessibilityText: string[] = notificationRequest.extraInfo?.hw_button_accessibility_text;
      let stringList: string[] = [
        context.resourceManager.getStringByNameSync('notification_trace_accessibility_text_on'),
        context.resourceManager.getStringByNameSync('notification_trace_accessibility_text_off')];
      expect(stringList).assertContain(accessibilityText[0]);
    });

    it('getNotificationRequest_test_check_extraInfo_second_button_accessibility_text', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let accessibilityText: string[] = notificationRequest.extraInfo?.hw_button_accessibility_text;
      let stringList: string[] = [
        context.resourceManager.getStringByNameSync('notification_mic_accessibility_text_on'),
        context.resourceManager.getStringByNameSync('notification_mic_accessibility_text_on')];
      expect(stringList).assertContain(accessibilityText[1]);
    });

    it('getNotificationRequest_test_check_extraInfo_third_button_accessibility_text', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let accessibilityText: string[] = notificationRequest.extraInfo?.hw_button_accessibility_text;
      expect(accessibilityText[2]).assertEqual(context.resourceManager.getStringByNameSync('control_stop_recording'));
    });

    it('getNotificationRequest_test_check_extraInfo_hidden_when_keyguard', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      expect(notificationRequest.extraInfo?.hw_live_view_hidden_when_keyguard).assertTrue();
    });

    it('getNotificationRequest_test_check_extraInfo_initialTime_when_assign_time', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest(1000);
      let initTime: number = notificationRequest.extraInfo?.initialTime;
      expect(initTime).assertUndefined();
    });

    it('getNotificationRequest_test_check_extraInfo_initialTime_when_not_assign_time', 0, async () => {
      let nm: NotificationManager = NotificationManager.getInstance();
      let notificationRequest = await nm.getNotificationRequest();
      let initTime: number = notificationRequest.extraInfo?.initialTime;
      expect(initTime).not().assertUndefined();
    });
  });

  describe('onTrackButtonClicked_TestSuite', () => {
    it('onTrackButtonClicked_test_send_notification_request_when_is_recording', 0, () => {
      let mocker: MockKit = new MockKit();
      let globalInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
      let recordingMockFunc: Function = mocker.mockFunc(globalInstance, globalInstance.getObject);
      when(recordingMockFunc)('isRecording').afterReturn(true);

      let nm: NotificationManager = NotificationManager.getInstance();
      let sendRequestFunc: Function = mocker.mockFunc(nm, nm.sendNotificationRequest);
      when(sendRequestFunc)().afterReturnNothing();
      nm.onTrackButtonClicked();
      mocker.verify('sendNotificationRequest', []).once();

      mocker.ignoreMock(globalInstance, globalInstance.getObject);
      mocker.ignoreMock(nm, nm.sendNotificationRequest);
    });

    it('onTrackButtonClicked_test_when_is_not_recording', 0, () => {
      let mocker: MockKit = new MockKit();
      let globalInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
      let mockFunc: Function = mocker.mockFunc(globalInstance, globalInstance.getObject);
      when(mockFunc)('isRecording').afterReturn(false);

      let nm: NotificationManager = NotificationManager.getInstance();
      let sendRequestFunc: Function = mocker.mockFunc(nm, nm.sendNotificationRequest);
      when(sendRequestFunc)().afterReturnNothing();
      nm.onTrackButtonClicked();
      mocker.verify('sendNotificationRequest', []).never();

      mocker.ignoreMock(globalInstance, globalInstance.getObject);
      mocker.ignoreMock(nm, nm.sendNotificationRequest);
    });
  });

  describe('onMicButtonClicked_TestSuite', () => {
    it('onMicButtonClicked_test_call_global_set_object', 0, async () => {
      let mocker: MockKit = new MockKit();
      let globalInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
      let mockFunc: Function = mocker.mockFunc(globalInstance, globalInstance.setObject);
      when(mockFunc)(ArgumentMatchers.any).afterReturnNothing();

      let notificationManager: NotificationManager = NotificationManager.getInstance();
      await notificationManager.onMicButtonClicked();

      mocker.verify('setObject', ['isMicClicked', true]).once();
      mocker.ignoreMock(globalInstance, globalInstance.setObject);
    });
  });
}
