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
import { Configuration } from '@ohos.app.ability.Configuration';
import ServiceExtensionAbility from '@ohos.app.ability.ServiceExtensionAbility';
import Want from '@ohos.app.ability.Want';
import ExtAbilityProxy from '../proxy/ExtAbilityProxy';

const TAG = 'ServiceExtAbility';


export default class ServiceExtAbility extends ServiceExtensionAbility {
  protected proxy: ExtAbilityProxy | undefined = undefined;

  async onCreate(): Promise<void> {
    LogUtil.warn(TAG, 'ServiceExtAbility onCreate');
    this.proxy = new ExtAbilityProxy(this.context);
    await this.proxy.onCreate();
  }

  /**
   * 发起录屏
   */
  async onRequest(want: Want): Promise<void> {
    LogUtil.info(TAG, 'onRequest');
    this.startRequest(want);
  }

  /**
   * 发起录屏
   */
  async startRequest(want: Want): Promise<void> {
    LogUtil.info(TAG, 'startRequest');
    await this.proxy?.onRequest(want, undefined, false);
  }

  async onDestroy(): Promise<void> {
    LogUtil.warn(TAG, 'ServiceExtAbility onDestroy');
    await this.proxy?.onDestroy();
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    this.proxy?.onConfigurationUpdate(newConfig);
  }
};