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
import { GlobalThisUtil, LogUtil } from '@ohos/common';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

const TAG = 'AccessManager';

export class AccessManager {
  private static instance: AccessManager;
  private photoAccessHelper?: photoAccessHelper.PhotoAccessHelper;
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();

  static getInstance(): AccessManager {
    if (!AccessManager.instance) {
      AccessManager.instance = new AccessManager();
    }
    return AccessManager.instance;
  }

  getPhotoAccessHelper(): photoAccessHelper.PhotoAccessHelper | undefined {
    if (this.photoAccessHelper) {
      return this.photoAccessHelper;
    }
    try {
      const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
      this.photoAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
      LogUtil.warn(TAG, 'get user file manager success');
      return this.photoAccessHelper;
    } catch (error) {
      LogUtil.error(TAG, 'get user file manager failed because: ', (error as BusinessError).message);
    }
    return undefined;
  }
}

