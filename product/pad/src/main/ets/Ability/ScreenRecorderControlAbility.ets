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
import { COLOR_TRANSPARENT } from '@ohos/screen-recorder';
import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import Want from '@ohos.app.ability.Want';

/* instrument ignore file */
const TAG: string = 'ScreenRecorderControlAbility';
const SCENEBOARD_NAME = 'com.ohos.sceneboard';

export default class ScreenRecorderControlAbility extends UIExtensionAbility {
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();

  async onCreate() {
    this.globalThisInstance!.setObject('screenRecorderControlContext', this.context);
    LogUtil.info(TAG, `UIExtAbility onCreate`);
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
    // want校验,仅支持控制中心拉起
    LogUtil.info(TAG, `UIExtAbility onSessionCreate`);
    if (!this.isControlCenterInvocation(want)) {
      LogUtil.error(TAG, 'Only the control center can invoke this interface.');
      return;
    }
    this.globalThisInstance!.setObject('screenRecorderControlSession', session);
    this.globalThisInstance!.setObject('screenRecorderControlWant', want);
    let param: Record<string, UIExtensionContentSession> = {
      'session': session
    }
    let storage: LocalStorage = new LocalStorage(param);
    try {
      session.loadContent('pages/ScreenRecorderControlPage', storage);
      session.setWindowBackgroundColor(COLOR_TRANSPARENT);
    } catch (e) {
      LogUtil.info(TAG, `session.loadContent error: ${e.code}`);
    }
  }

  isControlCenterInvocation(want: Want) {
    if (want.parameters?.['ohos.aafwk.param.callerBundleName'] === SCENEBOARD_NAME) {
      return true;
    }
    return false;
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    LogUtil.info(TAG, `UIExtAbility onSessionDestroy`);
  }
}