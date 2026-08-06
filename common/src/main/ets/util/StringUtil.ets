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

import { LogUtil } from './LogUtil';

const TAG = 'StringUtil';

/**
 * 字符串工具类
 */
export class StringUtil {
  /**
   * 通过context获取字符串值
   *
   * @param name 字符串key值
   * @param context 上下文对象
   * @param args 格式化字符串的参数
   * @returns 结果
   */
  public static getStringByNameSync(name: string, context: Context, ...args: Array<string | number>): string {
    let result = '';
    try {
      result = context.resourceManager.getStringByNameSync(name, ...args);
    } catch (err) {
      LogUtil.error(TAG, `getStringByNameSync failed, name: ${name}, err: ${err}`);
    }
    return result;
  }

  /**
   * 判断字符串是否为空
   *
   * @param value 需要判断字符串值
   * @returns 判断结果
   */
  public static isEmpty(value: string): boolean {
    return value === null || value === undefined || value.length === 0;
  }
}