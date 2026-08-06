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
import { screen } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import { Configuration } from '@ohos.app.ability.Configuration';
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import media from '@ohos.multimedia.media';
import window from '@ohos.window';

/* instrument ignore file */
const TAG = 'SelectDialogAbility';
const ACTIVE = 2;

class JsonData {
  public choice: string = 'true'
  public displayId: number | null = -1
  public missionId: number | null = -1
  public checkBoxSelected: string = 'true'
  public isInnerAudioBoxSelected: string = 'true'
}

export default class SelectDialogAbility extends UIAbility {
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();

  async onCreate(want: Want): Promise<void> {
    this.globalThisInstance!.setObject('selectContext', this.context);
    this.globalThisInstance!.setObject('selectWant', want);
    this.globalThisInstance!.setObject('isReportedToServer', false);
    AppStorage.SetOrCreate<String | undefined>('currentLanguageCode', this.context.config.language);
    LogUtil.info(TAG, 'SelectDialogAbility onCreate');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    LogUtil.info(TAG, `SelectDialogAbility onNewWant start`);
    let oldWant = this.globalThisInstance!.getObject('selectWant') as Want;
    let oldSessionId = -1;
    if (oldWant.parameters?.sessionId !== undefined) {
      oldSessionId = Number(oldWant.parameters?.sessionId);
    }
    let newSessionId = -1;
    if (want?.parameters?.sessionId !== undefined) {
      newSessionId = Number(want?.parameters?.sessionId);
    }
    if (newSessionId !== oldSessionId) {
      LogUtil.info(TAG, 'new session start again');
      return;
    }
    if (want?.parameters?.terminateSelf !== undefined && want?.parameters?.terminateSelf === true) {
      LogUtil.info(TAG, `new want: terminateSelf: ${want?.parameters?.terminateSelf}`);
      this.context.terminateSelf();
      return;
    }
    LogUtil.info(TAG, `SelectDialogAbility onNewWant end`);
  }

  async onDestroy(): Promise<void> {
    LogUtil.info(TAG, 'SelectDialogAbility onDestroy');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    LogUtil.info(TAG, 'onConfigurationUpdate:' + JSON.stringify(newConfig));
    const currentLanguage = AppStorage.Get<String>('currentLanguageCode');
    LogUtil.info(TAG, `currentLanguage ${currentLanguage}`);
    if (currentLanguage !== newConfig.language) {
      AppStorage.SetOrCreate<String | undefined>('currentLanguageCode', newConfig.language);
      LogUtil.info(TAG, 'Language changed', newConfig.language!);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    try {
      // Main window is created, set main page for this ability
      LogUtil.info(TAG, 'SelectDialogAbility onWindowStageCreate');
      this.globalThisInstance!.setObject('selectWindowStage', windowStage);

      windowStage.loadContent('pages/SelectWindowPage', (err, data) => {
        if (err.code) {
          LogUtil.error(TAG, 'Failed to load the content. Cause:' + err.message);
          return;
        }
        this.globalThisInstance!.setObject('windowClass', undefined);
        windowStage.getMainWindow((err, data) => {
          if (err.code) {
            LogUtil.error(TAG, 'Failed to obtain the window. Cause: ' + err.message);
            return;
          }
          let windowClass: window.Window = data;
          this.globalThisInstance!.setObject('windowClass', windowClass);
          LogUtil.info(TAG, 'Succeeded to obtain the window.');
          windowClass!.setWindowDecorVisible(false);
          // 目前需要设置为 [37-112] 范围内
          windowClass!.setWindowDecorHeight(56);
        });
        this.globalThisInstance!.setObject('windowLoadFirst', true);
        LogUtil.info(TAG, 'Succeeded in loading the content.');
      });

      windowStage.on('windowStageEvent', (data) => {
        LogUtil.info(TAG, `current windowStage event: ${data}, ${data === ACTIVE}`);
        AppStorage.SetOrCreate<boolean | undefined>('isActive', data === ACTIVE);
      })
    } catch (error) {
      LogUtil.error(TAG, 'onWindowStageCreate error: ' + (error as BusinessError).message);
    }
  }

  onWindowStageWillDestroy(windowStage: window.WindowStage): void {
    try {
      windowStage.off('windowStageEvent');
      LogUtil.info(TAG, 'SelectDialogAbility onWindowStageWillDestroy');
    } catch (error) {
      LogUtil.error(TAG, 'onWindowStageWillDestroy error: ' + (error as BusinessError).message);
    }
  }

  async onWindowStageDestroy(): Promise<void> {
    // Main window is destroyed, release UI related resources
    LogUtil.info(TAG, 'SelectDialogAbility onWindowStageDestroy');
    let userCheckBoxSelect = this.globalThisInstance!.getObject('userCheckBoxSelect') as string;
    let userIsInnerAudioBoxSelected = this.globalThisInstance!.getObject('userIsInnerAudioBoxSelected') as string;
    LogUtil.info(TAG, 'report user checkBoxSelected: ' + userCheckBoxSelect);
    LogUtil.info(TAG, 'report user checkAudioSelected: ' + userIsInnerAudioBoxSelected);
    if (!this.globalThisInstance!.getObject('isReportedToServer')) {
      const jsonData: JsonData = {
        choice: 'false',
        displayId: -1,
        missionId: -1,
        checkBoxSelected: userCheckBoxSelect,
        isInnerAudioBoxSelected: userIsInnerAudioBoxSelected,
      }
      LogUtil.info(TAG, `onWindowStageDestroy jsonData ${jsonData}`);
      screen.off('connect');
      screen.off('disconnect');
      LogUtil.info(TAG, `Cancel the Add and Remove of Listening on the Display Device`);
      let want = this.globalThisInstance!.getObject('selectWant') as Want;
      let sessionId = -1;
      if (want.parameters?.sessionId !== undefined) {
        sessionId = Number(want.parameters?.sessionId);
      }
      try {
        await media.reportAVScreenCaptureUserChoice(sessionId, JSON.stringify(jsonData));
      } catch (error) {
        LogUtil.error(TAG, `reportAVScreenCaptureUserChoice error: ${error}`);
      }
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

};
