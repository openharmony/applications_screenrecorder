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
import { ServiceExtensionAbility, Want } from '@kit.AbilityKit';
import { GlobalThisUtil, LogUtil } from '@ohos/common';
import { COLOR_TRANSPARENT } from '@ohos/screen-recorder';
import windowManager from '@ohos.window';
import { JSON } from '@kit.ArkTS';
import media from '@ohos.multimedia.media';
import MediaExtends from '../mediaExtends/mediaExtends'

/* instrument ignore file */
const TAG = 'PrivacyControlAbility';
const TERMINATE_DELAY: number = 300;
const BIND_SHEET_DELAY: number = 50;
type Window = windowManager.Window;


/**
 * AVScreenCapture Notification Privacy Control Ability
 *
 * @since 2025-7-11
 */
export default class PrivacyControlAbility extends ServiceExtensionAbility {
  private privacyWindow?: Window;
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private captureSessionId: number = 0;

  onCreate() {
    LogUtil.info(TAG, 'PrivacyControlAbility onCreate');
  }

  async onRequest(want: Want, startId: number): Promise<void> {
    LogUtil.info(TAG, 'PrivacyControlAbility onRequest');
    if (!want) {
      LogUtil.error(TAG, 'want info is invalid');
      return;
    }
    try {
      if (want.parameters?.sessionId !== undefined) {
        this.captureSessionId = Number(want.parameters?.sessionId);
      }
      if (want.parameters?.terminateSelf === true) {
        LogUtil.info(TAG, `terminateSelf(${want.parameters?.terminateSelf}) id: ${this.captureSessionId}`);
        AppStorage.SetOrCreate<boolean | undefined>('bindSheetShow', false);
        LogUtil.info(TAG, 'set bindSheetShow false');
        await new Promise<number>(resolve => setTimeout(resolve, TERMINATE_DELAY));
        this.context.terminateSelf();
        return;
      }
      let privacyResult: string = await MediaExtends.getAVScreenCaptureConfigurableParameters(this.captureSessionId);
      LogUtil.info(TAG, `getAVScreenCaptureConfigurableParameters result: ${privacyResult}`);
      let privacyJson: object = JSON.parse(privacyResult) as object;
      this.globalThisInstance.setObject('privacyControlData', privacyJson);

      const windowConfig: windowManager.Configuration = {
        name: 'PrivacyControlWindow',
        windowType: windowManager.WindowType.TYPE_FLOAT,
        ctx: this.context
      };
      LogUtil.info(TAG, `PrivacyControlAbility set windowConfig`);
      this.privacyWindow = this.globalThisInstance.getObject('PrivacyBindSheet') as windowManager.Window;
      if (this.privacyWindow !== undefined) {
        LogUtil.info(TAG, `PrivacyControlAbility destroyWindow`);
        AppStorage.SetOrCreate<boolean | undefined>('bindSheetShow', false);
        LogUtil.info(TAG, 'set bindSheetShow before destroyWindow');
        await new Promise<number>(resolve => setTimeout(resolve, TERMINATE_DELAY));
        await this.privacyWindow?.destroyWindow();
        this.globalThisInstance.setObject('PrivacyBindSheet', undefined);
      }
      this.privacyWindow = await windowManager.createWindow(windowConfig);
      this.privacyWindow.setSystemAvoidAreaEnabled(true);
      await this.privacyWindow.setUIContent('pages/PrivacyControlPage');
      LogUtil.info(TAG, `PrivacyControlAbility createWindow success`);
      this.privacyWindow.setWindowBackgroundColor(COLOR_TRANSPARENT);
      this.globalThisInstance.setObject('PrivacyBindSheet', this.privacyWindow);
      this.globalThisInstance.setObject('privacyControlWant', want);
      AppStorage.SetOrCreate<boolean | undefined>('bindSheetShow', false);
      await new Promise<number>(resolve => setTimeout(resolve, BIND_SHEET_DELAY));
      await this.privacyWindow.showWindow();
      await new Promise<number>(resolve => setTimeout(resolve, BIND_SHEET_DELAY));
      AppStorage.SetOrCreate<boolean | undefined>('bindSheetShow', true);
    } catch (err) {
      LogUtil.error(TAG, `PrivacyControlAbility error: ${err.message}`);
    }
  }

  onDestroy() {
    LogUtil.info(TAG, 'PrivacyControlAbility onDestroy');
  }

  onConfigurationUpdate() {
    LogUtil.info(TAG, 'PrivacyControlAbility onConfigurationUpdate');
  }
}