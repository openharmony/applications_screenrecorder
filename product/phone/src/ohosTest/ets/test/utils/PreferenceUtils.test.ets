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
import { GlobalThisUtil, PreferenceUtils } from '@ohos/common';
import { common, Context } from '@kit.AbilityKit';
import { Driver, ON } from '@kit.TestKit';
import { ArgumentMatchers, describe, it, expect, MockKit, when } from '@ohos/hypium';
import { controlCenterScreenRecord, controlCenterScreenRecordLongPress,
  controlCenterScreenRecordLongPressRecorder } from '../common';
import { COMMON_DELAY, DELAY_BETWEEN_TESTS } from '../types';

export function PreferenceUtilsTest() {
  describe('PreferenceUtils_test', () => {
    const context = GlobalThisUtil.getInstance()!.getObject('screenRecorderContext') as common.UIAbilityContext;
    it('loadPreferences_test_with_fail', 0, async () => {
      let preferenceutils: PreferenceUtils = new PreferenceUtils();
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(preferenceutils, preferenceutils.getPreference);
      when(mockfunc)(ArgumentMatchers.any).afterThrow("Error");
      let context: common.UIAbilityContext = getContext() as common.UIAbilityContext;
      let key: string = 'testKey';
      let result = preferenceutils.loadPreferences(context, key);
      expect(result).assertPromiseIsResolved();
      mocker.ignoreMock(preferenceutils, preferenceutils.getPreference);
    })
    it('loadPreferences_test_when_key_is_contained', 0, async () => {
      let preferenceutils: PreferenceUtils = new PreferenceUtils();
      let mocker: MockKit = new MockKit();
      let key: string = 'testKey';
      let result = preferenceutils.loadPreferences(context, key);
      expect(result).assertPromiseIsResolved();
      mocker.ignoreMock(preferenceutils, preferenceutils.getPreference);
    });
    it('loadPreferences_test_getValue_test', 0, async () => {
      const driver = Driver.create();
      await driver.delayMs(DELAY_BETWEEN_TESTS);
      await controlCenterScreenRecordLongPressRecorder(driver);
      let context = GlobalThisUtil.getInstance()!.getObject('screenRecorderControlContext') as Context;
      let value = await PreferenceUtils.getValue(context, 'isMicEnabled', false);
      expect(value).assertFalse();
      await controlCenterScreenRecord(driver);
    });
  })
}

