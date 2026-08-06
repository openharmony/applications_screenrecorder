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
import { display } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { Driver, ON } from '@ohos.UiTest';
import { Constants } from '../Constants';
import { COMMON_DELAY } from './types';

const TAG = 'ohosTest_common';

// 控制中心录屏
export const controlCenterScreenRecord = async (driver: Driver) => {
  try {
    let deviceWidth = display.getDefaultDisplaySync().width;
    let deviceHeight = display.getDefaultDisplaySync().height;
    const X = deviceWidth - Constants.BACK_SAFE_DISTANCE;
    await driver.swipe(X, 0, X, deviceHeight, Constants.SWIPE_SPEED_FAST);
    const btnImage = await driver.findComponent(ON.id('Ctrl.NewToggleBaseComponent_Image_toggle_screen_recorder'));
    await driver.delayMs(COMMON_DELAY);
    await btnImage.click();
  } catch (err) {
    LogUtil.error(TAG, 'setDeviceRate getDefaultDisplaySync, err: ' + (err as BusinessError).message);
  }
}

// 横屏状态控制中心开启录屏
export const landScapeControlCenterScreenRecord = async (driver: Driver) => {
  try {
    let deviceWidth = display.getDefaultDisplaySync().width;
    let deviceHeight = display.getDefaultDisplaySync().height;
    LogUtil.info(TAG, `landscape get width: ${deviceWidth}, height: ${deviceHeight}`);
    const X = deviceWidth - Constants.BACK_SAFE_DISTANCE;
    LogUtil.info(TAG, `device in landscape status`);
    await driver.swipe(X, 0, X, deviceHeight, Constants.SWIPE_SPEED_FAST);
    await driver.delayMs(COMMON_DELAY);
    await driver.swipe(X, 0, X, deviceHeight, Constants.SWIPE_SPEED_FAST);
    const btnImage = await driver.findComponent(ON.id('Ctrl.NewToggleBaseComponent_Image_toggle_screen_recorder'));
    LogUtil.info(TAG, `click recorder button`);
    await btnImage.click();
  } catch (err) {
    LogUtil.error(TAG, 'land setDeviceRate getDefaultDisplaySync, err: ' + (err as BusinessError).message);
  }
}

// 控制中心录屏长按
export const controlCenterScreenRecordLongPress = async (driver: Driver) => {
  try {
    let deviceWidth = display.getDefaultDisplaySync().width;
    let deviceHeight = display.getDefaultDisplaySync().height;
    let deviceRotation = display.getDefaultDisplaySync().rotation;
    const X = deviceWidth - Constants.BACK_SAFE_DISTANCE;
    if (deviceRotation === Constants.ROTATION_ONE || deviceRotation === Constants.ROTATION_THREE) {
      LogUtil.info(TAG, `device in landscape status`);
      await driver.swipe(X, 0, X, deviceHeight, Constants.SWIPE_SPEED_FAST);
      await driver.delayMs(COMMON_DELAY);
    }
    await driver.swipe(X, 0, X, deviceHeight, Constants.SWIPE_SPEED_FAST);
    const btnImage = await driver.findComponent(ON.id('Ctrl.NewToggleBaseComponent_Image_toggle_screen_recorder'));
    await btnImage.longClick();
  } catch (err) {
    LogUtil.error(TAG, 'setDeviceRate getDefaultDisplaySync, err: ' + (err as BusinessError).message);
  }
}

// 控制中心录屏长按开启录屏
export const controlCenterScreenRecordLongPressRecorder = async (driver: Driver) => {
  try {
    let deviceWidth = display.getDefaultDisplaySync().width;
    let deviceHeight = display.getDefaultDisplaySync().height;
    let deviceRotation = display.getDefaultDisplaySync().rotation;
    const X = deviceWidth - Constants.BACK_SAFE_DISTANCE;
    if (deviceRotation === Constants.ROTATION_ONE || deviceRotation === Constants.ROTATION_THREE) {
      LogUtil.info(TAG, `device in landscape status`);
      await driver.swipe(X, 0, X, deviceHeight, Constants.SWIPE_SPEED_FAST);
      await driver.delayMs(COMMON_DELAY);
    }
    await driver.swipe(X, 0, X, deviceHeight, Constants.SWIPE_SPEED_FAST);
    const btnImage = await driver.findComponent(ON.id('Ctrl.NewToggleBaseComponent_Image_toggle_screen_recorder'));
    await btnImage.longClick();
    await driver.delayMs(COMMON_DELAY);
    const bottomView = await driver.findComponent(ON.id('bottomView'));
    await bottomView.click();
    await driver.delayMs(COMMON_DELAY);
  } catch (err) {
    LogUtil.error(TAG, 'setDeviceRate getDefaultDisplaySync, err: ' + (err as BusinessError).message);
  }
}

// 底部向上滑动
export const swipeFromBottom = async (driver: Driver) => {
  try {
    let deviceWidth = display.getDefaultDisplaySync().width;
    let deviceHeight = display.getDefaultDisplaySync().height;
    const X = Math.ceil(deviceWidth / 2);
    const startY = deviceHeight
    const endY = Math.ceil(deviceHeight / 2);
    await driver.swipe(X, startY, X, endY, Constants.SWIPE_SPEED_FAST);
  } catch (err) {
    LogUtil.error(TAG, 'setDeviceRate getDefaultDisplaySync, err: ' + (err as BusinessError).message);
  }
}

// 实况暂停录屏
export const notificationStop = async (driver: Driver) => {
  await driver.click(Constants.NOTIFICATION_X, Constants.NOTIFICATION_Y);
  await driver.delayMs(COMMON_DELAY);
  // stop button
  await driver.click(Constants.STOP_BUTTON_X, Constants.NOTIFICATION_BUTTON_Y);
}

// 打开控制中心
export const openControlCenter = async (driver: Driver) => {
  let deviceWidth = display.getDefaultDisplaySync().width;
  let deviceHeight = display.getDefaultDisplaySync().height;
  const X = deviceWidth - Constants.BACK_SAFE_DISTANCE;
  await driver.swipe(X, 0, X, deviceHeight, Constants.SWIPE_SPEED_FAST);
}