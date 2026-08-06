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
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

/* instrument ignore file */
export enum FontSizeMode {
  SMALL = 0,
  MEDIUM,
  LARGE
}

export enum FontSizeScale {
  SMALL = 0.85,
  DEFAULT = 1,
  LARGE = 1.15,
  LARGE_EX = 1.3,
  LARGEST = 1.45
}

/**
 * 系统显示相关设置项
 */
export class SystemConfig {
  // 系统色彩模式
  public static colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
  // 系统字体大小
  public static fontSizeScale: number = 1;
  // PC上字体大于1.15倍为大字体,小于1倍则为小字体
  public static readonly bigFontSizeMinScale: number = 1.2;
  public static fontSizeMode: FontSizeMode = FontSizeMode.SMALL;
  public static isWindowType: boolean = true;

  public static updateDisplayConfig(context: common.ServiceExtensionContext, isWindowType: boolean = true): void {
    let config = context.config;
    SystemConfig.isWindowType = isWindowType;
    SystemConfig.colorMode = config.colorMode ?? ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    SystemConfig.fontSizeScale = config.fontSizeScale ?? SystemConfig.fontSizeScale;
    let fontMode = FontSizeMode.MEDIUM;
    if (SystemConfig.fontSizeScale > SystemConfig.bigFontSizeMinScale) {
      fontMode = FontSizeMode.LARGE;
    } else if (SystemConfig.fontSizeScale < 1) {
      fontMode = FontSizeMode.SMALL;
    }
    SystemConfig.fontSizeMode = fontMode;
  }

  /**
   * 是否是深色模式
   * @returns
   */
  public static isDark(): boolean {
    return SystemConfig.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  public static isRTL(): boolean {
    try {
      return i18n.isRTL(i18n.getSystemLocale());
    } catch (e) {
      LogUtil.error(`Get RTL failed, errMessage is ${(e as BusinessError).message}`);
      return false;
    }
  }
}