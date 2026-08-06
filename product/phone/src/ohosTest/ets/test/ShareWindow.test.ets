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
import { WindowManager } from '@ohos/screen-recorder';
import { Driver, ON } from '@ohos.UiTest';
import { beforeEach, describe, it, expect, afterAll } from '@ohos/hypium';
import { controlCenterScreenRecord, swipeFromBottom } from './common';
import { COMMON_DELAY, DELAY_BETWEEN_TESTS, MOVING_DELAY } from './types';

const TAG = 'ShareWindowTest';

/**
 * Share window testcases
 *
 * @since 2023-07-15
 */
export default function ShareWindowTest() {
  describe('ActsShareWindowTest', () => {
    const driver = Driver.create();
    let windowManagerInstance: WindowManager = WindowManager.getInstance();

    beforeEach(async () => {
      await driver.delayMs(DELAY_BETWEEN_TESTS);
      await controlCenterScreenRecord(driver);
      await driver.delayMs(MOVING_DELAY);
      await controlCenterScreenRecord(driver);
    });

    afterAll(async () => {
      await driver.delayMs(DELAY_BETWEEN_TESTS);
      await swipeFromBottom(driver);
      await driver.delayMs(MOVING_DELAY);
    })

    it('startShareWindow', 0, async () => {
      LogUtil.info(TAG, 'destroy share window test');
      try {
        await driver.delayMs(COMMON_DELAY);
        await windowManagerInstance.startShare(undefined);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('destroyShareWindow', 0, async () => {
      LogUtil.info(TAG, 'destroy share window test');
      try {
        await driver.delayMs(COMMON_DELAY);
        const shareButton = await driver.findComponent(ON.id('id_share_button'));
        LogUtil.info(TAG, 'shareButton info:' + JSON.stringify(shareButton));
      } catch (e) {
        expect().assertFail();
      }
    });
  });
}