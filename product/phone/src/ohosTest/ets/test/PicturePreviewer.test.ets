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
import { Driver, ON } from '@ohos.UiTest';
import { beforeEach, describe, expect, it } from '@ohos/hypium';
import { controlCenterScreenRecord, notificationStop } from './common';
import {
  COMMON_DELAY,
  DELAY_BETWEEN_TESTS,
  MOVING_DELAY,
  SWIPE_END_X,
  SWIPE_END_Y,
  SWIPE_LEFT_END_X,
  SWIPE_START_X,
  SWIPE_START_Y
} from './types';

const TAG = 'PicturePreviewerTest';

/**
 * Picture Previewer testcases
 *
 * @since 2023-07-15
 */
export default function PicturePreviewerTest() {
  describe('ActsPicturePreviewerTest', () => {
    const driver = Driver.create();

    beforeEach(async () => {
      await driver.delayMs(DELAY_BETWEEN_TESTS);
      await controlCenterScreenRecord(driver);
      await driver.delayMs(COMMON_DELAY);
      await controlCenterScreenRecord(driver);
    });

    it('dragPreviewCard', 0, async () => {
      LogUtil.info(TAG, 'drag preview card');
      try {
        await driver.delayMs(COMMON_DELAY);
        const previewCard = await driver.findComponent(ON.id('id_preview_card'));
        LogUtil.info(TAG, 'previewCard info:' + JSON.stringify(previewCard));
      } catch (e) {
        expect().assertFail();
      }
    });

    it('swipePreviewCardDestroy', 0, async () => {
      LogUtil.info(TAG, 'Show preview window destroy test');
      try {
        await driver.delayMs(COMMON_DELAY);
        await driver.swipe(SWIPE_START_X, SWIPE_START_Y, SWIPE_START_X + 30, SWIPE_START_Y);
        LogUtil.info(TAG, 'Move preview window back end');
        await controlCenterScreenRecord(driver);
        await driver.delayMs(COMMON_DELAY);
        await driver.swipe(SWIPE_START_X, SWIPE_START_Y, SWIPE_START_X + 30, SWIPE_START_Y);
        await driver.delayMs(COMMON_DELAY);
        await notificationStop(driver);
        await driver.delayMs(COMMON_DELAY);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('swipePreviewCardRight', 0, async () => {
      LogUtil.info(TAG, 'Swipe preview card right');

      // Swipe from coordinate (300, 2000) to coordinate (900, 2000)
      await driver.delayMs(COMMON_DELAY);
      await driver.swipe(SWIPE_START_X, SWIPE_START_Y, SWIPE_END_X, SWIPE_END_Y);
      await driver.delayMs(MOVING_DELAY);

      const previewCard = await driver.findComponent(ON.id('id_preview_card'));
      LogUtil.info(TAG, 'previewCard info:' + JSON.stringify(previewCard));
      expect(previewCard).assertNull();
    });

    it('swipePreviewCardLeft', 0, async () => {
      LogUtil.info(TAG, 'Swipe preview card left');

      // Swipe from coordinate (300, 2000) to coordinate (0, 2000)
      await driver.delayMs(COMMON_DELAY);
      await driver.swipe(SWIPE_START_X, SWIPE_START_Y, SWIPE_LEFT_END_X, SWIPE_END_Y);
      await driver.delayMs(MOVING_DELAY);

      const previewCard = await driver.findComponent(ON.id('id_preview_card'));
      LogUtil.info(TAG, 'previewCard info:' + JSON.stringify(previewCard));
      expect(previewCard).assertNull();
    });

    it('swipePreviewCardBack', 0, async () => {
      try {
        LogUtil.info(TAG, 'Show preview window test');
        await driver.delayMs(COMMON_DELAY);
        const previewCard = await driver.findComponent(ON.id('id_preview_card'));
        LogUtil.info(TAG, 'previewCard info:' + JSON.stringify(previewCard));
      } catch (e) {
        expect().assertFail();
      }
    });

    it('clickPreviewCard', 0, async () => {
      try {
        LogUtil.info(TAG, 'Click preview card');
        await driver.delayMs(COMMON_DELAY);
        const previewCard = await driver.findComponent(ON.id('id_preview_card'));
        LogUtil.info(TAG, 'previewCard info:' + JSON.stringify(previewCard));
      } catch (e) {
        LogUtil.info(TAG, 'clickPreviewCard   ' + e);
        expect().assertFail();
      }
    });
  });
}