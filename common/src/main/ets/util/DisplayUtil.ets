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

import { display } from '@kit.ArkUI';
import { BusinessError, settings, systemParameter } from '@kit.BasicServicesKit';
import { Context } from '@ohos.arkui.UIContext';

import { LogUtil } from './LogUtil';
import { SettingDataUtil } from './SettingDataUtil';

const BASE_DPI = 160;
const TAG = 'Display_Util';
const FOLD_SCREEN_PRODUCT_PROPERTY = 'const.window.foldscreen.type';
const SMALL_FOLD_SCREEN_VALUE: string = '2,';
const SMALL_FOLD_SCREEN_VALUE_4: string = '4,';
const SMALL_FOLD_SCREEN_VALUE_7: string = '7,';
const THREE_FOLD_SCREEN_VALUE: string = '6,';

export enum DisplayId {
  /**
   * Hopper悬停态上半屏的display id；或者单屏的默认id。
   */
  DEFAULT = 0,
  /**
   * Hopper悬停态下半屏的display id
   */
  LOWER_OF_FOLD_DEVICE = 999,
  /**
   * 虚拟屏的最小display id
   */
  VIRTUAL_DISPLAY_MIN_ID = 1000,
}

export enum FoldDisplayMode {
  HALF_DISPLAY = 0,
  SINGLE_DISPLAY = 1,
  DUAL_DISPLAY = 2,
  THREE_DISPLAY = 3
}

/**
 * Display Util
 *
 * @since 2022-05-27
 */
export class DisplayUtil {
  /**
   * 折叠屏配置属性缓存
   */
  private static foldProductProperty: string | undefined = undefined;
  private static readonly FOLD_MAPPING_DISPLAY_MODE: Map<number, FoldDisplayMode> =
    new Map<number, FoldDisplayMode>([
      [display.FoldStatus.FOLD_STATUS_EXPANDED, FoldDisplayMode.DUAL_DISPLAY],
      [display.FoldStatus.FOLD_STATUS_FOLDED, FoldDisplayMode.SINGLE_DISPLAY],
      [display.FoldStatus.FOLD_STATUS_HALF_FOLDED, FoldDisplayMode.DUAL_DISPLAY],
      [display.FoldStatus.FOLD_STATUS_EXPANDED_WITH_SECOND_EXPANDED, FoldDisplayMode.THREE_DISPLAY],
      [display.FoldStatus.FOLD_STATUS_EXPANDED_WITH_SECOND_HALF_FOLDED, FoldDisplayMode.THREE_DISPLAY],
      [display.FoldStatus.FOLD_STATUS_FOLDED_WITH_SECOND_EXPANDED, FoldDisplayMode.SINGLE_DISPLAY],
      [display.FoldStatus.FOLD_STATUS_FOLDED_WITH_SECOND_HALF_FOLDED, FoldDisplayMode.SINGLE_DISPLAY],
      [display.FoldStatus.FOLD_STATUS_HALF_FOLDED_WITH_SECOND_EXPANDED, FoldDisplayMode.THREE_DISPLAY],
      [display.FoldStatus.FOLD_STATUS_HALF_FOLDED_WITH_SECOND_HALF_FOLDED, FoldDisplayMode.THREE_DISPLAY]
    ]);

  /**
   * Convert the value in unit of vp to px.
   *
   * The api named 'vp2px' provided by the framework cannot be used in the TS file, so we need this function.
   * The function is applicable only to TS file.
   * For UI components or pages, use vp2px provided by the framework.
   *
   * @param vpValue Value in the unit of vp
   * @param deviceDpi DPI of the device, which can be obtained from the display object.
   * @return vpValue Value in the unit of px
   */
  static vp2pxInTs(vpValue: number, deviceDpi: number): number {
    return vpValue * deviceDpi / BASE_DPI;
  }

