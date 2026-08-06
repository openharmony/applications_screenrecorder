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
import { controlCenterScreenRecord, notificationStop } from './common';
import { COMMON_DELAY, MOVING_DELAY, SWIPE_FAST, SWIPE_X, SWIPE_Y, SWIPE_Y_END } from './types';

const TAG = 'NotificationTest';

/**
 * Notification testcases
 *
 * @since 2023-07-15
 */
export function LightNotificationTest() {
  describe('ActsLightNotificationTest', () => {
    const driver = Driver.create();
    const delegator = abilityDelegatorRegistry.getAbilityDelegator();

    beforeEach(async () => {
      await driver.delayMs(MOVING_DELAY);
      await controlCenterScreenRecord(driver);
      await driver.delayMs(COMMON_DELAY);
    });

    it('clickTrackButton', 0, async () => {
      LogUtil.info(TAG, 'Click Notification button');
      try {
        await driver.click(Constants.NOTIFICATION_X, Constants.NOTIFICATION_Y);
        await driver.delayMs(COMMON_DELAY);
        // track button
        await driver.click(Constants.TRACK_BUTTON_X, Constants.NOTIFICATION_BUTTON_Y);
        await driver.delayMs(COMMON_DELAY);
        await notificationStop(driver);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('clickMicButton', 0, async () => {
      LogUtil.info(TAG, 'Click Notification button');
      try {
        await driver.click(Constants.NOTIFICATION_X, Constants.NOTIFICATION_Y);
        await driver.delayMs(COMMON_DELAY);
        // mic button
        await driver.click(Constants.MIC_BUTTON_X, Constants.NOTIFICATION_BUTTON_Y);
        await driver.delayMs(COMMON_DELAY);
        await notificationStop(driver);
      } catch (e) {
        expect().assertFail();
      }
    });
  });
}

export function DarkNotificationTest() {
  describe('ActsDarkNotificationTest', () => {
    const driver = Driver.create();
    const delegator = abilityDelegatorRegistry.getAbilityDelegator();

    beforeEach(async () => {
      await driver.delayMs(MOVING_DELAY);
      await controlCenterScreenRecord(driver);
      await driver.delayMs(COMMON_DELAY);
    });

    it('changeToDarkMode', 0, async () => {
      LogUtil.info(TAG, 'Click stop button');
      try {
        await delegator.startAbility(Constants.DARK_UI_MODE_WANT);
        await driver.delayMs(COMMON_DELAY);
        await driver.click(Constants.DARK_MODE_X, Constants.DARK_MODE_Y);
        await driver.delayMs(COMMON_DELAY);
        await driver.click(Constants.START_DARK_MODE_X, Constants.START_DARK_MODE_Y);
        await driver.delayMs(COMMON_DELAY);
        await notificationStop(driver);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('clickMicButtonOnDarkMode', 0, async () => {
      LogUtil.info(TAG, 'Click mic button on dark mode');
      try {
        await driver.click(Constants.NOTIFICATION_X, Constants.NOTIFICATION_Y);
        await driver.delayMs(COMMON_DELAY);
        // mic button
        await driver.click(Constants.MIC_BUTTON_X, Constants.NOTIFICATION_BUTTON_Y);
        await driver.delayMs(COMMON_DELAY);
        await notificationStop(driver);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('clickTrackButtonOnDarkMode', 0, async () => {
      LogUtil.info(TAG, 'Click track button on dark mode');
      try {
        await driver.click(Constants.NOTIFICATION_X, Constants.NOTIFICATION_Y);
        await driver.delayMs(COMMON_DELAY);
        // track button
        await driver.click(Constants.TRACK_BUTTON_X, Constants.NOTIFICATION_BUTTON_Y);
        await driver.delayMs(COMMON_DELAY);
        await notificationStop(driver);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('changeToLightMode', 0, async () => {
      LogUtil.info(TAG, 'Click stop button');
      try {
        await driver.delayMs(COMMON_DELAY);
        await driver.click(Constants.START_DARK_MODE_X, Constants.START_DARK_MODE_Y);
        await driver.delayMs(COMMON_DELAY);
        await notificationStop(driver);
        await driver.delayMs(COMMON_DELAY);
        await driver.swipe(SWIPE_X, SWIPE_Y, SWIPE_X, SWIPE_Y_END, SWIPE_FAST);
      } catch (e) {
        expect().assertFail();
      }
    });
  });
}
