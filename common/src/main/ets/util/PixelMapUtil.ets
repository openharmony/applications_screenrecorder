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
import image from '@ohos.multimedia.image';
import { DisplayUtil } from './DisplayUtil';

import { GlobalThisUtil } from './GlobalThisUtil';
import { LogUtil } from './LogUtil';

const TAG = 'PixelMapUtil';

export class PixelMapUtil {
  static async getPixelMapByName(name: string, pixelSize: number): Promise<image.PixelMap | undefined> {
    LogUtil.info(TAG, 'getPixelMap: ' + name);
    const context = GlobalThisUtil.getInstance().getObject('screenRecorderContext') as common.ServiceExtensionContext;
    let dfsDensity = DisplayUtil.getDefaultDisplayDpi();
    let decodingOptions: image.DecodingOptions = {
      editable: true,
      desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
      desiredSize: {
        width: DisplayUtil.vp2pxInTs(pixelSize, dfsDensity),
        height: DisplayUtil.vp2pxInTs(pixelSize, dfsDensity)
      }
    }
    let imageSource: image.ImageSource | undefined = undefined;
    try {
      const resourceMgr = context.resourceManager;
      const fileData = resourceMgr.getRawFileContentSync(name);
      imageSource = image.createImageSource(fileData.buffer as ESObject);
      const pixelMap = imageSource.createPixelMapSync(decodingOptions);
      LogUtil.info(TAG, 'success getPixelMap: ' + name);
      return pixelMap;
    } catch (e) {
      LogUtil.error(TAG, `failed getPixelMap, error code: ${e?.code}, message: ${e?.message}`);
    } finally {
      if (imageSource !== undefined) {
        imageSource.release()
      }
    }
    return undefined;
  }
}