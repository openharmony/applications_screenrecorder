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

import common from '@ohos.app.ability.common';
import dataPreferences from '@ohos.data.preferences';
import preferences from '@ohos.data.preferences';
import { GlobalThisUtil } from './GlobalThisUtil';
import { LogUtil } from './LogUtil';
import { SettingDataUtil } from './SettingDataUtil';
import { EventReportUtil } from './EventReportUtil';

const TAG = 'PreferencesUtil';
const PREFERENCES_NAME = 'myPreferences';

/**
 * The PreferencesUtil provides preferences of create, save and query.
 */
export class PreferenceUtils {
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private currentValue: preferences.ValueType | null = null;
  public touchState: boolean = true;

  /**
   * init preferences
   */

  // 判断是否有对应键值对并取值
  async loadPreferences(context: Context, key: string) {
    try {
      let preference = await this.getPreference(context);
      preference.has(key, (err, val) => {
        /* instrument ignore if */
        if (err) {
          LogUtil.error(TAG, `Failed to get value of ${key}. code: ${err.code}`);
          return;
        }
        if (val) {
          LogUtil.info(TAG, `The key ${key} is contained.`);
        } else {
          LogUtil.info(TAG, `The key ${key} dose not contained.`);
        }
      })
      preference.get(key, 'true', (err, val: dataPreferences.ValueType) => {
        /* instrument ignore if */
        if (err) {
          LogUtil.error(TAG, `Failed to get value of ${key}. code: ${err.code}`);
          return;
        }
        LogUtil.info(TAG, `Succeeded in getting value of ${key}. val：` + val);

        if (key === 'showTouchState') {
          this.touchState = val === 'true' ? true : false
          LogUtil.info(TAG, `this.touchState：${this.touchState}`);
          if (val === 'true') {
            let state: boolean = SettingDataUtil.setSettingDataSync(context, 'settings.input.show_touch_hint', 'true');
            LogUtil.info(TAG, `Set ShowTouch on ${state}`);
          } else {
            let state: boolean = SettingDataUtil.setSettingDataSync(context, 'settings.input.show_touch_hint', 'false');
            LogUtil.info(TAG, `Set ShowTouch off ${state}`);
          }
          EventReportUtil.reportTrackStateEvent(false);
        } else {
          this.globalThisInstance.setObject('currentValue', val);
        }
      })
    } catch (e) {
      LogUtil.info(TAG, `loadPreferences preference ${PREFERENCES_NAME} failed. code: ${e?.code}`);
    }
  }

  async getPreference(context: Context): Promise<dataPreferences.Preferences> {
    return await dataPreferences.getPreferences(context, PREFERENCES_NAME);
  }

  /**
   * Obtains the value of a preferences in the ValueType format.
   *
   * @param { Context } context - Indicates the context of application or capability.
   * @param { string } key - Indicates the key of the preferences. It cannot be {@code null} or empty.
   *         <tt>MAX_KEY_LENGTH</tt>.
   * @param { preferences.ValueType } defaultValue - Indicates the default value to return.
   * @param { AsyncCallback<ValueType> } callback - The value matching the specified key if it is found;
   *        returns the default value otherwise.
   */
  async getPreferencesValueByKey(context: Context, key: string, defaultValue: preferences.ValueType,
    callback: (result: preferences.ValueType) => void) {
    try {
      dataPreferences.removePreferencesFromCacheSync(context, PREFERENCES_NAME);
      dataPreferences.getPreferences(context, PREFERENCES_NAME).then((preference: dataPreferences.Preferences) => {
        preference.get(key, defaultValue).then((val: dataPreferences.ValueType) => {
          try {
            callback(val);
            LogUtil.info(TAG, `Succeeded in getting value of ${key}. val：` + val);
          } catch (e) {
            LogUtil.error(TAG, `getValue execute callback failed. code: ${e?.code}, message: ${e?.message}`);
            callback(defaultValue);
          }
        }).catch((err: BusinessError) => {
          LogUtil.error(TAG, `Failed to get value of ${key}. code: ${err?.code}`);
          callback(defaultValue);
        })
      }).catch((e: BusinessError) => {
        LogUtil.error(TAG,
          `getPreferences preference ${PREFERENCES_NAME} failed. code: ${e?.code}, message: ${e?.message}`);
        callback(defaultValue);
      })
    } catch (e) {
      LogUtil.error(TAG, `getPreferencesValueByKey ${key} failed. code: ${e?.code}, message: ${e?.message}`);
      callback(defaultValue);
    }
  }

