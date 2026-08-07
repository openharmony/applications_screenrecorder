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

import { LogUtil } from '@ohos/common';
import { Driver } from '@ohos.UiTest';
import { beforeEach, describe, it, expect } from '@ohos/hypium';
import { controlCenterScreenRecord } from './common';
import { COMMON_DELAY, DELAY_BETWEEN_TESTS, POWER_KEY, SCREEN_OFF_DELAY } from './types';

const TAG = 'CapsuleTest';

/**
 * Capsule testcases
 *
 * @since 2023-07-15
 */
export default function CapsuleTest() {
  describe('ActsCapsuleTest', () => {
    const driver = Driver.create();

    beforeEach(async () => {
      await driver.delayMs(DELAY_BETWEEN_TESTS);
      await controlCenterScreenRecord(driver);
      await driver.delayMs(COMMON_DELAY);
    });

    it('clickScreenKey', 0, async () => {
      LogUtil.info(TAG, 'Click ScreenKey');
      try {
        await driver.triggerKey(POWER_KEY);
        await driver.delayMs(SCREEN_OFF_DELAY);
      } catch (e) {
        expect().assertFail();
      }
    });
  });
}