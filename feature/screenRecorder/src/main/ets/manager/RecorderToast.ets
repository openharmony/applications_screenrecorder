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

import { GlobalThisUtil, LogUtil, } from '@ohos/common';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

const TAG = 'RecorderToast';

/**
 * Toast管理类
 */
export class RecorderToast {
  private static instance: RecorderToast = new RecorderToast();
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();

  static getInstance(): RecorderToast {
    return RecorderToast.instance;
  }

  showToast(resName: string, mode: promptAction.ToastShowMode = 2) {
    // 获取上下文对象
    const context = this.globalThisInstance.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    try {
      // 构建请求参数
      const wantData: Want = {
        bundleName: 'com.ohos.screenrecorder',
        abilityName: 'com.ohos.screenrecorder.ToastExtensionAbility',
        parameters: {
          resName,
          mode
        }
      };
      // 启动Ability
      context.startAbility(wantData);
    } catch (e) {
      LogUtil.error(TAG, `show toast failed: ${e}`);
    }
  }
}