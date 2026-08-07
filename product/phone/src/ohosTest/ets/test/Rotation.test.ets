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
import { Constants } from '../Constants';
import { controlCenterScreenRecord, landScapeControlCenterScreenRecord, notificationStop } from './common';
import { COMMON_DELAY, DELAY_BETWEEN_TESTS, MOVING_DELAY, SWIPE_START_X, SWIPE_START_Y } from './types';

const TAG = 'RotationTest';

/**
 * Rotation testcases
 *
 * @since 2023-07-15
 */
export function LandRotationTest() {
  describe('ActsLandRotationTest', () => {
    const driver = Driver.create();

    beforeEach(async () => {
      await driver.delayMs(DELAY_BETWEEN_TESTS);
      await controlCenterScreenRecord(driver);
      await driver.delayMs(MOVING_DELAY);
    });

    it('RotationPreWindowDestroyTest', 0, async () => {
      LogUtil.info(TAG, `RotationPreWindowDestroyTest start`);
      try {
        await notificationStop(driver);
        await driver.delayMs(COMMON_DELAY);
        await driver.swipe(SWIPE_START_X, SWIPE_START_Y, SWIPE_START_X + 30, SWIPE_START_Y);
        await controlCenterScreenRecord(driver);
        await driver.delayMs(COMMON_DELAY);
        await driver.setDisplayRotation(Constants.ROTATION_THREE);
        await driver.delayMs(COMMON_DELAY);
        await landScapeControlCenterScreenRecord(driver);
        await driver.delayMs(COMMON_DELAY);
        await driver.pressBack();
      } catch (e) {
        expect().assertFail();
      }
    });
  });
}

export function PortraitRotationTest() {
  describe('ActsPortraitRotationTest', () => {
    const driver = Driver.create();

    beforeEach(async () => {
      await driver.delayMs(DELAY_BETWEEN_TESTS);
      await controlCenterScreenRecord(driver);
      await driver.delayMs(MOVING_DELAY);
    });

    it('startScreenRecorderRotationTest', 0, async () => {
      LogUtil.info(TAG, `startScreenRecorderRotationTest start`);
      try {
        await driver.setDisplayRotation(Constants.ROTATION_THREE);
        await driver.delayMs(COMMON_DELAY);
        await landScapeControlCenterScreenRecord(driver);
        await driver.delayMs(COMMON_DELAY);
        await driver.pressBack();
      } catch (e) {
        expect().assertFail();
      }
    });
  });
}