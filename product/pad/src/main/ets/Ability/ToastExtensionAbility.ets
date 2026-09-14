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

import { GlobalThisUtil, LogUtil, StringUtil } from '@ohos/common';
import common from '@ohos.app.ability.common';
import ServiceExtensionAbility from '@ohos.app.ability.ServiceExtensionAbility';
import promptAction from '@ohos.promptAction';

const TAG = 'ToastExtensionAbility';

export default class ToastExtensionAbility extends ServiceExtensionAbility {
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();

  private parseWantWholeTokenInt(value: Object | undefined | null, defaultValue: number): number {
    if (typeof value === 'number' && Number.isFinite(value)) {
      return value;
    }
    const valueText: string = String(value ?? '');
    if (/^\d+$/.test(valueText)) {
      return Number.parseInt(valueText, 10);
    }
    return defaultValue;
  }

  async onRequest(want: Want): Promise<void> {
    LogUtil.info(TAG, `toast extension ability start.`)
    const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    let resName = want?.parameters?.resName?.toString();
    let mode = this.parseWantWholeTokenInt(want?.parameters?.mode, 0);
    promptAction.showToast({
      message: StringUtil.getStringByNameSync(resName, context),
      showMode: mode
    });
  }

  onCreate(): void {
    this.globalThisInstance!.setObject('toastContext', this.context);
  }

  async onDestroy(): Promise<void> {
    this.globalThisInstance!.setObject('toastContext', undefined);
    LogUtil.info(TAG, `toast extension ability destroy.`)
  }
}