  getPreferencesValueByKeySync(context: Context, key: string, defaultValue: preferences.ValueType) {
    let res = defaultValue;
    try {
      dataPreferences.removePreferencesFromCacheSync(context, PREFERENCES_NAME);
      let preference = dataPreferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      res = preference.getSync(key, defaultValue)
    } catch (e) {
      LogUtil.error(TAG, `getPreferencesValueByKey preference ${PREFERENCES_NAME} failed. code: ${e?.code}`);
    }
    return res;
  }

  async setPreferenceKeyValue(key: string, state: preferences.ValueType, abilityContext?: common.Context) {
    const context = abilityContext ? abilityContext :
      this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    try {
      let preference = await dataPreferences.getPreferences(context, PREFERENCES_NAME);
      await preference!.put(key, state);
      await preference!.flush();
    } catch (e) {
      LogUtil.error(TAG, `setPreferenceKeyValue preference ${PREFERENCES_NAME} failed. code: ${e?.code}`);
    }
  }

  setPreferenceKeyValueSync(key: string, state: preferences.ValueType, abilityContext?: common.Context) {
    const context = abilityContext ? abilityContext :
      this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    try {
      let preference = dataPreferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      preference!.putSync(key, state);
      preference!.flushSync();
    } catch (e) {
      LogUtil.error(TAG, `setPreferenceKeyValueSync preference ${PREFERENCES_NAME} failed. code: ${e?.code}`);
    }
  }

  /**
   * Loads the latest Preferences, reads value from the Preferences.
   *
   * @param { Context } context - Indicates the context of application or capability.
   * @param { string } key - Indicates the key of the preferences. It cannot be {@code null} or empty.
   * @param { preferences.ValueType } defaultValue - Indicates the default value to return.
   * @param isNeedRemoveCache judge to remove cache
   * @returns { Promise }
   */
  static async getValue(
    context: Context,
    key: string,
    defaultValue: preferences.ValueType,
    isNeedRemoveCache?: boolean
  ): Promise<preferences.ValueType> {
    let value: preferences.ValueType = defaultValue;
    try {
      if (isNeedRemoveCache) {
        await dataPreferences.removePreferencesFromCache(context, PREFERENCES_NAME);
      }
      let preferences = await dataPreferences.getPreferences(context, PREFERENCES_NAME);
      value = await preferences.get(key, defaultValue);
      LogUtil.info(TAG, `get ${key} from preference succeeded and its value is ${value}`);
    } catch (e) {
      LogUtil.error(TAG, `getPreferencesValueByKey preference ${PREFERENCES_NAME} failed. code: ${e?.code}`);
    }
    return value;
  }

  static getValueSync(
    context: Context,
    key: string,
    defaultValue: preferences.ValueType,
    isNeedRemoveCache?: boolean
  ): preferences.ValueType {
    let value: preferences.ValueType = defaultValue;
    try {
      if (isNeedRemoveCache) {
        dataPreferences.removePreferencesFromCacheSync(context, PREFERENCES_NAME);
      }
      let preferences = dataPreferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
      value = preferences.getSync(key, defaultValue);
      LogUtil.info(TAG, `get ${key} from preference succeeded and its value is ${value}`);
    } catch (e) {
      LogUtil.error(TAG, `getPreferencesValueByKey preference ${PREFERENCES_NAME} failed. code: ${e?.code}`);
    }
    return value;
  }
}

