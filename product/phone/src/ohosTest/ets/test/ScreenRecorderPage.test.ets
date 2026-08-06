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
import { abilityDelegatorRegistry } from '@kit.TestKit';
import { Driver, ON } from '@ohos.UiTest';
import { afterAll, beforeAll, describe, expect, it } from '@ohos/hypium';
import { Constants } from '../Constants';
import { COMMON_DELAY, MOVING_DELAY } from './types';

/**
 * screen recorder page test
 */
export default function ScreenRecorderPageTest() {
  describe('ScreenRecorderPageTest', () => {
    const driver = Driver.create();
    const delegator = abilityDelegatorRegistry.getAbilityDelegator();

    beforeAll(async () => {
      await delegator.startAbility(Constants.OPEN_QUICK_GESTURES_WANT);
      await driver.delayMs(MOVING_DELAY);
      const screenRecorderItem =
        await driver.findComponent(ON.id('Setting.quick_gestures.wake_screen_settings.screen_recorder_setting.result'));
      await driver.delayMs(COMMON_DELAY);
      await screenRecorderItem.click();
    });

    afterAll(async () => {
      await driver.delayMs(COMMON_DELAY);
      await driver.pressBack();
      await driver.delayMs(MOVING_DELAY);
    });

    it('test_subtitle_exist', 0, async () => {
      await driver.delayMs(COMMON_DELAY);
      const subtitle = await driver.findComponent(ON.id('subtitle'));
      expect(await subtitle.getText()).assertEqual('双指关节录屏');
    });

    it('test_title_exist', 0, async () => {
      await driver.delayMs(COMMON_DELAY);
      const title = await driver.findComponent(ON.id('title'));
      expect(await title.getText()).assertEqual('录屏');
    });

    it('test_description_exist', 0, async () => {
      await driver.delayMs(COMMON_DELAY);
      const title = await driver.findComponent(ON.id('description'));
      expect(await title.getText()).assertEqual('双指关节双击启动/停止录屏');
    });
  });
}

