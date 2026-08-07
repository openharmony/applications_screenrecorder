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

import { bundleManager } from '@kit.AbilityKit';
import { accessibility } from '@kit.AccessibilityKit';
import { display } from '@kit.ArkUI';
import { BusinessError, settings, systemParameterEnhance } from '@kit.BasicServicesKit';
import { media } from '@kit.MediaKit';
import deviceInfo from '@ohos.deviceInfo';
import systemParameter from '@ohos.systemParameterEnhance';
import { GlobalThisUtil } from './GlobalThisUtil';
import { SettingDataUtil } from './SettingDataUtil'

import { LogUtil } from './LogUtil';

const TAG = 'Common_Util';
const DEVICE_TYPE_PHONE = 'phone';
const DEVICE_TYPE_TABLET = 'tablet';
const DEVICE_TYPE_PC = '2in1';
const DEVICE_TYPE_TV = 'tv';
const DEVICE_TYPE_CAR = 'car';
const FOLD_PRODUCT_TYPE = 'const.window.foldscreen.type';
const DEFAULTS_FOLD_TYPE = '0,0,0,0';
const PKG_NAME = 'com.ohos.screenrecorder';

export const enum FoldPhoneTypeValue {
  INVALID_VALUE = -1,
  STRAIGHT = 0,
  LARGE_FOLD = 1,
  SMALL_FOLD = 2,
  EXTERNAL_FOLD = 3,
  EXPANDING_NEX_FORMS = 4,
  LARGE_FOLD_NEW_FORMS = 7,
}

/**
 * Common Util
 *
 * @since 2022-11-07
 */
export class CommonUtil {

  /**
   * Check whether the current device is a mobile phone.
   *
   * @return Whether the current device is a mobile phone.
   */
  static checkIfDeviceIsPhone(): boolean {
    return deviceInfo.deviceType === DEVICE_TYPE_PHONE;
  }

  static checkIfDeviceIsCar(): boolean {
    return deviceInfo.deviceType === DEVICE_TYPE_CAR;
  }

  static checkNeedNotification(): boolean {
    return (deviceInfo.deviceType === DEVICE_TYPE_PHONE || deviceInfo.deviceType === DEVICE_TYPE_TABLET ||
      deviceInfo.deviceType === DEVICE_TYPE_TV || deviceInfo.deviceType === DEVICE_TYPE_CAR) &&
      !CommonUtil.checkIfInPcModel();
  }

  static checkIfDeviceIsPC(): boolean {
    LogUtil.info(TAG, 'checkIfDeviceIsPC deviceInfo.deviceType: ' + deviceInfo.deviceType);
    return deviceInfo.deviceType === DEVICE_TYPE_PC || CommonUtil.checkIfInPcModel();
  }

  static checkIfDeviceIsTv(): boolean {
    LogUtil.info(TAG, 'checkIfDeviceIsTv deviceInfo.deviceType: ' + deviceInfo.deviceType);
    return deviceInfo.deviceType === DEVICE_TYPE_TV;
  }

  static checkIfDeviceIsTablet(): boolean {
    LogUtil.info(TAG, 'checkIfDeviceIsTablet deviceInfo.deviceType: ' + deviceInfo.deviceType);
    return deviceInfo.deviceType === DEVICE_TYPE_TABLET && !CommonUtil.checkIfInPcModel();
  }

  static checkIfInPcModel(): boolean {
    try {
      return systemParameterEnhance.getSync('persist.sceneboard.ispcmode', 'false') === 'true';
    } catch (e) {
      LogUtil.error(TAG, 'Get pc mode switch failed');
      return false;
    }
  }

  /**
   * 判断是否是TGR产品
   *
   * @returns 返回结果
   */
  static checkIfDeviceIsTgr(): boolean {
    LogUtil.info(TAG, 'checkIfDeviceIsTgr deviceInfo.productSeries: ' + deviceInfo.productSeries);
    return deviceInfo.productSeries === 'TGR';
  }

  static isFoldedDevice(): boolean {
    return display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_FOLDED;
  }

  static isExpandedDevice(): boolean {
    return display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_EXPANDED;
  }

  static isFoldableDevice(): boolean {
    return display.isFoldable();
  }

  static clearPreviewTimeout(): void {
    const previewTimeoutId = GlobalThisUtil.getInstance()!.getObject('previewTimeoutId') as number;
    if (previewTimeoutId !== undefined) {
      clearTimeout(previewTimeoutId);
      LogUtil.info(TAG, `clear timeout by id: ${previewTimeoutId}`);
      GlobalThisUtil.getInstance()!.setObject('previewTimeoutId', undefined);
    }
  }

