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

import { CommonUtil, FoldPhoneTypeValue, GlobalThisUtil } from '@ohos/common';
import { CommonEventUtil } from '@ohos/common/src/main/ets/util/CommonEventUtil';
import { EVENT_NAME } from '@ohos/common/src/main/ets/util/types';
import { WindowManager } from '@ohos/screen-recorder';
import { media } from '@kit.MediaKit';
import { Driver } from '@kit.TestKit';
import { ArgumentMatchers, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { controlCenterScreenRecord } from '../common';
import { COMMON_DELAY } from '../types';

export function CommonUtilTest() {
  describe('CommonUtil_Devices_Check_Test', () => {
    it("checkIfDeviceIsPhone_test_boolean", 0, () => {
      let checkIfDeviceIsPhone = CommonUtil.checkIfDeviceIsPhone();
      expect(checkIfDeviceIsPhone).assertInstanceOf("Boolean");
    });

    it('checkIfDeviceIsPhone_test_check_valid_value_list', 0, () => {
      let isPhone = CommonUtil.checkIfDeviceIsPhone();
      expect([true, false]).assertContain(isPhone);
    });

    it("checkNeedNotification_test_boolean", 0, () => {
      let checkNeedNotification = CommonUtil.checkNeedNotification();
      expect(checkNeedNotification).assertInstanceOf("Boolean");
    });

    it("checkNeedNotification_test_check_valid_value_list", 0, () => {
      let isNeedNotification = CommonUtil.checkNeedNotification();
      expect([true, false]).assertContain(isNeedNotification);
    });

    it("checkIfDeviceIsPC_test_boolean", 0, () => {
      let checkIfDeviceIsPC = CommonUtil.checkIfDeviceIsPC();
      expect(checkIfDeviceIsPC).assertInstanceOf("Boolean");
    });

    it("checkIfDeviceIsPC_test_check_valid_value_list", 0, () => {
      let isDeviceIsPC = CommonUtil.checkIfDeviceIsPC();
      expect([true, false]).assertContain(isDeviceIsPC);
    });

    it("checkIfDeviceIsTablet_test_boolean", 0, () => {
      let checkIfDeviceIsTablet = CommonUtil.checkIfDeviceIsTablet();
      expect(checkIfDeviceIsTablet).assertInstanceOf("Boolean");
    });

    it("checkIfDeviceIsTablet_test_check_valid_value_list", 0, () => {
      let isDeviceIsTablet = CommonUtil.checkIfDeviceIsTablet();
      expect([true, false]).assertContain(isDeviceIsTablet);
    });

    it("isDeviceFolded_test_boolean", 0, () => {
      let isFoldedDevice = CommonUtil.isFoldedDevice();
      expect(isFoldedDevice).assertInstanceOf("Boolean");
    });

    it("isDeviceFolded_test_check_valid_value_list", 0, () => {
      let isFoldedDevice = CommonUtil.isFoldedDevice();
      expect([true, false]).assertContain(isFoldedDevice);
    });

    it("isDeviceExpanded_test_boolean", 0, () => {
      let isExpandedDevice = CommonUtil.isExpandedDevice();
      expect(isExpandedDevice).assertInstanceOf("Boolean");
    });

    it("isDeviceExpanded_test_check_valid_value_list", 0, () => {
      let isExpandedDevice = CommonUtil.isExpandedDevice();
      expect([true, false]).assertContain(isExpandedDevice);
    });

    it("isDeviceFoldable_test_boolean", 0, () => {
      let isFoldableDevice = CommonUtil.isFoldableDevice();
      expect(isFoldableDevice).assertInstanceOf("Boolean");
    });

    it("isDeviceFoldable_test_check_valid_value_list", 0, () => {
      let isFoldableDevice = CommonUtil.isFoldableDevice();
      expect([true, false]).assertContain(isFoldableDevice);
    });

    it("checkOobeState_test_boolean", 0, () => {
      let checkOobeState = CommonUtil.checkOobeState();
      expect(checkOobeState).assertInstanceOf("Boolean");
    });

    it("checkOobeState_test_check_valid_value_list", 0, () => {
      let isOobeState = CommonUtil.checkOobeState();
      expect([true, false]).assertContain(isOobeState);
    });

    it("isSingleDisplayPocketFoldDevice_test_boolean", 0, () => {
      let isSingleDisplayPocketFoldDevice = CommonUtil.isSingleDisplayPocketFoldDevice();
      expect(isSingleDisplayPocketFoldDevice).assertInstanceOf("Boolean");
    });

    it("isSingleDisplayPocketFoldDevice_test_check_valid_value_list", 0, () => {
      let isSingleDisplayPocketFoldDevice = CommonUtil.isSingleDisplayPocketFoldDevice();
      expect([true, false]).assertContain(isSingleDisplayPocketFoldDevice);
    });

    it("isLargeInFoldProduct_test_boolean", 0, () => {
      let isLargeInFoldProduct = CommonUtil.isLargeInFoldProduct();
      expect(isLargeInFoldProduct).assertInstanceOf("Boolean");
    });

    it("isLargeInFoldProduct_test_check_valid_value_list", 0, () => {
      let isLargeInFoldProduct = CommonUtil.isLargeInFoldProduct();
      expect([true, false]).assertContain(isLargeInFoldProduct);
    });
  });

  describe('IsNewExpandingFormsExternalDisplay_test', () => {
    it("IsNewExpandingFormsExternalDisplay_test_true_one", 0, () => {
      let mocker: MockKit = new MockKit();
      let deviceMockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      when(deviceMockFunc)().afterReturn(true);
      let isFoldedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldedDevice);
      when(isFoldedDeviceFunc)().afterReturn(true);

      let IsNewExpandingFormsExternalDisplay = CommonUtil.IsNewExpandingFormsExternalDisplay();
      expect(IsNewExpandingFormsExternalDisplay).assertEqual(true);
      mocker.ignoreMock(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
    });

    it("IsNewExpandingFormsExternalDisplay_test_false_one", 0, () => {
      let mocker: MockKit = new MockKit();
      let deviceMockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      when(deviceMockFunc)().afterReturn(false);
      let isFoldedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldedDevice);
      when(isFoldedDeviceFunc)().afterReturn(true);

      let IsNewExpandingFormsExternalDisplay = CommonUtil.IsNewExpandingFormsExternalDisplay();
      expect(IsNewExpandingFormsExternalDisplay).assertEqual(false);
      mocker.ignoreMock(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
    });

    it("IsNewExpandingFormsExternalDisplay_test_false_two", 0, () => {
      let mocker: MockKit = new MockKit();
      let deviceMockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      when(deviceMockFunc)().afterReturn(false);
      let isFoldedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldedDevice);
      when(isFoldedDeviceFunc)().afterReturn(false);

      let IsNewExpandingFormsExternalDisplay = CommonUtil.IsNewExpandingFormsExternalDisplay();
      expect(IsNewExpandingFormsExternalDisplay).assertEqual(false);
      mocker.ignoreMock(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
    });

    it("IsNewExpandingFormsExternalDisplay_test_false_three", 0, () => {
      let mocker: MockKit = new MockKit();
      let deviceMockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      when(deviceMockFunc)().afterReturn(true);
      let isFoldedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldedDevice);
      when(isFoldedDeviceFunc)().afterReturn(false);

      let IsNewExpandingFormsExternalDisplay = CommonUtil.IsNewExpandingFormsExternalDisplay();
      expect(IsNewExpandingFormsExternalDisplay).assertEqual(false);
      mocker.ignoreMock(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
    });

    it("IsNewExpandingFormsExternalDisplay_error_one", 0, () => {
      let mocker: MockKit = new MockKit();
      let deviceMockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      when(deviceMockFunc)().afterThrow('error');

      let IsNewExpandingFormsExternalDisplay = CommonUtil.IsNewExpandingFormsExternalDisplay();
      expect(IsNewExpandingFormsExternalDisplay).assertEqual(false);
      mocker.ignoreMock(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
    });

    it("IsNewExpandingFormsExternalDisplay_error_two", 0, () => {
      let mocker: MockKit = new MockKit();
      let deviceMockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      when(deviceMockFunc)().afterReturn(true);
      let isFoldedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldedDevice);
      when(isFoldedDeviceFunc)().afterAction('error');

      let IsNewExpandingFormsExternalDisplay = CommonUtil.IsNewExpandingFormsExternalDisplay();
      expect(IsNewExpandingFormsExternalDisplay).assertEqual(false);
      mocker.ignoreMock(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
    });
  });

  describe('checkIfDeviceNeedAvoidPot_test', () => {
    it("checkIfDeviceNeedAvoidPot_test_true_one", 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPhone);
      when(mockFunc)().afterReturn(true);

      let isFoldableDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldableDevice);
      when(isFoldableDeviceFunc)().afterReturn(false);

      let checkIfDeviceNeedAvoidPot = CommonUtil.checkIfDeviceNeedAvoidPot();
      expect(checkIfDeviceNeedAvoidPot).assertEqual(true);
    });

    it("checkIfDeviceNeedAvoidPot_test_true_two", 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPhone);
      when(mockFunc)().afterReturn(true);

      let isFoldableDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldableDevice);
      when(isFoldableDeviceFunc)().afterReturn(true);
      let isLargeInFoldProductFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isLargeInFoldProduct);
      when(isLargeInFoldProductFunc)().afterReturn(true);
      let isFoldedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldedDevice);
      when(isFoldedDeviceFunc)().afterReturn(true);

      let checkIfDeviceNeedAvoidPot = CommonUtil.checkIfDeviceNeedAvoidPot();
      expect(checkIfDeviceNeedAvoidPot).assertEqual(true);
      mocker.ignoreMock(CommonUtil, CommonUtil.isLargeInFoldProduct);
    });

    it("checkIfDeviceNeedAvoidPot_test_true_three", 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPhone);
      when(mockFunc)().afterReturn(true);

      let isFoldableDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldableDevice);
      when(isFoldableDeviceFunc)().afterReturn(true);

      let isLargeInFoldProductFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isLargeInFoldProduct);
      when(isLargeInFoldProductFunc)().afterReturn(false);
      let isFoldedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldedDevice);
      when(isFoldedDeviceFunc)().afterReturn(true);

      let isSingleDisplayPocketFoldDeviceFunc: Function =
        mocker.mockFunc(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      when(isSingleDisplayPocketFoldDeviceFunc)().afterReturn(true);
      let isExpandedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isExpandedDevice);
      when(isExpandedDeviceFunc)().afterReturn(true);

      let checkIfDeviceNeedAvoidPot = CommonUtil.checkIfDeviceNeedAvoidPot();
      expect(checkIfDeviceNeedAvoidPot).assertEqual(true);
      mocker.ignoreMock(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      mocker.ignoreMock(CommonUtil, CommonUtil.isLargeInFoldProduct);
    });

    it("checkIfDeviceNeedAvoidPot_test_true_four", 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPhone);
      when(mockFunc)().afterReturn(true);

      let isFoldableDevice: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldableDevice);
      when(isFoldableDevice)().afterReturn(true);

      let isLargeInFoldProductFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isLargeInFoldProduct);
      when(isLargeInFoldProductFunc)().afterReturn(true);
      let isFoldedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldedDevice);
      when(isFoldedDeviceFunc)().afterReturn(false);

      let isSingleDisplayPocketFoldDeviceFunc: Function =
        mocker.mockFunc(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      when(isSingleDisplayPocketFoldDeviceFunc)().afterReturn(true);
      let isExpandedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isExpandedDevice);
      when(isExpandedDeviceFunc)().afterReturn(true);

      let checkIfDeviceNeedAvoidPot = CommonUtil.checkIfDeviceNeedAvoidPot();
      expect(checkIfDeviceNeedAvoidPot).assertEqual(true);
      mocker.ignoreMock(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      mocker.ignoreMock(CommonUtil, CommonUtil.isLargeInFoldProduct);
    });

    it("checkIfDeviceNeedAvoidPot_test_true_five", 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPhone);
      when(mockFunc)().afterReturn(true);

      let isFoldableDevice: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldableDevice);
      when(isFoldableDevice)().afterReturn(true);

      let isLargeInFoldProductFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isLargeInFoldProduct);
      when(isLargeInFoldProductFunc)().afterReturn(false);
      let isFoldedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldedDevice);
      when(isFoldedDeviceFunc)().afterReturn(false);

      let isSingleDisplayPocketFoldDeviceFunc: Function =
        mocker.mockFunc(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      when(isSingleDisplayPocketFoldDeviceFunc)().afterReturn(true);
      let isExpandedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isExpandedDevice);
      when(isExpandedDeviceFunc)().afterReturn(true);

      let checkIfDeviceNeedAvoidPot = CommonUtil.checkIfDeviceNeedAvoidPot();
      expect(checkIfDeviceNeedAvoidPot).assertEqual(true);
      mocker.ignoreMock(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      mocker.ignoreMock(CommonUtil, CommonUtil.isLargeInFoldProduct);
    });

    it("checkIfDeviceNeedAvoidPot_test_false_one", 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPhone);
      when(mockFunc)().afterReturn(false);

      let checkIfDeviceNeedAvoidPot = CommonUtil.checkIfDeviceNeedAvoidPot();
      expect(checkIfDeviceNeedAvoidPot).assertEqual(false);
    });

    it("checkIfDeviceNeedAvoidPot_test_false_two", 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPhone);
      when(mockFunc)().afterReturn(false);

      let isFoldableDevice: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldableDevice);
      when(isFoldableDevice)().afterReturn(true);

      let isLargeInFoldProductFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isLargeInFoldProduct);
      when(isLargeInFoldProductFunc)().afterReturn(false);
      let isFoldedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldedDevice);
      when(isFoldedDeviceFunc)().afterReturn(true);

      let isSingleDisplayPocketFoldDeviceFunc: Function =
        mocker.mockFunc(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      when(isSingleDisplayPocketFoldDeviceFunc)().afterReturn(false);
      let isExpandedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isExpandedDevice);
      when(isExpandedDeviceFunc)().afterReturn(true);

      let checkIfDeviceNeedAvoidPot = CommonUtil.checkIfDeviceNeedAvoidPot();
      expect(checkIfDeviceNeedAvoidPot).assertEqual(false);
      mocker.ignoreMock(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      mocker.ignoreMock(CommonUtil, CommonUtil.isLargeInFoldProduct);
    });

    it("checkIfDeviceNeedAvoidPot_test_false_three", 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPhone);
      when(mockFunc)().afterReturn(false);

      let isFoldableDevice: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldableDevice);
      when(isFoldableDevice)().afterReturn(true);

      let isLargeInFoldProductFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isLargeInFoldProduct);
      when(isLargeInFoldProductFunc)().afterReturn(true);
      let isFoldedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldedDevice);
      when(isFoldedDeviceFunc)().afterReturn(false);

      let isSingleDisplayPocketFoldDeviceFunc: Function =
        mocker.mockFunc(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      when(isSingleDisplayPocketFoldDeviceFunc)().afterReturn(false);
      let isExpandedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isExpandedDevice);
      when(isExpandedDeviceFunc)().afterReturn(false);

      let checkIfDeviceNeedAvoidPot = CommonUtil.checkIfDeviceNeedAvoidPot();
      expect(checkIfDeviceNeedAvoidPot).assertEqual(false);
      mocker.ignoreMock(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      mocker.ignoreMock(CommonUtil, CommonUtil.isLargeInFoldProduct);
    });

    it("checkIfDeviceNeedAvoidPot_test_false_four", 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPhone);
      when(mockFunc)().afterReturn(false);

      let isFoldableDevice: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldableDevice);
      when(isFoldableDevice)().afterReturn(true);

      let isLargeInFoldProductFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isLargeInFoldProduct);
      when(isLargeInFoldProductFunc)().afterReturn(false);
      let isFoldedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldedDevice);
      when(isFoldedDeviceFunc)().afterReturn(false);

      let isSingleDisplayPocketFoldDeviceFunc: Function =
        mocker.mockFunc(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      when(isSingleDisplayPocketFoldDeviceFunc)().afterReturn(false);
      let isExpandedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isExpandedDevice);
      when(isExpandedDeviceFunc)().afterReturn(false);

      let checkIfDeviceNeedAvoidPot = CommonUtil.checkIfDeviceNeedAvoidPot();
      expect(checkIfDeviceNeedAvoidPot).assertEqual(false);
      mocker.ignoreMock(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      mocker.ignoreMock(CommonUtil, CommonUtil.isLargeInFoldProduct);
    });

    it("checkIfDeviceNeedAvoidPot_test_error_one", 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPhone);
      when(mockFunc)().afterThrow('error');

      let checkIfDeviceNeedAvoidPot = CommonUtil.checkIfDeviceNeedAvoidPot();
      expect(checkIfDeviceNeedAvoidPot).assertEqual(false);
    });

    it("checkIfDeviceNeedAvoidPot_test_error_two", 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPhone);
      when(mockFunc)().afterReturn(true);

      let isFoldableDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldableDevice);
      when(isFoldableDeviceFunc)().afterThrow('error');

      let checkIfDeviceNeedAvoidPot = CommonUtil.checkIfDeviceNeedAvoidPot();
      expect(checkIfDeviceNeedAvoidPot).assertEqual(false);
    });

    it("checkIfDeviceNeedAvoidPot_test_error_three", 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPhone);
      when(mockFunc)().afterReturn(true);

      let isFoldableDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldableDevice);
      when(isFoldableDeviceFunc)().afterReturn(true);

      let isLargeInFoldProductFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isLargeInFoldProduct);
      when(isLargeInFoldProductFunc)().afterThrow('error');

      let checkIfDeviceNeedAvoidPot = CommonUtil.checkIfDeviceNeedAvoidPot();
      expect(checkIfDeviceNeedAvoidPot).assertEqual(false);
      mocker.ignoreMock(CommonUtil, CommonUtil.isLargeInFoldProduct);
    });

    it("checkIfDeviceNeedAvoidPot_test_error_four", 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPhone);
      when(mockFunc)().afterReturn(true);

      let isFoldableDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldableDevice);
      when(isFoldableDeviceFunc)().afterReturn(true);

      let isLargeInFoldProductFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isLargeInFoldProduct);
      when(isLargeInFoldProductFunc)().afterReturn(false);

      let isFoldedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldedDevice);
      when(isFoldedDeviceFunc)().afterReturn(false);

      let isSingleDisplayPocketFoldDeviceFunc: Function =
        mocker.mockFunc(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      when(isSingleDisplayPocketFoldDeviceFunc)().afterThrow('error');

      let checkIfDeviceNeedAvoidPot = CommonUtil.checkIfDeviceNeedAvoidPot();
      expect(checkIfDeviceNeedAvoidPot).assertEqual(false);
      mocker.ignoreMock(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      mocker.ignoreMock(CommonUtil, CommonUtil.isLargeInFoldProduct);
    });

    it("checkIfDeviceNeedAvoidPot_test_error_five", 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPhone);
      when(mockFunc)().afterReturn(true);

      let isFoldableDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldableDevice);
      when(isFoldableDeviceFunc)().afterReturn(true);

      let isLargeInFoldProductFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isLargeInFoldProduct);
      when(isLargeInFoldProductFunc)().afterReturn(true);

      let isFoldedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldedDevice);
      when(isFoldedDeviceFunc)().afterReturn(false);

      let isSingleDisplayPocketFoldDeviceFunc: Function =
        mocker.mockFunc(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      when(isSingleDisplayPocketFoldDeviceFunc)().afterReturn(true);

      let isExpandedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isExpandedDevice);
      when(isExpandedDeviceFunc)().afterThrow('error');

      let checkIfDeviceNeedAvoidPot = CommonUtil.checkIfDeviceNeedAvoidPot();
      expect(checkIfDeviceNeedAvoidPot).assertEqual(false);
      mocker.ignoreMock(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      mocker.ignoreMock(CommonUtil, CommonUtil.isLargeInFoldProduct);
    });

    it("checkIfDeviceNeedAvoidPot_test_error_six", 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.checkIfDeviceIsPhone);
      when(mockFunc)().afterReturn(true);

      let isFoldableDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldableDevice);
      when(isFoldableDeviceFunc)().afterReturn(true);

      let isLargeInFoldProductFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isLargeInFoldProduct);
      when(isLargeInFoldProductFunc)().afterReturn(true);

      let isFoldedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isFoldedDevice);
      when(isFoldedDeviceFunc)().afterReturn(false);

      let isSingleDisplayPocketFoldDeviceFunc: Function =
        mocker.mockFunc(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      when(isSingleDisplayPocketFoldDeviceFunc)().afterThrow('error');

      let isExpandedDeviceFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.isExpandedDevice);
      when(isExpandedDeviceFunc)().afterThrow('error');

      let checkIfDeviceNeedAvoidPot = CommonUtil.checkIfDeviceNeedAvoidPot();
      expect(checkIfDeviceNeedAvoidPot).assertEqual(false);
      mocker.ignoreMock(CommonUtil, CommonUtil.isSingleDisplayPocketFoldDevice);
      mocker.ignoreMock(CommonUtil, CommonUtil.isLargeInFoldProduct);
    });
  });

  describe('isSingleDisplayPocketFoldDevice_TestSuite', () => {
    it('isSingleDisplayPocketFoldDevice_test_return_false_when_invalid', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.getFoldProductType);
      when(mockFunc)().afterReturn(-1);
      expect(CommonUtil.isSingleDisplayPocketFoldDevice()).assertFalse();
      mocker.ignoreMock(CommonUtil, CommonUtil.getFoldProductType);
    });

    it('isSingleDisplayPocketFoldDevice_test_return_false_when_fold_straight', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.getFoldProductType);
      when(mockFunc)().afterReturn(0);
      expect(CommonUtil.isSingleDisplayPocketFoldDevice()).assertFalse();
      mocker.ignoreMock(CommonUtil, CommonUtil.getFoldProductType);
    });

    it('isSingleDisplayPocketFoldDevice_test_return_false_when_large_fold', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.getFoldProductType);
      when(mockFunc)().afterReturn(1);
      expect(CommonUtil.isSingleDisplayPocketFoldDevice()).assertFalse();
      mocker.ignoreMock(CommonUtil, CommonUtil.getFoldProductType);
    });

    it('isSingleDisplayPocketFoldDevice_test_return_false_when_small_fold', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.getFoldProductType);
      when(mockFunc)().afterReturn(2);
      expect(CommonUtil.isSingleDisplayPocketFoldDevice()).assertFalse();
      mocker.ignoreMock(CommonUtil, CommonUtil.getFoldProductType);
    });

    it('isSingleDisplayPocketFoldDevice_test_return_false_when_extern_fold', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.getFoldProductType);
      when(mockFunc)().afterReturn(3);
      expect(CommonUtil.isSingleDisplayPocketFoldDevice()).assertFalse();
      mocker.ignoreMock(CommonUtil, CommonUtil.getFoldProductType);
    });

    it('isSingleDisplayPocketFoldDevice_test_return_true_when_fold_expanding_nex_forms', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.getFoldProductType);
      when(mockFunc)().afterReturn(4);
      expect(CommonUtil.isSingleDisplayPocketFoldDevice()).assertTrue();
      mocker.ignoreMock(CommonUtil, CommonUtil.getFoldProductType);
    })
  });

  describe('isLargeInFoldProduct_TestSuite', () => {
    it('isLargeInFoldProduct_test_return_false_when_invalid', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.getFoldProductType);
      when(mockFunc)().afterReturn(-1);
      expect(CommonUtil.isLargeInFoldProduct()).assertFalse();
      mocker.ignoreMock(CommonUtil, CommonUtil.getFoldProductType);
    });

    it('isLargeInFoldProduct_test_return_false_when_fold_straight', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.getFoldProductType);
      when(mockFunc)().afterReturn(0);
      expect(CommonUtil.isLargeInFoldProduct()).assertFalse();
      mocker.ignoreMock(CommonUtil, CommonUtil.getFoldProductType);
    });

    it('isLargeInFoldProduct_test_return_true_when_large_fold', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.getFoldProductType);
      when(mockFunc)().afterReturn(1);
      expect(CommonUtil.isLargeInFoldProduct()).assertTrue();
      mocker.ignoreMock(CommonUtil, CommonUtil.getFoldProductType);
    });

    it('isLargeInFoldProduct_test_return_false_when_small_fold', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.getFoldProductType);
      when(mockFunc)().afterReturn(2);
      expect(CommonUtil.isLargeInFoldProduct()).assertFalse();
      mocker.ignoreMock(CommonUtil, CommonUtil.getFoldProductType);
    });

    it('isLargeInFoldProduct_test_return_false_when_extern_fold', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.getFoldProductType);
      when(mockFunc)().afterReturn(3);
      expect(CommonUtil.isLargeInFoldProduct()).assertFalse();
      mocker.ignoreMock(CommonUtil, CommonUtil.getFoldProductType);
    });

    it('isLargeInFoldProduct_test_return_false_when_fold_expanding_nex_forms', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.getFoldProductType);
      when(mockFunc)().afterReturn(4);
      expect(CommonUtil.isLargeInFoldProduct()).assertFalse();
      mocker.ignoreMock(CommonUtil, CommonUtil.getFoldProductType);
    })
  });

  describe('checkNeedNotification_test', () => {
    it("getFoldProductType_test_error", 0, async () => {
      let checkNeedNotification = CommonUtil.checkNeedNotification();
      await CommonUtil.sleep(200);
      expect(checkNeedNotification).assertInstanceOf("Boolean");
    });

    it("checkOobeState_test_error", 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(GlobalThisUtil, GlobalThisUtil.getInstance);
      when(mockFunc)().afterThrow('error');
      let state = CommonUtil.checkOobeState();
      expect(state).assertFalse()
    });
  })

  describe('getAvailableEncoder_testSuite', () => {
    it('should_return_max_rate_when_video_type_h264_format', 2, async (done: Function) => {
      const result =
        await CommonUtil.getAvailableEncoder(media.AVScreenCaptureRecordPreset.SCREEN_RECORD_PRESET_H264_AAC_MP4);
      expect(result).assertInstanceOf("Number");
      done();
    });

    it('should_return_max_rate_when_video_type_h265_format', 2, async (done: Function) => {
      const result =
        await CommonUtil.getAvailableEncoder(media.AVScreenCaptureRecordPreset.SCREEN_RECORD_PRESET_H265_AAC_MP4);
      expect(result).assertInstanceOf("Number");
      done();
    });
  });

  describe('check_is_tgr_product', () => {
    it('checkIfDeviceIsTgr_test', 0, () => {
      expect(CommonUtil.checkIfDeviceIsTgr()).assertInstanceOf('Boolean');
    })
  });

  describe('subscribe_unsubscribe_test', () => {
    const driver = Driver.create();
    let windowManagerInstance: WindowManager = WindowManager.getInstance();
    it('subscribe_test', 0, async () => {
      try {
        await driver.delayMs(COMMON_DELAY);
        await controlCenterScreenRecord(driver);
        await driver.delayMs(COMMON_DELAY);
        let navbarEvent: CommonEventUtil =
          new CommonEventUtil([EVENT_NAME.NAVBAR_EVENT], windowManagerInstance.dismissShareWindow);
        await navbarEvent.subscribe();
        await driver.delayMs(COMMON_DELAY);
        navbarEvent.unsubscribe();
        await driver.delayMs(COMMON_DELAY);
        await controlCenterScreenRecord(driver);
      } catch (e) {
        expect().assertFail();
      }
    })
  });

  describe('getSystemParam_TestSuite', () => {
    it('getSystemParam_test_get_assign_value', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.getSystemParameter);
      when(mockFunc)('testKey').afterReturn('testValue');
      const resValue: string = CommonUtil.getSystemParameter('testKey');
      expect(resValue).assertEqual('testValue');
      mocker.ignoreMock(CommonUtil, CommonUtil.getSystemParameter);
    });

    it('getSystemParam_test_get_nothing', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CommonUtil, CommonUtil.getSystemParameter);
      when(mockFunc)('testKey').afterReturnNothing();
      const resValue: string = CommonUtil.getSystemParameter('testKey');
      expect(resValue).assertUndefined();
      mocker.ignoreMock(CommonUtil, CommonUtil.getSystemParameter);
    });
  });

  describe('getFoldProductType_test', () => {
    let mocker: MockKit = new MockKit();
    it('getFoldProductType_test_when_productValue_is_large_fold', 0, () => {
      let productValue: string = '1,1,0,0';
      when(mocker.mockFunc(CommonUtil, CommonUtil.getSystemParm))(ArgumentMatchers.any, ArgumentMatchers.any)
        .afterReturn(productValue);

      expect(CommonUtil.getFoldProductType()).assertEqual(FoldPhoneTypeValue.LARGE_FOLD);

      mocker.ignoreMock(CommonUtil, CommonUtil.getSystemParm);
    });

    it('getFoldProductType_test_when_productValue_is_straight', 0, () => {
      let productValue: string = '0,1,0,0';
      when(mocker.mockFunc(CommonUtil, CommonUtil.getSystemParm))(ArgumentMatchers.any, ArgumentMatchers.any)
        .afterReturn(productValue);

      expect(CommonUtil.getFoldProductType()).assertEqual(FoldPhoneTypeValue.STRAIGHT);

      mocker.ignoreMock(CommonUtil, CommonUtil.getSystemParm);
    });

    it('getFoldProductType_test_when_productValue_is_small_fold', 0, () => {
      let productValue: string = '2,1,0,0';
      when(mocker.mockFunc(CommonUtil, CommonUtil.getSystemParm))(ArgumentMatchers.any, ArgumentMatchers.any)
        .afterReturn(productValue);

      expect(CommonUtil.getFoldProductType()).assertEqual(FoldPhoneTypeValue.SMALL_FOLD);

      mocker.ignoreMock(CommonUtil, CommonUtil.getSystemParm);
    });

    it('getFoldProductType_test_when_productValue_is_external_fold', 0, () => {
      let productValue: string = '3,1,0,0';
      when(mocker.mockFunc(CommonUtil, CommonUtil.getSystemParm))(ArgumentMatchers.any, ArgumentMatchers.any)
        .afterReturn(productValue);

      expect(CommonUtil.getFoldProductType()).assertEqual(FoldPhoneTypeValue.EXTERNAL_FOLD);

      mocker.ignoreMock(CommonUtil, CommonUtil.getSystemParm);
    });

    it('getFoldProductType_test_when_productValue_is_expand_new_forms', 0, () => {
      let productValue: string = '4,1,0,0';
      when(mocker.mockFunc(CommonUtil, CommonUtil.getSystemParm))(ArgumentMatchers.any, ArgumentMatchers.any)
        .afterReturn(productValue);

      expect(CommonUtil.getFoldProductType()).assertEqual(FoldPhoneTypeValue.EXPANDING_NEX_FORMS);

      mocker.ignoreMock(CommonUtil, CommonUtil.getSystemParm);
    });

    it('atc_should_return_FoldPhoneTypeValue_when_productValue_is_invalid', 0, () => {
      let productValue: string = 'invalid';
      when(mocker.mockFunc(CommonUtil, CommonUtil.getSystemParm))(ArgumentMatchers.any, ArgumentMatchers.any)
        .afterReturn(productValue);

      expect(CommonUtil.getFoldProductType()).assertNaN();

      mocker.ignoreMock(CommonUtil, CommonUtil.getSystemParm);
    });

    it('atc_should_return_FoldPhoneTypeValue_when_productValue_is_empty', 0, () => {
      let productValue: string = '';
      when(mocker.mockFunc(CommonUtil, CommonUtil.getSystemParm))(ArgumentMatchers.any, ArgumentMatchers.any)
        .afterReturn(productValue);

      expect(CommonUtil.getFoldProductType()).assertNaN();

      mocker.ignoreMock(CommonUtil, CommonUtil.getSystemParm);
    });

    it('getFoldProductType_test_check_instance', 0, () => {
      let foldProductType = CommonUtil.getFoldProductType();
      expect(foldProductType).assertInstanceOf('Number');
    });

    it('getFoldProductType_test_check_return_min_value', 0, () => {
      let foldProductType = CommonUtil.getFoldProductType();
      expect(foldProductType).assertLarger(-2);
    });

    it('getFoldProductType_test_when_productValue_is_empty', 0, () => {
      when(mocker.mockFunc(CommonUtil, CommonUtil.getSystemParm))(ArgumentMatchers.any, ArgumentMatchers.any)
        .afterReturn('');
      expect(CommonUtil.getFoldProductType()).assertNaN();
    });
  });
}
