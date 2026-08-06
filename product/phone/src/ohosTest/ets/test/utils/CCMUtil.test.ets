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
import { CCMUtil } from '@ohos/common/src/main/ets/util';
import { describe, expect, it, MockKit, when } from '@ohos/hypium';

export function CCMUtilTest() {
  describe('CCMUtil_GetParam_TestSuite', () => {
    it('ccm_getParam_test_check_instance', 0, () => {
      expect(CCMUtil.getCCMParam('test', 'testKey')).assertInstanceOf("Promise");
    })

    it('ccm_getParam_test_check_assign_value', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CCMUtil, CCMUtil.getCCMParam);
      when(mockFunc)('test', 'testKey').afterReturn('testValue')
      expect(CCMUtil.getCCMParam('test', 'testKey')).assertEqual('testValue');
      mocker.ignoreMock(CCMUtil, CCMUtil.getCCMParam);
    });

    it('ccm_getParam_test_return_nothing', 0, () => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CCMUtil, CCMUtil.getCCMParam);
      when(mockFunc)('test', 'testKey').afterReturnNothing();
      expect(CCMUtil.getCCMParam('test', 'testKey')).assertUndefined();
      mocker.ignoreMock(CCMUtil, CCMUtil.getCCMParam);
    });

    it('atc_should_return_default_value_when_getSync_success_with_default', 0, async () => {
      const testName: string = 'test_name';
      const testKey: string = 'test_key';
      const defaultValue: ESObject = 'default_value';
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(CCMUtil, CCMUtil.getCCMParam);
      when(mockFunc)(testName, testKey, defaultValue).afterReturn(defaultValue);
      const result: ESObject = await CCMUtil.getCCMParam(testName, testKey, defaultValue);
      expect(result).assertEqual(defaultValue);
    });

    it('atc_should_return_default_when_not_key', 0, async () => {
      const testName: string = 'test_name';
      const testKey: string = 'test_key';
      const defaultValue: ESObject = 'default_value';
      const result: ESObject = await CCMUtil.getCCMParam(testName, testKey, defaultValue);
      expect(result).assertEqual(defaultValue);
    });
  });
}