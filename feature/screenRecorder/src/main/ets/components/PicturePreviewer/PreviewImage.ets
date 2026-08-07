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

import { Constants } from '@ohos/common';
import {
  BORDER_OPACITY_PREFIX,
  BORDER_OPACITY_SUFFIX,
  FULL_CONTAINER_HEIGHT,
  FULL_CONTAINER_WIDTH,
  IMAGE_BORDER_WIDTH_PX,
  WINDOW_BORDER_WIDTH
} from './types';

@Component
export struct PreviewImage {
  @StorageLink('thumbnail') thumbnail: PixelMap | undefined = undefined;
  @StorageLink('borderColorOpacityValue') opacityValue: number = 0;
  @StorageLink('thumbWidth') thumbWidth: number = 270;
  @StorageLink('thumbHeight') thumbHeight: number = 626;

  build() {
    Column() {
      Row() {
        Image(this.thumbnail!)
          .draggable(false)
          .syncLoad(true)
          .borderRadius(0)
      }
      .clip(true)
      .borderRadius($r('app.float.default_corner_radius_xs'))
      .borderColor($r('app.color.color_image_border'))
      .borderWidth(IMAGE_BORDER_WIDTH_PX)
    }
    .borderColor(`${BORDER_OPACITY_PREFIX}${this.opacityValue}${BORDER_OPACITY_SUFFIX}`)
    .backgroundColor(`${BORDER_OPACITY_PREFIX}${this.opacityValue}${BORDER_OPACITY_SUFFIX}`)
    .width(FULL_CONTAINER_WIDTH)
    .height(FULL_CONTAINER_HEIGHT)
    .borderRadius($r('app.float.default_corner_radius_s'))
    .borderWidth(WINDOW_BORDER_WIDTH)
    .accessibilityLevel(Constants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS)
  }
}