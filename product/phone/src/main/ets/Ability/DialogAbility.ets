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
import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import Want from '@ohos.app.ability.Want';

/* instrument ignore file */
const TAG: string = 'DialogAbility';

export default class DialogAbility extends UIExtensionAbility {
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();

  onCreate() {
    LogUtil.info(TAG, `UIExtAbility onCreate`);
    this.globalThisInstance.setObject('UserChoice', 'false');
  }

  onForeground() {
    LogUtil.info(TAG, `UIExtAbility onForeground`);
  }

  onBackground() {
    LogUtil.info(TAG, `UIExtAbility onBackground`);
  }

  async onDestroy() {
    LogUtil.info(TAG, `UIExtAbility onDestroy`);
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    this.globalThisInstance!.setObject('privacyDialogContext', this.context);
    this.globalThisInstance!.setObject('privacyDialogWant', want);
    this.globalThisInstance!.setObject('privacySession', session);
    let param: Record<string, UIExtensionContentSession> = {
      'session': session
    }
    let storage: LocalStorage = new LocalStorage(param);
    try {
      session.loadContent('pages/DialogPage', storage);
    } catch (err) {
      LogUtil.error(TAG, `session loadContent error: ${err?.message}`)
    }
    session.setWindowBackgroundColor('#00ffffff');
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    LogUtil.info(TAG, `UIExtAbility onSessionDestroy`)
  }
}

