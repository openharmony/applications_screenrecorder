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

const TAG: string = 'ReflectUtil';
type AnyType = number | string | boolean | null | undefined | bigint | object | void;

export class ReflectUtil {
  /**
   * 调用对象的私有方法
   *
   * @param obj 对象
   * @param funcName 方法名称
   * @param args 参数
   * @returns 函数执行结果
   */
  public static callPrivateFunc<T>(obj: object, funcName: string, ...args: Object[]): T | undefined {
    try {
      const func: Function = Reflect.get(obj, funcName);
      try {
        const objFunc: Function = func.bind(obj, ...args); // 绑定方法调用者为obj
        const result = objFunc(...args) as T;
        return result;
      } catch (callErr) {
        const callErrObj: Record<string, Object> = callErr;
        callErrObj['isCallErr'] = true;
        throw callErrObj as object as Error;
      }
    } catch (err) {
      const errObj: Record<string, Object> = err;
      if (typeof errObj['isCallErr'] === 'boolean' && errObj['isCallErr']) {
        throw err as Error;
      }
      LogUtil.error(TAG, 'callPrivateFunc err ' + err?.message);
    }
    return undefined;
  }

  /**
   * 获取对象的属性，可以是类的静态属性
   *
   * @param obj 对象
   * @param attrName 属性名
   * @returns 属性内容
   */
  public static getObjAttr<T>(obj: object, attrName: string): T | undefined {
    try {
      return Reflect.get(obj, attrName) as T;
    } catch (err) {
      LogUtil.error(TAG, 'getObjAttr err ' + err?.message);
    }
    return undefined;
  }

  /**
   * 设置对象属性,或者设置类的静态属性
   *
   * @param obj 对象实例
   * @param attrName 属性名
   * @param attrValue 属性值
   * @returns 是否成功
   */
  public static setObjAttr(obj: object, attrName: string, attrValue: AnyType): boolean {
    try {
      return Reflect.set(obj, attrName, attrValue);
    } catch (err) {
      LogUtil.error(TAG, 'setObjAttr err ' + err?.message);
    }
    return false;
  }
}