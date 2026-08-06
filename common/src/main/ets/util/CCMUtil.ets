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
import { systemParameterEnhance } from '@kit.BasicServicesKit';
import { LogUtil } from './LogUtil';

const TAG = 'CCMUtil';

export class CCMUtil {
  /**
   * 获取参数型CCM配置
   * @param name CCM项名称
   * @param key 用以获取CCM值的键值
   * @param defaultValue 默认值
   * @returns CCM项值
   */
  public static getCCMParam(name: string, key: string, defaultValue?: string): Promise<string | undefined> {
    return new Promise((resolve, reject) => {
      let ccmParam: string | undefined = undefined
      try {
        ccmParam = systemParameterEnhance.getSync(key, defaultValue);
        LogUtil.info(TAG, `success to get ${name}'s ccm param.`);
      } catch (err) {
        LogUtil.error(TAG, `fail to get ${name}'s ccm param, for ${err?.message}.`);
      }
      resolve(ccmParam);
    });
  }
}