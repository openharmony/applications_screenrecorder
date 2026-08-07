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

/**
 * 全局变量管理类
 */
export class GlobalThisUtil {
  private constructor() {
  }

  private static instance: GlobalThisUtil;
  private objects = new Map<string, Object>();

  public static getInstance(): GlobalThisUtil {
    if (!GlobalThisUtil.instance) {
      GlobalThisUtil.instance = new GlobalThisUtil();
    }
    return GlobalThisUtil.instance;
  }

  getObject(value: string): Object | undefined {
    return this.objects.get(value);
  }

  setObject(key: string, objectClass: Object | undefined): void {
    this.objects.set(key, objectClass!);
  }
}
