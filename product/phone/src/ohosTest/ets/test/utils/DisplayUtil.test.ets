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

import { DisplayUtil, LogUtil } from '@ohos/common';
import { describe, expect, it, MockKit, when } from '@ohos/hypium';

const onFoldChangeCallBackTest = (status: number) => {
  LogUtil.info(status);
};
export function DisplayUtilTest() {
  describe('DisplayUtil_test', () => {
    it("vp2pxInTs_test_number", 0, () => {
      let vp2pxInTs = DisplayUtil.vp2pxInTs(1000, 10);
      expect(vp2pxInTs).assertInstanceOf("Number");
    });

    it("vp2pxInTs_test_check_assign_value", 0, () => {
      let vp2pxInTs = DisplayUtil.vp2pxInTs(160, 10);
      expect(vp2pxInTs).assertEqual(10);
    });

    it("isLandscapeMode_test_boolean", 0, () => {
      let isLandscapeMode = DisplayUtil.isLandscapeMode();
      expect(isLandscapeMode).assertInstanceOf("Boolean");
    });

    it("isLandscapeMode_test_check_valid_value_list", 0, () => {
      let isLandscapeMode = DisplayUtil.isLandscapeMode();
      expect([true, false]).assertContain(isLandscapeMode);
    });

    it("isLandscapeModeRtl_test_boolean", 0, () => {
      let isLandscapeModeRtl = DisplayUtil.isLandscapeModeRtl();
      expect(isLandscapeModeRtl).assertInstanceOf("Boolean");
    });

    it("isLandscapeModeRtl_test_check_valid_value_list", 0, () => {
      let isLandscapeModeRtl = DisplayUtil.isLandscapeModeRtl();
      expect([true, false]).assertContain(isLandscapeModeRtl);
    });

    it("isHalfFoldedState_test_boolean", 0, () => {
      let isHalfFoldedState = DisplayUtil.isHalfFoldedState();
      expect(isHalfFoldedState).assertInstanceOf("Boolean");
    });

    it("isHalfFoldedState_test_check_valid_value_list", 0, () => {
      let isHalfFoldedState = DisplayUtil.isHalfFoldedState();
      expect([true, false]).assertContain(isHalfFoldedState);
    });

    it('isSmallFoldScreen_test_boolean', 0, () => {
      let isSmallFoldScreen = DisplayUtil.isSmallFoldScreen();
      expect(isSmallFoldScreen).assertInstanceOf("Boolean");
    });

    it('isSmallFoldScreen_test_check_valid_value_list', 0, () => {
      let isSmallFoldScreen = DisplayUtil.isSmallFoldScreen();
      expect([true, false]).assertContain(isSmallFoldScreen);
    });

    it('isExpandedStatus_test_boolean', 0, () => {
      let isExpandedStatus = DisplayUtil.isExpandedStatus();
      expect(isExpandedStatus).assertInstanceOf("Boolean");
    });

    it('isExpandedStatus_test_check_valid_value_list', 0, () => {
      let isExpandedStatus = DisplayUtil.isExpandedStatus();
      expect([true, false]).assertContain(isExpandedStatus);
    });

    it('isFoldedStatus_test_boolean', 0, () => {
      let isFoldedStatus = DisplayUtil.isFoldedStatus();
      expect(isFoldedStatus).assertInstanceOf("Boolean");
    });

    it('isFoldedStatus_test_check_valid_value_list', 0, () => {
      let isFoldedStatus = DisplayUtil.isFoldedStatus();
      expect([true, false]).assertContain(isFoldedStatus);
    });

    it('getFoldStatus_test_number', 0, () => {
      let isFoldedStatus = DisplayUtil.getFoldStatus();
      expect(isFoldedStatus).assertInstanceOf("Number");
    });

    it('getFoldStatus_test_check_min_value', 0, () => {
      let isFoldedStatus = DisplayUtil.getFoldStatus();
      expect(isFoldedStatus).assertLargerOrEqual(0);
    });

    it('registerFoldStatusChange_test', 1, () => {
      try {
        DisplayUtil.registerFoldStatusChange(onFoldChangeCallBackTest);
      }catch (e) {
        expect().assertFail();
      }
    });

    it('unregisterFoldStatusChange_test', 1, () => {
      try {
        DisplayUtil.unRegisterFoldStatusChange(onFoldChangeCallBackTest)
      }catch (e) {
        expect().assertFail();
      }

    })

    it('isOneHandedMode_test_boolean', 0, () => {
      let isOneHandedMode = DisplayUtil.isOneHandedMode(getContext());
      expect(isOneHandedMode).assertInstanceOf('Boolean');
    })

    it('isOneHandedMode_test_check_valid_value_list', 0, () => {
      let isOneHandedMode = DisplayUtil.isOneHandedMode(getContext());
      expect([true, false]).assertContain(isOneHandedMode);
    });
  });

  describe('getSystemParameter_TestSuite', () => {
    it('getSystemParam_test_equals_special_value', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(DisplayUtil, DisplayUtil.getSystemParameter);
      when(mockFunc)('testKey').afterReturn('testValue');
      const resValue: string = DisplayUtil.getSystemParameter('testKey');
      expect(resValue).assertEqual('testValue');
      mocker.ignoreMock(DisplayUtil, DisplayUtil.getSystemParameter);
    });

    it('getSystemParam_test_return_undefined', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(DisplayUtil, DisplayUtil.getSystemParameter);
      when(mockFunc)('testKey').afterReturnNothing();
      const resValue: string = DisplayUtil.getSystemParameter('testKey');
      expect(resValue).assertUndefined();
      mocker.ignoreMock(DisplayUtil, DisplayUtil.getSystemParameter);
    });
  });

  describe('isSmallFoldScreen_TestSuite', () => {
    it('isSmallFoldScreen_test_return_true_when_smallfold', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(DisplayUtil, DisplayUtil.getSystemParameter);
      when(mockFunc)('const.window.foldscreen.type').afterReturn('2,1,0,0');
      let isSmallFoldScreen = DisplayUtil.isSmallFoldScreen();
      expect(isSmallFoldScreen).assertTrue();
      mocker.ignoreMock(DisplayUtil, DisplayUtil.getSystemParameter);
    });

    it('isSmallFoldScreen_test_return_true_when_smallfold_four', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(DisplayUtil, DisplayUtil.getSystemParameter);
      when(mockFunc)('const.window.foldscreen.type').afterReturn('4,2,0,0');
      let isSmallFoldScreen = DisplayUtil.isSmallFoldScreen();
      expect(isSmallFoldScreen).assertTrue();
      mocker.ignoreMock(DisplayUtil, DisplayUtil.getSystemParameter);
    });

    it('isSmallFoldScreen_test_return_false_with_bigfold', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(DisplayUtil, DisplayUtil.getSystemParameter);
      when(mockFunc)('const.window.foldscreen.type').afterReturn('1,2,0,0');
      let isSmallFoldScreen = DisplayUtil.isSmallFoldScreen();
      expect(isSmallFoldScreen).assertFalse();
      mocker.ignoreMock(DisplayUtil, DisplayUtil.getSystemParameter);
    });

    it('isSmallFoldScreen_test_return_false_with_fold_two', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(DisplayUtil, DisplayUtil.getSystemParameter);
      when(mockFunc)('const.window.foldscreen.type').afterReturn('6,2,0,0');
      let isSmallFoldScreen = DisplayUtil.isSmallFoldScreen();
      expect(isSmallFoldScreen).assertFalse();
      mocker.ignoreMock(DisplayUtil, DisplayUtil.getSystemParameter);
    });
  });

  describe('isVerdeProducts_TestSuite', () => {
    it('isVerdeProducts_test_check_instance', 0, () => {
      let isVerdeProduct = DisplayUtil.isVerdeProducts();
      expect(isVerdeProduct).assertInstanceOf("Boolean");
    });

    it('isVerdeProducts_test_return_true_with_valid', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(DisplayUtil, DisplayUtil.getSystemParameter);
      when(mockFunc)('const.window.foldscreen.type').afterReturn('4,5,0,0');
      let isVerdeProduct = DisplayUtil.isVerdeProducts();
      expect(isVerdeProduct).assertTrue();
      mocker.ignoreMock(DisplayUtil, DisplayUtil.getSystemParameter);
    });

    it('isVerdeProducts_test_return_false_with_bigfold', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(DisplayUtil, DisplayUtil.getSystemParameter);
      when(mockFunc)('const.window.foldscreen.type').afterReturn('2,1,0,0');
      let isVerdeProduct = DisplayUtil.isVerdeProducts();
      expect(isVerdeProduct).assertFalse();
      mocker.ignoreMock(DisplayUtil, DisplayUtil.getSystemParameter);
    });

    it('isVerdeProducts_test_return_false_with_invalid', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(DisplayUtil, DisplayUtil.getSystemParameter);
      when(mockFunc)('const.window.foldscreen.type').afterReturn('-1,1,0,0');
      let isVerdeProduct = DisplayUtil.isVerdeProducts();
      expect(isVerdeProduct).assertFalse();
      mocker.ignoreMock(DisplayUtil, DisplayUtil.getSystemParameter);
    });
  });

  describe('isThreeFoldScreen_test', () => {
    let mocker: MockKit = new MockKit();
    it('isThreeFoldScreen_test_with_fold_property_is_null', 0, () => {
      when(mocker.mockFunc(DisplayUtil, DisplayUtil.getFoldProductProperty))().afterReturn('');

      expect(DisplayUtil.isThreeFoldScreen()).assertFalse();

      mocker.ignoreMock(DisplayUtil, DisplayUtil.getFoldProductProperty);
    });

    it('isThreeFoldScreen_test_with_fold_property_is_small', 0, () => {
      when(mocker.mockFunc(DisplayUtil, DisplayUtil.getFoldProductProperty))().afterReturn('2,');

      expect(DisplayUtil.isThreeFoldScreen()).assertFalse();

      mocker.ignoreMock(DisplayUtil, DisplayUtil.getFoldProductProperty);
    });

    it('isThreeFoldScreen_test_with_fold_property_is_small_four', 0, () => {
      when(mocker.mockFunc(DisplayUtil, DisplayUtil.getFoldProductProperty))().afterReturn('4,');

      expect(DisplayUtil.isThreeFoldScreen()).assertFalse();

      mocker.ignoreMock(DisplayUtil, DisplayUtil.getFoldProductProperty);
    });

    it('isThreeFoldScreen_test_with_fold_property_is_three_fold', 0, () => {
      when(mocker.mockFunc(DisplayUtil, DisplayUtil.getFoldProductProperty))().afterReturn('6,');

      expect(DisplayUtil.isThreeFoldScreen()).assertTrue();

      mocker.ignoreMock(DisplayUtil, DisplayUtil.getFoldProductProperty);
    });
  });
}