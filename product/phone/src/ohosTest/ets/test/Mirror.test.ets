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
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import { Driver } from '@ohos.UiTest';
import { beforeEach, describe, it, expect } from '@ohos/hypium';
import { Constants } from '../Constants';
import { controlCenterScreenRecord } from './common';
import {
  COMMON_DELAY,
  DELAY_BETWEEN_TESTS,
  MOVING_DELAY,
  SWIPE_FAST,
  SWIPE_X,
  SWIPE_Y,
  SWIPE_Y_END,
  SWITCH_LANGUAGE_DELAY
} from './types';

const TAG = 'MirrorTest';

/**
 * Mirror testcases
 *
 * @since 2023-07-15
 */
export default function MirrorTest() {
  describe('ActsMirrorTest', () => {
    const driver = Driver.create();
    const delegator = abilityDelegatorRegistry.getAbilityDelegator();

    beforeEach(async () => {
      await driver.delayMs(DELAY_BETWEEN_TESTS);
      await controlCenterScreenRecord(driver);
      await driver.delayMs(MOVING_DELAY);
    });

    it('ChangeMirrorLanguage', 0, async () => {
      LogUtil.info(TAG, `change mirror language test`);
      try {
        await delegator.startAbility(Constants.LANGUAGES_AND_REGIONS_WANT);
        await driver.delayMs(MOVING_DELAY);
        await driver.click(Constants.SWITCH_LANGUAGE_X, Constants.SWITCH_LANGUAGE_Y);
        await driver.delayMs(COMMON_DELAY);
        await controlCenterScreenRecord(driver);
        await driver.delayMs(SWITCH_LANGUAGE_DELAY);
        await driver.click(Constants.SWITCH_LANGUAGE_X, Constants.SWITCH_LANGUAGE_Y);
        await driver.delayMs(COMMON_DELAY);
        await driver.swipe(SWIPE_X, SWIPE_Y, SWIPE_X, SWIPE_Y_END, SWIPE_FAST);
      } catch (e) {
        expect().assertFail();
      }

    });
  });
}