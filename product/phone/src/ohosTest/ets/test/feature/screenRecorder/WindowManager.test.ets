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

import { GlobalThisUtil, LogUtil } from '@ohos/common';
import { RecorderUtil, WindowManager } from '@ohos/screen-recorder';
import { display } from '@kit.ArkUI';
import { ON } from '@kit.TestKit';
import { Driver } from '@ohos.UiTest';
import { ArgumentMatchers, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { controlCenterScreenRecord } from '../../common';
import { COMMON_DELAY, DELAY_BETWEEN_TESTS } from '../../types';

const TAG = 'WindowManagerTest';

/**
 * Window manager testcases
 *
 * @since 2025-04-29
 */
export function WindowManagerShareTest() {

  describe('shareVideo_test', () => {
    const driver = Driver.create();
    let windowManagerInstance: WindowManager = WindowManager.getInstance();
    it('id_share_button_share_test', 0, async () => {
      try {
        await prepareToShare(driver);
        await driver.click(200, 1800);
        await driver.delayMs(COMMON_DELAY);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('id_share_button_bluetooth_share_test', 0, async () => {
      try {
        await prepareToShare(driver);
        await driver.click(400, 1800);
        await driver.delayMs(COMMON_DELAY);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('id_share_button_chang_lian_test', 0, async () => {
      try {
        await prepareToShare(driver);
        await driver.click(600, 1800);
        await driver.delayMs(COMMON_DELAY);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('id_share_button_other_test', 0, async () => {
      try {
        await prepareToShare(driver);
        await driver.click(800, 1800);
        await driver.delayMs(COMMON_DELAY);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('id_share_button_email_test', 0, async () => {
      try {
        await prepareToShare(driver);
        await driver.click(1000, 1800);
        await driver.delayMs(COMMON_DELAY);
      } catch (e) {
        expect().assertFail();
      }
    });

    // it('showCapsuleWindow_test', 0, async () => {
    //   let result = windowManagerInstance.showCapsuleWindow();
    //   expect(result).assertPromiseIsResolved();
    // });

    it('initPreviewWindow_test', 0, async () => {
      let result = windowManagerInstance.initPreviewWindow(0);
      expect(result).assertPromiseIsResolved();
    });

    it('initPreviewWindow_w_100_h_100_test', 0, async () => {
      let result = windowManagerInstance.initPreviewWindow(0);
      expect(result).assertPromiseIsResolved();
    });

    it('setDisplayRotation_test', 0, async () => {
      windowManagerInstance.setDisplayRotation(1);
      let result = windowManagerInstance.onChange(0, 0, 0);
      expect(result).assertPromiseIsResolved();
    });

    it('initPreviewImage_test', 0, async () => {
      let result = windowManagerInstance.initPreviewImage();
      expect(result).assertPromiseIsResolved();
    });
  })
}

/**
 * Window manager testcases
 *
 * @since 2025-03-31
 */
export default function WindowManagerTest() {
  let windowManagerInstance: WindowManager = WindowManager.getInstance();
  describe('destroyPreWindow_test', () => {
    it('test_windowId_is_zero', 0, async () => {
      GlobalThisUtil.getInstance()!.setObject('windowId', 0);
      let result = windowManagerInstance.destroyPreWindow();
      expect(result).assertPromiseIsResolved();
    })
    it('test_windowId_is_not_zero', 0, async () => {
      try {
        GlobalThisUtil.getInstance()!.setObject('windowId', 10);
        await windowManagerInstance.destroyPreWindow();
      } catch (e) {
        expect().assertFail();
      }
    })
  })

  describe('onChange_test', () => {
    const driver = Driver.create();
    let mocker: MockKit = new MockKit();
    let globalThisUtil: GlobalThisUtil = GlobalThisUtil.getInstance();
    it('onChange_recording_test', 0, async () => {
      LogUtil.info(TAG, 'test onChange recording start');
      try {
        await driver.delayMs(DELAY_BETWEEN_TESTS);
        await controlCenterScreenRecord(driver);
        await driver.delayMs(COMMON_DELAY);
        let displayClass: display.Display = display.getDefaultDisplaySync();
        let rotation: number = 0;
        let mockGetObject: Function = mocker.mockFunc(globalThisUtil, globalThisUtil.getObject);
        when(mockGetObject)('isRecording').afterReturn(true);
        when(mockGetObject)('isPreViewWindowExisting').afterReturn(true);

        let mocPostKillProcessMessage: Function = mocker.mockFunc(RecorderUtil, RecorderUtil.postKillProcessMessage);
        when(mocPostKillProcessMessage)(ArgumentMatchers.any).afterReturnNothing;
        await windowManagerInstance.onChange(rotation, displayClass?.width, displayClass?.height);
        await driver.delayMs(COMMON_DELAY);
        await controlCenterScreenRecord(driver);
        mocker.ignoreMock(globalThisUtil, globalThisUtil.getObject);
        mocker.ignoreMock(RecorderUtil, RecorderUtil.postKillProcessMessage);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('onChange_recording_test_one', 0, async () => {
      try {
        LogUtil.info(TAG, 'test onChange recording start');
        await driver.delayMs(DELAY_BETWEEN_TESTS);
        await controlCenterScreenRecord(driver);
        await driver.delayMs(COMMON_DELAY);
        let displayClass: display.Display = display.getDefaultDisplaySync();
        let rotation: number = 1;
        let mockGetObject: Function = mocker.mockFunc(globalThisUtil, globalThisUtil.getObject);
        when(mockGetObject)('isRecording').afterReturn(true);
        when(mockGetObject)('isPreViewWindowExisting').afterReturn(true);
        let mocPostKillProcessMessage: Function = mocker.mockFunc(RecorderUtil, RecorderUtil.postKillProcessMessage);
        when(mocPostKillProcessMessage)(ArgumentMatchers.any).afterReturnNothing;
        await windowManagerInstance.onChange(rotation, displayClass?.width, displayClass?.height);
        await driver.delayMs(COMMON_DELAY);
        await controlCenterScreenRecord(driver);
        mocker.ignoreMock(globalThisUtil, globalThisUtil.getObject);
        mocker.ignoreMock(RecorderUtil, RecorderUtil.postKillProcessMessage);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('onChange_recording_test_two', 0, async () => {
      try {
        LogUtil.info(TAG, 'test onChange recording start');
        await driver.delayMs(DELAY_BETWEEN_TESTS);
        await controlCenterScreenRecord(driver);
        await driver.delayMs(COMMON_DELAY);
        let displayClass: display.Display = display.getDefaultDisplaySync();
        let rotation: number = 0;
        let mockGetObject: Function = mocker.mockFunc(globalThisUtil, globalThisUtil.getObject);
        when(mockGetObject)('isRecording').afterReturn(true);
        when(mockGetObject)('isPreViewWindowExisting').afterReturn(false);
        let mocPostKillProcessMessage: Function = mocker.mockFunc(RecorderUtil, RecorderUtil.postKillProcessMessage);
        when(mocPostKillProcessMessage)(ArgumentMatchers.any).afterReturnNothing;
        await windowManagerInstance.onChange(rotation, displayClass?.width, displayClass?.height);
        await driver.delayMs(COMMON_DELAY);
        await controlCenterScreenRecord(driver);
        mocker.ignoreMock(globalThisUtil, globalThisUtil.getObject);
        mocker.ignoreMock(RecorderUtil, RecorderUtil.postKillProcessMessage);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('onChange_recording_test_three', 0, async () => {
      try {
        LogUtil.info(TAG, 'test onChange recording start');
        await driver.delayMs(DELAY_BETWEEN_TESTS);
        await controlCenterScreenRecord(driver);
        await driver.delayMs(COMMON_DELAY);
        let displayClass: display.Display = display.getDefaultDisplaySync();
        let rotation: number = 1;
        let mockGetObject: Function = mocker.mockFunc(globalThisUtil, globalThisUtil.getObject);
        when(mockGetObject)('isRecording').afterReturn(true);
        when(mockGetObject)('isPreViewWindowExisting').afterReturn(false);
        let mocPostKillProcessMessage: Function = mocker.mockFunc(RecorderUtil, RecorderUtil.postKillProcessMessage);
        when(mocPostKillProcessMessage)(ArgumentMatchers.any).afterReturnNothing;
        await windowManagerInstance.onChange(rotation, displayClass?.width, displayClass?.height);
        await driver.delayMs(COMMON_DELAY);
        await controlCenterScreenRecord(driver);
        mocker.ignoreMock(globalThisUtil, globalThisUtil.getObject);
        mocker.ignoreMock(RecorderUtil, RecorderUtil.postKillProcessMessage);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('onChange_recording_test_four', 0, async () => {
      try {
        LogUtil.info(TAG, 'test onChange recording start');
        await driver.delayMs(DELAY_BETWEEN_TESTS);
        await controlCenterScreenRecord(driver);
        await driver.delayMs(COMMON_DELAY);
        let rotation: number = 0;
        let mockGetObject: Function = mocker.mockFunc(globalThisUtil, globalThisUtil.getObject);
        when(mockGetObject)('isRecording').afterReturn(true);
        when(mockGetObject)('isPreViewWindowExisting').afterReturn(true);
        let mocPostKillProcessMessage: Function = mocker.mockFunc(RecorderUtil, RecorderUtil.postKillProcessMessage);
        when(mocPostKillProcessMessage)(ArgumentMatchers.any).afterReturnNothing;
        await windowManagerInstance.onChange(rotation, 0, 0);
        await driver.delayMs(COMMON_DELAY);
        await controlCenterScreenRecord(driver);
        mocker.ignoreMock(globalThisUtil, globalThisUtil.getObject);
        mocker.ignoreMock(RecorderUtil, RecorderUtil.postKillProcessMessage);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('onChange_test_same', 0, async () => {
      try {
        LogUtil.info(TAG, 'test onChange start');
        await driver.delayMs(COMMON_DELAY);
        let rotation: number = 0;
        let mockGetObject: Function = mocker.mockFunc(globalThisUtil, globalThisUtil.getObject);
        when(mockGetObject)('isRecording').afterReturn(false);
        when(mockGetObject)('isPreViewWindowExisting').afterReturn(true);
        let mocPostKillProcessMessage: Function = mocker.mockFunc(RecorderUtil, RecorderUtil.postKillProcessMessage);
        when(mocPostKillProcessMessage)(ArgumentMatchers.any).afterReturnNothing;
        await windowManagerInstance.onChange(rotation, 0, 0);
        mocker.ignoreMock(globalThisUtil, globalThisUtil.getObject);
        mocker.ignoreMock(RecorderUtil, RecorderUtil.postKillProcessMessage);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('onChange_test_same_one', 0, async () => {
      try {
        LogUtil.info(TAG, 'test onChange start');
        await driver.delayMs(COMMON_DELAY);
        let rotation: number = 0;
        let mockGetObject: Function = mocker.mockFunc(globalThisUtil, globalThisUtil.getObject);
        when(mockGetObject)('isRecording').afterReturn(false);
        when(mockGetObject)('isPreViewWindowExisting').afterReturn(false);
        let mocPostKillProcessMessage: Function = mocker.mockFunc(RecorderUtil, RecorderUtil.postKillProcessMessage);
        when(mocPostKillProcessMessage)(ArgumentMatchers.any).afterReturnNothing;
        await windowManagerInstance.onChange(rotation, 0, 0);
        mocker.ignoreMock(globalThisUtil, globalThisUtil.getObject);
        mocker.ignoreMock(RecorderUtil, RecorderUtil.postKillProcessMessage);
      } catch (e) {
        expect().assertFail();
      }
    });

    it('onChange_test_diff', 0, async () => {
      try {
        LogUtil.info(TAG, 'test onChange start');
        await driver.delayMs(COMMON_DELAY);
        let rotation: number = 1;
        let mockGetObject: Function = mocker.mockFunc(globalThisUtil, globalThisUtil.getObject);
        when(mockGetObject)('isRecording').afterReturn(false);
        when(mockGetObject)('isPreViewWindowExisting').afterReturn(true);
        let mocPostKillProcessMessage: Function = mocker.mockFunc(RecorderUtil, RecorderUtil.postKillProcessMessage);
        when(mocPostKillProcessMessage)(ArgumentMatchers.any).afterReturnNothing;
        await windowManagerInstance.onChange(rotation, 0, 0);
        mocker.ignoreMock(globalThisUtil, globalThisUtil.getObject);
        mocker.ignoreMock(RecorderUtil, RecorderUtil.postKillProcessMessage);
      } catch (e) {
        expect().assertFail();
      }
    });
  })
}

async function prepareToShare(driver: Driver) {
  await driver.delayMs(COMMON_DELAY);
  await controlCenterScreenRecord(driver);
  await driver.delayMs(DELAY_BETWEEN_TESTS);
  await controlCenterScreenRecord(driver);
  await driver.delayMs(COMMON_DELAY);
  const screenRecorderItem = await driver.findComponent(ON.id('id_share_button'));
  LogUtil.info(TAG, 'share button clicked');
  await screenRecorderItem.click();
  await driver.delayMs(COMMON_DELAY);
}
