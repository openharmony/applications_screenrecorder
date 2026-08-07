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
import { Want } from '@kit.AbilityKit';
import { uiExtension, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';

const TAG: string = 'UIExtAbility:';
// instrument ignore file
export default class UIExtAbility extends UIExtensionAbility {
  private extensionWindow: uiExtension.WindowProxy | null = null;

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    LogUtil.info(TAG, 'UIExtAbility onSessionCreate');
    let storage: LocalStorage = new LocalStorage({
      'session': session,
    } as Record<string, Object>);
    if (this.context?.config?.fontSizeScale != null) {
      AppStorage.setOrCreate('fontSizeScale', this.context.config.fontSizeScale);
    }
    if (want && want.uri !== '') {
      session.loadContent(want.uri, storage);
    }
    try {
      session?.setReceiveDataCallback((data) => {
        AppStorage.setOrCreate<boolean>('hideBackButton', data['hideBackButton'] as boolean);
        AppStorage.setOrCreate('navigationMode', data['navigationMode']);
      });
    } catch (error) {
      LogUtil.error(TAG, `UIExtAbility onSessionCreate error: ${error}`);
    }
    if (want != undefined && want.parameters != undefined) {
      const startReason = want.parameters['startReason'];

      if (typeof startReason !== 'undefined' && startReason == 'from_search') {
        AppStorage.setOrCreate('routerType', true);
        LogUtil.info(TAG, 'routerType:  true');
      } else {
        AppStorage.setOrCreate('routerType', false);
        LogUtil.info(TAG, 'routerType:  false');
      }
    } else {
      LogUtil.info(TAG, 'want or parameters is undefined');
    }

    this.extensionWindow = session.getUIExtensionWindowProxy();
    try {
      // 注册避让区变化的监听
      this.extensionWindow?.on('avoidAreaChange', (info: uiExtension.AvoidAreaInfo) => {
        let type = info.type;
        if (type === window.AvoidAreaType.TYPE_SYSTEM) {
          AppStorage.setOrCreate('avoidAreaHeight', px2vp(info.area.topRect.height));
          LogUtil.info(TAG, `avoidAreaHeight: ${JSON.stringify(px2vp(info.area.topRect.height))}.`);
        }
      });
    } catch (error) {
      LogUtil.error(TAG, 'onSessionCreate avoidAreaChange error  : ' + (error as BusinessError).message);
    }
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    LogUtil.info(TAG, 'UIExtAbility onSessionDestroy');
    try {
      // 注销所有避让区变化的监听
      this.extensionWindow?.off('avoidAreaChange');
    } catch (error) {
      LogUtil.error(TAG, 'onSessionDestroy avoidAreaChange error  : ' + (error as BusinessError).message);
    }
  }
}