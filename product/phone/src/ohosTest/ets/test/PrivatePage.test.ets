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
import { controlCenterScreenRecord, notificationStop, openControlCenter, swipeFromBottom } from './common';
import {
  DELAY_BETWEEN_TESTS,
  LOCK_SCREEN_X,
  LOCK_SCREEN_Y,
  MOVING_DELAY,
  SWIPE_FAST,
  SWIPE_X,
  SWIPE_Y,
  SWIPE_Y_END
} from './types';

const TAG = 'PrivatePageTest';

/**
 * PrivatePage testcases
 *
 * @since 2023-07-15
 */
export default function PrivatePageTest() {
  describe('ActsPrivatePageTest', () => {
    const driver = Driver.create();
    const delegator = abilityDelegatorRegistry.getAbilityDelegator();

    beforeEach(async () => {
      await driver.delayMs(DELAY_BETWEEN_TESTS);
      await controlCenterScreenRecord(driver);
      await driver.delayMs(MOVING_DELAY);
    });

    it('PrivateWindowOnScreenRecorder', 0, async () => {
      LogUtil.info(TAG, `PrivateWindowScreenRecorder start`);
      try {
        await delegator.startAbility(Constants.LOCK_SCREEN_PASSWORD_WANT);
        await driver.delayMs(MOVING_DELAY);
        await driver.click(LOCK_SCREEN_X, LOCK_SCREEN_Y);
        await driver.delayMs(MOVING_DELAY);
        await notificationStop(driver);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('PrivateWindowBeforeScreenRecorder', 0, async () => {
      try {
        LogUtil.info(TAG, `PrivateWindowScreenRecorder start`);
        await notificationStop(driver);
        await driver.delayMs(MOVING_DELAY);
        await driver.swipe(SWIPE_X, SWIPE_Y, SWIPE_X, SWIPE_Y_END, SWIPE_FAST);
      } catch (e) {
        expect().assertFail();
      }
    });

    // it('change_dark_model', 0, async () => {
    //   LogUtil.info(TAG, `PrivateWindowScreenRecorder start`);
    //   try {
    //     await openControlCenter(driver);
    //     await driver.delayMs(MOVING_DELAY);
    //     await swipeFromBottom(driver);
    //     await driver.delayMs(MOVING_DELAY);
    //     LogUtil.info('zhahsh', '-----------------------------')
    //     await notificationStop(driver);
    //     LogUtil.info('zhahsh', '++++++++++++++++++++++++++++++')
    //     await driver.delayMs(MOVING_DELAY);
    //     await driver.swipe(SWIPE_X, SWIPE_Y, SWIPE_X, SWIPE_Y_END, SWIPE_FAST);
    //   } catch (e) {
    //     expect().assertFail();
    //   }
    // });
  });
}