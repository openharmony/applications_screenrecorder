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

import display from '@ohos.display';
import { BusinessError } from '@ohos.base';
import { LogUtil } from './LogUtil';

const TAG: string = 'DisplayUtil';
const BASE_DPI: number = 160;

/**
 * Display Util
 *
 * @since 2025-04-23
 */
export class DisplayUtil {
  /**
   * Convert the value in unit of vp to px.
   *
   * The api named 'vp2px' provided by the framework cannot be used in the TS file, so we need this function.
   * The function is applicable only to TS file.
   * For UI components or pages, use vp2px provided by the framework.
   *
   * @param { number } vpValue Value in the unit of vp
   * @param { number } deviceDpi DPI of the device, which can be obtained from the display object.
   * @return { number } vpValue Value in the unit of px
   */
  static vp2pxInTs(vpValue: number, deviceDpi: number): number {
    return vpValue * deviceDpi / BASE_DPI;
  }

  /**
   * Convert the value in unit of px to vp.
   *
   * The api named 'vp2px' provided by the framework cannot be used in the TS file, so we need this function.
   * The function is applicable only to TS file.
   * For UI components or pages, use vp2px provided by the framework.
   *
   * @param { number } pxValue Value in the unit of vp
   * @return { number } pxValue Value in the unit of vp
   */
  static px2vpInTs(pxValue: number): number {
    try {
      let displays: display.Display = display.getPrimaryDisplaySync();
      if (displays.densityPixels === 0) {
        return 0;
      }
      return pxValue / displays.densityPixels;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(TAG, `px2vpInTs displays failed: ${err.code}: ${err.message}`);
      return 0;
    }
  }

  /**
   * Format formula to add separator
   *
   * @param { string } target formula string
   * @return { string } Whether value is legal formula tail.
   */
  static formatAddSeparator(target: string): string {
    let result: string = target?.toString().replace(/\.?[0-9\.\E]+/g, (str) => {
      return this.numberAddSeparator(str);
    });
    return result;
  }

  /**
   * number formula to add separator
   *
   * @param { string } target formula string
   * @return { string } Whether value is legal formula tail.
   */
  static numberAddSeparator(number: string): string {
    if (number.substring(0, 1) !== '.') {
      return number?.replace(/\d+/, (subStr) => {
        return subStr?.replace(/(\d)(?=(\d{3})+$)/g, ($1) => {
          return $1 + ',';
        });
      });
    } else {
      return number;
    }
  }

  /**
   * Check whether value is legal formula tail.
   *
   * @param { string } target formula string
   * @return { boolean } Whether value is legal formula tail.
   */
  static isLegalFormulaTail(target: string): boolean {
    let pattern: RegExp = /^([1-9][\d]*|0?)(\.\d{0,})?(E[+-]?\d+)?$/;
    let tailStr: string = target?.match(/[0-9\.]+(E[+-]?\d+)?/g)?.pop();
    return pattern.test(tailStr);
  }

  /**
   * Check whether value is digit.
   *
   * @param { string } target string
   * @return { boolean } Whether value is digit.
   */
  static isDigit(target: string): boolean {
    let pattern: RegExp = /^\d{1}$/;
    return pattern.test(target);
  }

  /**
   * Check whether value is number.
   *
   * @param { string } target string
   * @return { boolean } Whether value is number.
   */
  static isNumber(target: string): boolean {
    let pattern: RegExp = /^-?\d+(\.)?(\d+)?(E-?\d+)?([+]|-|÷|×)?$/;
    return pattern.test(target);
  }

  /**
   * Check whether value is number.
   *
   * @param { string } target string
   * @return { boolean } Whether value is number.
   */
  static isNumberOrFloat(target: string): boolean {
    let pattern: RegExp = /^-?(\d+)?(\.)?(\d+)?$/;
    return pattern.test(target);
  }

  static isNumberOrPoint(target: string): boolean {
    let pattern: RegExp = /^(\d+)?(\.)?$/;
    return pattern.test(target);
  }

  /**
   * 检查是不是大数.
   *
   * @param { string }
   * @return { boolean }
   */
  static isBigNumber(target: string): boolean {
    let pattern: RegExp = /^-?(\d+)\.?(\d+)?[E][+-]?(\d+)?$/;
    return pattern.test(target);
  }

  /**
   * 检查是不是在零之前
   *
   * @param { string }
   * @return { boolean }
   */
  static checkFrontZero(target: string): boolean {
    let pattern: RegExp = /^\-?0+\d+\.?/;
    return pattern.test(target);
  }
}