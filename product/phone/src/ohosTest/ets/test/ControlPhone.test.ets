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
import { beforeEach, describe, it, expect} from '@ohos/hypium';
import { controlCenterScreenRecord, controlCenterScreenRecordLongPress, notificationStop } from './common';
import {
  COMMON_DELAY,
  CONTROL_BUTTON_X,
  CONTROL_MIC_Y,
  CONTROL_TRACK_Y,
  DELAY_BETWEEN_TESTS,
  MOVING_DELAY,
  RECORDER_X,
  SCREENRECORDER_Y
} from './types';

const TAG = 'ControlPhoneTest';

/**
 * ControlPhone testcases
 *
 * @since 2023-07-15
 */
export function ControlPhoneBeforeRecorderTest() {
  describe('ActsControlPhoneBeforeRecorderTest', () => {
    const driver = Driver.create();

    beforeEach(async () => {
      await driver.delayMs(DELAY_BETWEEN_TESTS);
      await controlCenterScreenRecordLongPress(driver);
      await driver.delayMs(COMMON_DELAY);
    });

    it('openControlPhonePage', 0, async () => {
      LogUtil.info(TAG, 'open ControlPhone page');
      try {
        await driver.pressBack();
        await driver.delayMs(COMMON_DELAY);
        await driver.pressBack();
      } catch (e) {
        expect().assertFail();
      }
    });

    it('controlPhonePageStartRecorder', 0, async () => {
      LogUtil.info(TAG, 'control page start recorder');
      try {
        await driver.click(RECORDER_X, SCREENRECORDER_Y);
        await driver.delayMs(MOVING_DELAY);
        await controlCenterScreenRecordLongPress(driver);
        await driver.delayMs(COMMON_DELAY);
        await driver.click(RECORDER_X, SCREENRECORDER_Y);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('toggleMicButtonBeforeRecorder', 0, async () => {
      LogUtil.info(TAG, 'toggle mic Button Before Recorder');
      try {
        await driver.click(CONTROL_BUTTON_X, CONTROL_MIC_Y);
        await driver.delayMs(MOVING_DELAY);
        await driver.click(RECORDER_X, SCREENRECORDER_Y);
        await driver.delayMs(MOVING_DELAY);
        await notificationStop(driver);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('toggleTrackButtonBeforeRecorder', 0, async () => {
      LogUtil.info(TAG, 'toggle track Button Before Recorder');
      try {
        await driver.click(CONTROL_BUTTON_X, CONTROL_TRACK_Y);
        await driver.delayMs(MOVING_DELAY);
        await driver.click(RECORDER_X, SCREENRECORDER_Y);
        await driver.delayMs(MOVING_DELAY);
        await notificationStop(driver);
      } catch (e) {
        expect().assertFail();
      }
    });
  });
}

export function ControlPhoneOnRecorderTest() {
  describe('ActsControlPhoneOnRecorderTest', () => {
    const driver = Driver.create();

    beforeEach(async () => {
      await driver.delayMs(MOVING_DELAY);
      await controlCenterScreenRecord(driver);
      await driver.delayMs(COMMON_DELAY);
    });

    it('toggleMicButtonOnRecorder', 0, async () => {
      LogUtil.info(TAG, 'toggle mic Button On Recorder');
      try {
        await controlCenterScreenRecordLongPress(driver);
        await driver.click(CONTROL_BUTTON_X, CONTROL_MIC_Y);
        await driver.delayMs(COMMON_DELAY);
        await driver.click(RECORDER_X, SCREENRECORDER_Y);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('toggleTrackButtonOnRecorder', 0, async () => {
      LogUtil.info(TAG, 'toggle track Button On Recorder');
      try {
        await controlCenterScreenRecordLongPress(driver);
        await driver.click(CONTROL_BUTTON_X, CONTROL_TRACK_Y);
        await driver.delayMs(COMMON_DELAY);
        await driver.click(RECORDER_X, SCREENRECORDER_Y);
      } catch (e) {
        expect().assertFail();
      }
    });
  });
}