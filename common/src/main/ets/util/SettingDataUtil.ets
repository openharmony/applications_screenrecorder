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
import { settings } from '@kit.BasicServicesKit';
import { LogUtil } from './LogUtil';
import { StringUtil } from './StringUtil';

const TAG: string = 'SettingUtil';

/**
 * setting 数据库工具类
 */
export class SettingDataUtil {
  /**
   * 同步获取setting数据库数据
   *
   * @param context 应用上下文
   * @param key 字段key值
   * @param defaultValue 获取不到对应值时默认值
   * @param domain 对应所要查询的域名称
   * @returns 查询到的值
   */
  public static getSettingsDataSync(context: Context, key: string, defaultValue: string, domain?: string): string {
    if (StringUtil.isEmpty(key)) {
      LogUtil.warn(TAG, 'key is empty');
      return '';
    }

    try {
      if (domain) {
        return settings.getValueSync(context, key, defaultValue, domain);
      }
      return settings.getValueSync(context, key, defaultValue ?? '');
    } catch (err) {
      LogUtil.error(TAG, `getValueSync failed, key: ${key}, error message: ${err?.message}`)
    }
    return defaultValue ?? '';
  }

  /**
   * 同步向setting数据库存储或更新字段值
   *
   * @param context 应用上下文
   * @param key 字段key值
   * @param value 值
   * @param domain 对应所要存储的域名称
   * @returns 是否设置成功
   */
  public static setSettingDataSync(context: Context, key: string, value: string, domain?: string): boolean {
    if (StringUtil.isEmpty(key)) {
      LogUtil.error(TAG, 'key is empty');
      return false;
    }
    try {
      if (domain) {
        settings.setValueSync(context, key, value, domain);
      } else {
        settings.setValueSync(context, key, value);
      }
      return true;
    } catch (err) {
      LogUtil.error(TAG, `setValueSync failed, key: ${key}, error message: ${err?.message}`)
    }
    return false;
  }
}