  static checkIfDeviceNeedAvoidPot(): boolean {
    try {
      if (CommonUtil.checkIfDeviceIsPhone()) {
        if (!CommonUtil.isFoldableDevice()) {
          LogUtil.info(TAG, 'phone device and cannot fold');
          return true;
        }

        if (CommonUtil.isLargeInFoldProduct() && CommonUtil.isFoldedDevice()) {
          LogUtil.info(TAG, 'phone device and in large fold state, and need avoid pot');
          return true;
        }

        if (CommonUtil.isSingleDisplayPocketFoldDevice() && CommonUtil.isExpandedDevice()) {
          LogUtil.info(TAG, 'phone device and in small fold state, and need avoid pot');
          return true;
        }
      }
      return false;
    } catch (err) {
      LogUtil.error(TAG, 'checkIfDeviceNeedAvoidPot error:' + (err as BusinessError).message);
      return false;
    }
  }

  static IsNewExpandingFormsExternalDisplay(): boolean {
    try {
      if (CommonUtil.isSingleDisplayPocketFoldDevice() && CommonUtil.isFoldedDevice()) {
        LogUtil.info(TAG, 'judge external display in fold product: true');
        return true;
      } else {
        LogUtil.info(TAG, 'judge external display in fold product: false');
        return false;
      }
    } catch (err) {
      LogUtil.error(TAG, 'failed to judge external display in fold product:' + (err as BusinessError).message);
      return false;
    }
  }

  /**
   * broadcast some text in accessibility mode
   *
   * @param text: text need to be broadcast
   */
  static broadcastAccessibilityText(text: string, notInterrupt?: boolean): void {
    if (accessibility.isOpenAccessibilitySync()) {
      LogUtil.info(TAG, 'has open Accessibility')
      let eventInfo: accessibility.EventInfo = ({
        type: notInterrupt ? 'announceForAccessibilityNotInterrupt' : 'announceForAccessibility',
        bundleName: 'com.ohos.screenrecorder',
        triggerAction: 'common',
        textAnnouncedForAccessibility: text
      });

      accessibility.sendAccessibilityEvent(eventInfo).then(() => {
        LogUtil.info(TAG, 'Event on Accessible Broadcast Text has been sent');
      });
    }
  }

  /**
   * 当前是否处于无障碍屏幕阅读状态
   *
   * @returns 是否处于无障碍阅读状态
   */
  public static isScreenReaderEnabled(): boolean {
    let screenReaderEnabled = false;
    try {
      const context = GlobalThisUtil.getInstance()!.getObject('screenRecorderContext') as Context;
      screenReaderEnabled =
        !!Number(SettingDataUtil.getSettingsDataSync(context, 'accessibility_screenreader_enabled', '0'));
      LogUtil.info(TAG, `screenReaderEnabled: ${screenReaderEnabled}`);
    } catch (error) {
      LogUtil.error(TAG, `screenReaderEnabled failed: { code: ${error?.code}, message: ${error?.message}}`);
    }
    return screenReaderEnabled;
  }

  /**
   * 无障碍模式主动聚焦
   *
   * @param customId 组件id
   * @param bundleName 不传则默认设置包名
   */
  /* instrument ignore next */
  public static requestFocusAccessibilityWithBundleName(customId: string, bundleName?: string): void {
    const isOpenAccessibility: boolean = accessibility.isOpenAccessibilitySync();
    const isOpenTouchGuide: boolean = accessibility.isOpenTouchGuideSync();
    if (!isOpenAccessibility || !isOpenTouchGuide) {
      return;
    }
    let eventInfo: accessibility.EventInfo = {
      type: 'requestFocusForAccessibility',
      bundleName: bundleName ?? 'com.ohos.screenrecorder',
      triggerAction: 'common',
      customId,
    };

    try {
      accessibility.sendAccessibilityEvent(eventInfo, (err) => {
        if (err) {
          LogUtil.error(TAG, `sendAccessibilityEvent is failed, code:${err?.code} message:${err?.message}`);
          return;
        }
        LogUtil.info(TAG, `sendAccessibilityEvent is Succeeded, customId:${customId}`);
      });
    } catch (error) {
      LogUtil.error(TAG, `sendAccessibilityEvent catch failed, code:${error?.code} message:${error?.message}`);
    }
  }

  static getSystemParameter(name: string): string {
    let property: string = '';
    try {
      property = systemParameter.getSync(name);
    } catch (error) {
      LogUtil.error(TAG, `get systemParameter ${name} error, cause: ${(error as BusinessError).message}`);
    }
    LogUtil.info(TAG, `systemParameter ${name} is ${property}`);
    return property;
  }

