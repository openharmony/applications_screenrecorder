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

import { CommonUtil, EventReportUtil, GlobalThisUtil, LogUtil, UNKNOWN_REASON } from '@ohos/common';
import { RecordManager } from '@ohos/screen-recorder';
import { common } from '@kit.AbilityKit';
import { Configuration } from '@ohos.app.ability.Configuration';
import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';
import Want from '@ohos.app.ability.Want';
import { BusinessError } from '@ohos.base';
import display from '@ohos.display';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import screenLock from '@ohos.screenLock';


const TAG = 'ExtAbilityProxy';
const MULTIMODAL_INPUT_UID = 6696;
const SHELL_UID = 2000;
const SHELL_UID_ROOT = 0;
const FILENAME_MAX = 255;
const FILENAME_REGEX_CHECK: RegExp = new RegExp('[\\[\\]:?*"`\\\'{}\\\\|<>/]');
const FILENAME_SUFFIX = '.mp4';
const SCENEBOARD_NAME = 'com.ohos.sceneboard';
const SCREENRECORDER_NAME = 'com.ohos.screenrecorder';

export default class ExtAbilityProxyUtil {
  private static globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private context: common.ServiceExtensionContext;

  constructor(context: common.ServiceExtensionContext) {
    this.context = context;
  }

  initData(): void {
    ExtAbilityProxyUtil.globalThisInstance!.setObject('screenRecorderContext', this.context);
    ExtAbilityProxyUtil.globalThisInstance!.setObject('windowId', 0);
    ExtAbilityProxyUtil.globalThisInstance!.setObject('preWindowId', 0);
    ExtAbilityProxyUtil.globalThisInstance!.setObject('isPreViewWindowExisting', false);
    ExtAbilityProxyUtil.globalThisInstance!.setObject('previewTimeoutId', undefined);
    ExtAbilityProxyUtil.globalThisInstance!.setObject('darkMode', this.context.config.colorMode);
    ExtAbilityProxyUtil.globalThisInstance!.setObject('isMicClicked', false);
    ExtAbilityProxyUtil.globalThisInstance!.setObject('isTrackClicked', false);
    AppStorage.SetOrCreate<boolean>('isDarkMode',
      this.context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    AppStorage.SetOrCreate<String | undefined>('languageCode', this.context.config.language);
  }

  static checkAbilityPermission(want: Want): boolean {
    if (!want?.parameters?.['ohos.aafwk.param.callerBundleName']) {
      let bundleUid = want?.parameters?.['ohos.aafwk.param.callerUid'] as number;
      return bundleUid === MULTIMODAL_INPUT_UID || bundleUid === SHELL_UID || bundleUid === SHELL_UID_ROOT;
    }
    let callerBundleName = want?.parameters?.['ohos.aafwk.param.callerBundleName'];
    if (typeof callerBundleName === 'string' && CommonUtil.isSystemApp(callerBundleName)) {
      return callerBundleName === SCENEBOARD_NAME || callerBundleName === SCREENRECORDER_NAME;
    }
    return false;
  }

  static isNeedStopRequest(): boolean {
    const isProcessing = ExtAbilityProxyUtil.globalThisInstance!.getObject('isProcessing') as boolean;
    let isOobeState: boolean = CommonUtil.checkOobeState();
    let isLocked: boolean = screenLock.isLocked();
    let isInStartupAnimation: boolean = CommonUtil.getSystemParameter('bootevent.boot.completed') !== 'true';
    LogUtil.info(TAG,
      `isProcessing: ${isProcessing}, isOobeState: ${isOobeState}, isLocked: ${isLocked}, isInStartupAnimation: ${isInStartupAnimation}`)
    return isProcessing || isOobeState || isLocked || isInStartupAnimation;
  }

  static needReSendNot(newConfig: Configuration): boolean {
    let result = false;
    LogUtil.info(TAG, 'onConfigurationUpdate:' + JSON.stringify(newConfig));

    const currentLanguage = AppStorage.Get<String>('languageCode');
    const currentFontSize = AppStorage.Get<Number>('fontSizeScaleCode');
    const currentDarkMode = ExtAbilityProxyUtil.globalThisInstance!.getObject('darkMode') as ConfigurationConstant.ColorMode;

    if (currentLanguage !== newConfig.language) {
      AppStorage.SetOrCreate<String | undefined>('languageCode', newConfig.language);
      LogUtil.info(TAG, 'Language changed', newConfig.language!);
      result = true;
    }

    if (currentFontSize !== newConfig.fontSizeScale) {
      AppStorage.SetOrCreate<Number | undefined>('fontSizeScaleCode', newConfig.fontSizeScale);
      LogUtil.info(TAG, 'fontSize changed: ' + newConfig.fontSizeScale);
    }

    if (currentDarkMode !== newConfig.colorMode) {
      ExtAbilityProxyUtil.globalThisInstance!.setObject('darkMode', newConfig.colorMode);
      AppStorage.SetOrCreate<boolean>('isDarkMode',
        newConfig.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
      LogUtil.info(TAG, 'DarkMode change to ' + newConfig.colorMode);
      result = true;
    }

    return result;
  }

  applyEfficiencyResources(): void {
    let request: backgroundTaskManager.EfficiencyResourcesRequest = {
      resourceTypes: backgroundTaskManager.ResourceType.CPU,
      isApply: true,
      timeOut: 0,
      reason: 'screenrecord',
      isPersist: true,
      isProcess: false,
    };
    backgroundTaskManager.applyEfficiencyResources(request);
    LogUtil.info(TAG, 'Succeeded in invoking applyEfficiencyResources.');
  }

  static checkFileName(name: string | undefined): boolean {
    if (name === undefined) {
      LogUtil.info(TAG, 'fileName is undefined');
      return true;
    }

    if (name.length > FILENAME_MAX) {
      LogUtil.error(TAG, 'fileName exceed max length');
      return false;
    }

    if (name.charAt(0) === '.') {
      LogUtil.error(TAG, 'fileName with illegal start');
      return false;
    }

    try {
      /* instrument ignore if */
      if (name.match(FILENAME_REGEX_CHECK)) {
        LogUtil.error(TAG, 'fileName illegal');
        return false;
      }

      if (!name.endsWith(FILENAME_SUFFIX)) {
        LogUtil.error(TAG, 'fileName with illegal end');
        return false;
      }
    } catch (err) {
      LogUtil.error(TAG, 'regex check error: ' + (err as BusinessError).message);
    }

    return true;
  }
};