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
import { BusinessError } from '@kit.BasicServicesKit';
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';

const TAG = 'ShareUIAbility';

export default class ShareUIAbility extends UIAbility {
  private startWant?: Want;

  onCreate(want: Want): void {
    LogUtil.info(TAG, 'ShareUIAbility onCreate');
    this.startWant = want;
    GlobalThisUtil.getInstance()!.setObject('shareUIAbilityContext', this.context);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    LogUtil.info(TAG, 'ShareUIAbility onWindowStageCreate');
    try {
      windowStage.loadContent('pages/EmptyPage', (err) => {
        if (err.code) {
          LogUtil.error(TAG, 'Failed to load content. Cause: ' + err.message);
          this.cleanupAndTerminate();
          return;
        }
        windowStage.getMainWindow((err, data) => {
          if (err.code) {
            LogUtil.error(TAG, 'Failed to obtain the window. Cause: ' + err.message);
            this.cleanupAndTerminate();
            return;
          }
          let mainWindow: window.Window = data;
          mainWindow.setWindowBackgroundColor('#00000000');
          mainWindow.setWindowDecorVisible(false);
          this.showSharePanel();
        });
      });
    } catch (error) {
      LogUtil.error(TAG, 'onWindowStageCreate error: ' + (error as BusinessError).message);
      this.cleanupAndTerminate();
    }
  }

  /**
   * 分享功能自行实现。当前仅作为空占位，启动后立即销毁。
   */
  private async showSharePanel(): Promise<void> {
    LogUtil.info(TAG, 'showSharePanel: share not implemented, terminate self');
    this.cleanupAndTerminate();
  }

  private cleanupAndTerminate(): void {
    GlobalThisUtil.getInstance()!.setObject('shareUIAbilityContext', undefined);
    GlobalThisUtil.getInstance()!.setObject('isShareWindowExisting', false);
    this.context.terminateSelf();
  }

  onDestroy(): void {
    LogUtil.info(TAG, 'ShareUIAbility onDestroy');
  }
};
