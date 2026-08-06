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
import window from '@ohos.window';

const TAG = 'WindowTestUtil';

/**
 * Test util
 *
 * @since 2023-07-15
 */
export class TestUtil {

  /**
   * Check whether the window exists based on the window name.
   *
   * @param windowName The window name
   * @return Whether the window exists
   */
  public static isWindowHere(windowName: string): boolean {
    try {
      return !!window.findWindow(windowName);
    } catch (error) {
      LogUtil.error(TAG, 'Window not found:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * Get the position and size of the window.
   *
   * @param windowName The window name
   * @return The position and size of the window.If the value cannot be obtained, undefined is returned.
   */
  public static getWindowProperties(windowName: string): window.Rect | undefined {
    try {
      const windowObj = window.findWindow(windowName);
      const windowProperties = windowObj.getWindowProperties();
      return windowProperties.windowRect;
    } catch (error) {
      LogUtil.error(TAG, 'Window not found:', JSON.stringify(error));
      return undefined;
    }
  }
}