  static sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  static checkOobeState(): boolean {
    // PC设备不存在OOBE流程，跳过检测。若后续有，需删除该判断逻辑
    if (CommonUtil.checkIfDeviceIsPC()) {
      LogUtil.info(TAG, 'PC device without OOBE, skip OOBE check');
      return false;
    }
    let isOobeState = false;
    try {
      const context = GlobalThisUtil.getInstance()!.getObject('screenRecorderContext') as Context;
      const deviceProvisioned =
        !!Number(SettingDataUtil.getSettingsDataSync(context, 'device_provisioned', '0'));
      const userSetupComplete =
        !!Number(SettingDataUtil.getSettingsDataSync(context, 'user_setup_complete', '0',
          settings.domainName.USER_SECURITY));
      const isOtaFinished =
        !!Number(SettingDataUtil.getSettingsDataSync(context, 'is_ota_finished', '1',
          settings.domainName.USER_SECURITY));
      isOobeState = !deviceProvisioned || !userSetupComplete || !isOtaFinished;
      LogUtil.info(TAG, `isOobeState: ${isOobeState}, deviceProvisioned: ${deviceProvisioned}, userSetupComplete:
        ${userSetupComplete}, isOtaFinished: ${isOtaFinished}`);
    } catch (error) {
      LogUtil.error(TAG, `checkOobeState failed: { code: ${error?.code}, message: ${error?.message}}`);
    }
    return isOobeState;
  }

  public static isSingleDisplayPocketFoldDevice(): boolean {
    return CommonUtil.getFoldProductType() === FoldPhoneTypeValue.EXPANDING_NEX_FORMS;
  }

  static isLargeInFoldProduct(): boolean {
    let phoneFoldType: FoldPhoneTypeValue = CommonUtil.getFoldProductType();
    return phoneFoldType === FoldPhoneTypeValue.LARGE_FOLD || phoneFoldType === FoldPhoneTypeValue.LARGE_FOLD_NEW_FORMS;
  }

  static getSystemParm(key: string, def: string): string {
    let result: string = '';
    try {
      result = systemParameterEnhance.getSync(key, def);
    } catch (e) {
      LogUtil.error('Get system parameter value failed: %{public}s', e);
    }
    return result;
  }

  static getFoldProductType(): FoldPhoneTypeValue {
    let productValue: string = CommonUtil.getSystemParm(FOLD_PRODUCT_TYPE, DEFAULTS_FOLD_TYPE);
    LogUtil.info(TAG, `productValue: ${productValue}`);
    const result: string[] = productValue?.split(',');
    if (result.length > 0) {
      const sFoldProductTypeValue = Number.parseInt(result[0]);
      return sFoldProductTypeValue;
    }
    return FoldPhoneTypeValue.INVALID_VALUE;
  }

  /**
   * 获取设备软编码支持的长边最大分辨率
   *
   * @param preset 录制视频类型
   * @returns 长边支持的最大分辨率
   */
  static async getAvailableEncoder(preset: number): Promise<number> {
    const recorder = await media.createAVRecorder();
    const videoType =
      preset === media.AVScreenCaptureRecordPreset.SCREEN_RECORD_PRESET_H264_AAC_MP4 ? 'video/avc' : 'video/hevc';
    let encoderInfo: media.EncoderInfo | undefined;
    let longSideMaxRate: number = 0;

    try {
      const encoderInfos = await recorder.getAvailableEncoder();
      encoderInfo = encoderInfos.find(info => info.mimeType === videoType);
      /* instrument ignore if */
      if (encoderInfo && encoderInfo.width && encoderInfo.height) {
        longSideMaxRate = Math.max(encoderInfo.width.max, encoderInfo.height.max);
      } else {
        LogUtil.warn(TAG, `No suitable encoder found for preset: ${preset}`)
      }
    } catch (err) {
      LogUtil.error(TAG, err);
    } finally {
      // Ensure the recorder is properly released
      if (recorder) {
        await recorder.release();
      }
    }
    return longSideMaxRate;
  }

  /**
   * 通知APS模块场景启动和结束
   * @param sceneName 场景名称，包括应用启动场景，应用退出场景等
   * @param state 状态 1表示启动 0表示结束
   */
  public static setApsScene(sceneName: string, state: number): void {
    try {
      // apsManager?.setScene(PKG_NAME, sceneName, state);
      LogUtil.info(`${sceneName} setApsScene: ${state}`);
    } catch (error) {
      LogUtil.error(`setApsScene error: ${error}`);
    }
  }

  /**
   * 判断是否为系统应用
   *
   * @param bundleName 应用的bundelName
   * @returns 是否为系统应用
   */
  public static isSystemApp(bundleName: string): boolean {
    let bundleFlags: bundleManager.BundleFlag = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
    let isSystemApp: boolean = false;
    try {
      let data: bundleManager.BundleInfo = bundleManager.getBundleInfoSync(bundleName, bundleFlags);
      isSystemApp = data.appInfo.systemApp;
      LogUtil.info(TAG, `getBundleInfo successfully isSystemApp:${isSystemApp} bundleName:${bundleName}`);
    } catch (err) {
      let message = (err as BusinessError).message;
      LogUtil.error(TAG, `getBundleInfo failed: ${message}`);
    }
    return isSystemApp;
  }
}