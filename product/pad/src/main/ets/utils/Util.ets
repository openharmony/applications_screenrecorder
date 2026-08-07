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
import { systemParameterEnhance } from '@kit.BasicServicesKit';
import deviceInfo from '@ohos.deviceInfo';

const TAG = 'CommonUtil';
const DEVICE_TYPE_PC = '2in1';
/**
 * Common Util
 *
 * @since 2025-07-07
 */
export class Util {

  static checkIfInPcModel(): boolean {
    try {
      return systemParameterEnhance.getSync('persist.sceneboard.ispcmode', 'false') === 'true';
    } catch (e) {
      LogUtil.error(TAG, 'Get pc mode switch failed');
      return false;
    }
  }

  static checkIfDeviceIsPC(): boolean {
    LogUtil.info(TAG, 'checkIfDeviceIsPC deviceInfo.deviceType: ' + deviceInfo.deviceType);
    return deviceInfo.deviceType === DEVICE_TYPE_PC;
  }
}