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

import { screen } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { Configuration } from '@ohos.app.ability.Configuration';
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import media from '@ohos.multimedia.media';
import window from '@ohos.window';
import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';

import { GlobalThisUtil, LogUtil } from '@ohos/common';

/* instrument ignore file */
const TAG = 'SelectDialogAbility';
const ACTIVE = 2;

class JsonData {
  public choice: string = 'true'
  public displayId: number | null = -1
  public missionId: number | null = -1
  public checkBoxSelected: string = 'true'
}

export default class SelectDialogAbility extends UIAbility {
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();

  onCreate(want: Want): void {
    this.globalThisInstance!.setObject('selectContext', this.context);
    this.globalThisInstance!.setObject('selectWant', want);
    this.globalThisInstance!.setObject('isReportedToServer', false);
    AppStorage.setOrCreate<string | undefined>('currentLanguageCode', this.context.config.language);
    LogUtil.info(TAG, 'SelectDialogAbility onCreate');
  }

  onNewWant(want: Want): void {
    LogUtil.info(TAG, `SelectDialogAbility onNewWant start`);
    let oldWant = this.globalThisInstance!.getObject('selectWant') as Want;
    let oldSessionId = -1;
    let oldWantSessionId = oldWant?.parameters?.sessionId;
    if (oldWantSessionId !== undefined) {
      oldSessionId = Number(oldWantSessionId);
    }
    let newSessionId = -1;
    let newWantSessionId = want?.parameters?.sessionId;
    if (newWantSessionId !== undefined) {
      newSessionId = Number(newWantSessionId);
    }
    if (newSessionId !== oldSessionId) {
      LogUtil.info(TAG, 'new session start again');
      return;
    }
    let wantTerminateSelf = want?.parameters?.terminateSelf;
    LogUtil.info(TAG, `new want: terminateSelf: ${wantTerminateSelf}`);
    if (wantTerminateSelf !== undefined && wantTerminateSelf === true) {
      this.context.terminateSelf();
      return;
    }
    LogUtil.info(TAG, `SelectDialogAbility onNewWant end`);
  }

  onDestroy(): void {
    LogUtil.info(TAG, 'SelectDialogAbility onDestroy');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    LogUtil.info(TAG, 'onConfigurationUpdate:' + JSON.stringify(newConfig));
    const currentLanguage = AppStorage.get<string>('currentLanguageCode');
    LogUtil.info(TAG, `currentLanguage ${currentLanguage}`);
    if (currentLanguage !== newConfig.language) {
      AppStorage.setOrCreate<string | undefined>('currentLanguageCode', newConfig.language);
      LogUtil.info(TAG, 'Language changed', newConfig.language!);
    }
    if (newConfig.colorMode !== undefined) {
      this.updateBackground(newConfig.colorMode);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    try {
      // Main window is created, set main page for this ability
      LogUtil.info(TAG, 'SelectDialogAbility onWindowStageCreate');
      windowStage.loadContent('pages/SelectWindowPage', (err, data) => {
        if (err.code) {
          LogUtil.error(TAG, 'Failed to load the content. Cause:' + err.message);
          return;
        }

        windowStage.getMainWindow((err, data) => {
          if (err.code) {
            LogUtil.error(TAG, 'Failed to obtain the window. Cause: ' + err.message);
            return;
          }
          let windowClass: window.Window = data;
          windowClass.setSnapshotSkip(true);
          windowClass!.setWindowDecorVisible(false);
          // 目前需要设置为 [37-112] 范围内
          windowClass!.setWindowDecorHeight(56);
          this.globalThisInstance!.setObject('windowClass', windowClass);
          LogUtil.info(TAG, 'Succeeded to obtain the window.');
        });
        this.globalThisInstance!.setObject('windowLoadFirst', true);
        LogUtil.info(TAG, 'Succeeded in loading the content.');
      });
    } catch (error) {
      LogUtil.error(TAG, `onWindowStageCreate error: ${error.message}`);
    }
  }

  onWindowStageWillDestroy(windowStage: window.WindowStage): void {
    try {
      LogUtil.info(TAG, 'SelectDialogAbility onWindowStageWillDestroy');
    } catch (error) {
      LogUtil.error(TAG, `onWindowStageWillDestroy error: ${error.message}`);
    }
  }

  async onWindowStageDestroy(): Promise<void> {
    // Main window is destroyed, release UI related resources
    try {
      LogUtil.info(TAG, 'SelectDialogAbility onWindowStageDestroy');
      let userCheckBoxSelect = this.globalThisInstance!.getObject('userCheckBoxSelect') as string;
      LogUtil.info(TAG, `report user checkBoxSelected: ${userCheckBoxSelect}`);
      if (!this.globalThisInstance!.getObject('isReportedToServer')) {
        const jsonData: JsonData = {
          choice: 'false',
          displayId: -1,
          missionId: -1,
          checkBoxSelected: userCheckBoxSelect,
        }
        let want = this.globalThisInstance!.getObject('selectWant') as Want;
        let sessionId = -1;
        let wantSessionId = want?.parameters?.sessionId;
        if (wantSessionId !== undefined) {
          sessionId = Number(wantSessionId);
        }
        await media.reportAVScreenCaptureUserChoice(sessionId, JSON.stringify(jsonData));
      }
    } catch (err) {
      LogUtil.error(TAG, `reportAVScreenCaptureUserChoice error: ${err.message}`);
    }
  }

  onForeground(): void {
    // Ability has brought to foreground
    LogUtil.info(TAG, 'SelectDialogAbility onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    LogUtil.info(TAG, 'SelectDialogAbility onBackground');
  }

  private updateBackground(type: number | undefined): void {
    LogUtil.info(TAG, 'update window background color');
    try {
      let isColorModeDark: boolean = false;
      if (type === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
        isColorModeDark = true;
      }
      LogUtil.info(TAG, `isColorModeDark is: ${isColorModeDark}`);
      AppStorage.setOrCreate('isColorModeDark', isColorModeDark);
    } catch (err) {
      LogUtil.error(TAG, `updateBackground error: ${err.message}`);
    }
  }
};