  static isLandscapeMode(): boolean {
    try {
      return display.getDefaultDisplaySync().orientation === display.Orientation.LANDSCAPE_INVERTED;
    } catch (err) {
      LogUtil.error(TAG, 'isLandscapeMode get display fail, err: ' + (err as BusinessError).message);
      return false;
    }
  }

  static isLandscapeModeRtl(): boolean {
    try {
      return display.getDefaultDisplaySync().orientation === display.Orientation.LANDSCAPE;
    } catch (err) {
      LogUtil.error(TAG, 'isLandscapeModeRtl get display fail, err: ' + (err as BusinessError).message);
      return false;
    }
  }

  /**
   * 获取系统参数
   *
   * @param name 参数名
   * @returns 参数值
   */
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

  /**
   * Determine whether the current device is a small folding device
   *
   * @returns
   */
  public static isSmallFoldScreen(): boolean {
    let productProperty: string = DisplayUtil.getSystemParameter(FOLD_SCREEN_PRODUCT_PROPERTY);
    return productProperty.startsWith(SMALL_FOLD_SCREEN_VALUE) || productProperty.startsWith(SMALL_FOLD_SCREEN_VALUE_4);
  }

  /**
   * 判断是否是verde产品
   *
   * @returns 结果
   */
  public static isVerdeProducts(): boolean {
    let productProperty: string = DisplayUtil.getSystemParameter(FOLD_SCREEN_PRODUCT_PROPERTY);
    return productProperty.startsWith(SMALL_FOLD_SCREEN_VALUE_4);
  }

  /**
   * 判断是否是hope产品
   *
   * @returns 结果
   */
  public static isHopeProducts(): boolean {
    let productProperty: string = DisplayUtil.getSystemParameter(FOLD_SCREEN_PRODUCT_PROPERTY);
    return productProperty.startsWith(SMALL_FOLD_SCREEN_VALUE_7);
  }

  /**
   * 是否为折叠屏半展态
   *
   * @returns true 是，false 不是
   */
  public static isHalfFoldedState(): boolean {
    let isHalfFoldedState: boolean = false;
    try {
      isHalfFoldedState = display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_HALF_FOLDED;
    } catch (error) {
      LogUtil.error('isHalfFoldedState -> try error:', error);
    }
    return isHalfFoldedState;
  }

  /**
   * 是否是折叠屏展开态
   *
   * @returns 结果
   */
  static isExpandedStatus(): boolean {
    let result: boolean = false;
    try {
      result = display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_EXPANDED;
    } catch (err) {
      LogUtil.error(TAG, `getFoldStatus error, cause: ${(err as BusinessError)?.message}`);
    }
    return result;
  }

  /**
   * 是否是折叠屏折叠态
   *
   * @returns 结果
   */
  static isFoldedStatus(): boolean {
    let result: boolean = false;
    try {
      result = display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_FOLDED;
    } catch (err) {
      LogUtil.error(TAG, `getFoldStatus error, cause: ${(err as BusinessError)?.message}`);
    }
    return result;
  }

  /**
   * 获取屏幕折叠状态
   *
   * @returns 折叠状态
   */
  static getFoldStatus(): number {
    let result: number = display.FoldStatus.FOLD_STATUS_UNKNOWN;
    try {
      result = display.getFoldStatus();
    } catch (err) {
      LogUtil.error(TAG, `getFoldStatus error, cause: ${(err as BusinessError)?.message}`);
    }
    return result;
  }

  /**
   * 折叠状态发生变化监听注册
   *
   * @param callback 回调函数
   */
  public static registerFoldStatusChange(callback: (state: number) => void): void {
    try {
      /* instrument ignore else */
      if (!display.isFoldable()) {
        return;
      }
      display.on('foldStatusChange', callback);
    } catch (err) {
      LogUtil.error(TAG, `register foldStatusChange: code: ${err?.code} message: ${err?.message}`);
    }
  }

