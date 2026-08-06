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
import { GlobalThisUtil, SettingDataUtil } from '@ohos/common';
import settings from '@ohos.settings';
import { describe, expect, it } from '@ohos/hypium';

export function SettingDataUtilTest() {
  describe('setSettingsDataSync_test', () => {
    let context: Context = GlobalThisUtil.getInstance()!.getObject('screenRecorderContext') as Context;
    it("setSettingsDataSync_test_with_Key_isEmpty", 1, () => {
      const result = SettingDataUtil.setSettingDataSync(context, '', 'defaultValue');
      expect(result).assertFalse();
    });

    it("setSettingsDataSync_test_with_domain_not_provide", 1, () => {
      const result = SettingDataUtil.setSettingDataSync(context, 'test_key', 'defaultValue');
      expect(result).assertTrue();
    });

    it("setSettingsDataSync_test_with_domain_user_security", 1, () => {
      const result =
        SettingDataUtil.setSettingDataSync(context, 'test_key', 'setValueTest', settings.domainName.USER_SECURITY);
      expect(result).assertTrue();
    });

    it("setSettingsDataSync_test_with_domain_user_property", 1, () => {
      const result =
        SettingDataUtil.setSettingDataSync(context, 'test_key', 'setValueTest', settings.domainName.USER_PROPERTY);
      expect(result).assertTrue();
    });
  });

  describe('getSettingsDataSync_test', () => {
    let context: Context = GlobalThisUtil.getInstance()!.getObject('screenRecorderContext') as Context;
    it('getSettingsDataSync_test_with_Key_isEmpty', 1, () => {
      const result = SettingDataUtil.getSettingsDataSync(context, '', 'defaultValue', 'testDomain');
      expect(result).assertEqual('');
    });

    it("getSettingsDataSync_test_with_domain_not_provide", 1, () => {
      let isSetSuccess = SettingDataUtil.setSettingDataSync(context, 'test_key', 'testResult');
      expect(isSetSuccess).assertTrue();
      const result = SettingDataUtil.getSettingsDataSync(context, 'test_key', 'testDefaultValue');
      expect(result).assertEqual('testResult');
    });

    it('getSettingsDataSync_test_with_domain_provide', 1, () => {
      let isSetSuccess =
        SettingDataUtil.setSettingDataSync(context, 'test_key', 'testResult', settings.domainName.USER_SECURITY);
      expect(isSetSuccess).assertTrue();
      const result =
        SettingDataUtil.getSettingsDataSync(context, 'test_key', 'testDefaultValue', settings.domainName.USER_SECURITY);
      expect(result).assertEqual('testResult');
    });

    it('getSettingsDataSync_test_with_domain_not_correct', 1, () => {
      let isSetSuccess =
        SettingDataUtil.setSettingDataSync(context, 'test_key1', 'testResult', settings.domainName.USER_SECURITY);
      expect(isSetSuccess).assertTrue();
      const result =
        SettingDataUtil.getSettingsDataSync(context, 'test_key1', 'testDefaultValue', settings.domainName.USER_PROPERTY);
      expect(result).assertEqual('testDefaultValue');
    });
  });
}