  /**
   * 校验设备是否是可折叠设备
   *
   * @returns 校验结果
   */
  public static checkDeviceIsFoldable(): boolean {
    try {
      return display.isFoldable();
    } catch (e) {
      LogUtil.error(TAG, 'get display foldable fail');
    }
    return false;
  }

  /**
   * 获取默认显示屏DPI
   *
   * @returns DPI
   */
  public static getDefaultDisplayDpi(): number {
    try {
      return display.getDefaultDisplaySync().densityDPI;
    } catch (e) {
      LogUtil.error(TAG, `get default display dpi fail: ${e}`);
    }
    return 0;
  }

  /**
   * 获取所有显示屏
   *
   * @returns 显示屏集合
   */
  public static async getAllDisplays(): Promise<display.Display[]> {
    try {
      return await display.getAllDisplays();
    } catch (e) {
      LogUtil.error(TAG, `get all display fail: ${e}`);
    }
    return [];
  }

  /**
   * 折叠状态变化监听销毁
   *
   * @param callback 回调函数
   */
  public static unRegisterFoldStatusChange(callback: (state: number) => void): void {
    try {
      /* instrument ignore else */
      if (!display.isFoldable()) {
        return;
      }
      display.off('foldStatusChange', callback);
    } catch (err) {
      LogUtil.error(TAG, `unregister foldStatusChange: code: ${err?.code} message: ${err?.message}`);
    }
  }

  /**
   * 是否是单手模式
   */
  public static isOneHandedMode(context: Context): boolean {
    let result: boolean = false;
    let singleHandMode: string =
      SettingDataUtil.getSettingsDataSync(context, 'single_hand_mode', '', settings.domainName.USER_PROPERTY);
    result = singleHandMode === 'left' || singleHandMode === 'right';
    LogUtil.info(TAG, `current handle model is: ${singleHandMode}`);
    return result;
  }

  /**
   * 获取设备折叠屏配置属性
   *
   * @returns 折叠屏配置属性
   */
  static getFoldProductProperty(): string {
    if (!DisplayUtil.foldProductProperty) {
      DisplayUtil.foldProductProperty = DisplayUtil.getSystemParameter(FOLD_SCREEN_PRODUCT_PROPERTY);
    }
    return DisplayUtil.foldProductProperty;
  }

  /**
   * 判断是否是三折叠
   *
   * @returns 结果
   */
  public static isThreeFoldScreen(): boolean {
    let productProperty: string = DisplayUtil.getFoldProductProperty();
    return productProperty.startsWith(THREE_FOLD_SCREEN_VALUE);
  }

  /**
   * 获取屏幕显示方式
   *
   * @returns 屏幕显示方式
   */
  public static getFoldDisplayMode(): FoldDisplayMode {
    if (!DisplayUtil.getIsFoldableInner()) {
      return FoldDisplayMode.SINGLE_DISPLAY;
    }
    if (DisplayUtil.isSmallFoldScreen()) {
      if (DisplayUtil.getFoldStatus() === display.FoldStatus.FOLD_STATUS_FOLDED) {
        return FoldDisplayMode.HALF_DISPLAY;
      }
      return FoldDisplayMode.SINGLE_DISPLAY;
    }
    let foldStatus = DisplayUtil.getFoldStatus();
    const displayMode: FoldDisplayMode | undefined = DisplayUtil.FOLD_MAPPING_DISPLAY_MODE.get(foldStatus);
    if (!displayMode) {
      return FoldDisplayMode.SINGLE_DISPLAY;
    }
    return displayMode;
  }

  /**
   * get device is foldable, no private for DT mock
   *
   * @returns device is foldable
   */
  static getIsFoldableInner(): boolean {
    let isFoldable = false;
    try {
      isFoldable = display.isFoldable();
    } catch (error) {
      LogUtil.error(TAG, `getFoldStatusInner error :${error?.message}`);
    }
    return isFoldable;
  }
}