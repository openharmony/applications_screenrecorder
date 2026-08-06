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
import { WindowManager } from '../../manager';

@Component
export struct StopImage {
  @State stopImageWidth: Resource = $r('app.float.icon_play_size');
  @State stopImageHeight: Resource = $r('app.float.icon_play_size');

  build() {
    Image($r('app.media.ic_video_play_btn'))
      .objectFit(ImageFit.Contain)
      .width(this.stopImageWidth)
      .height(this.stopImageHeight)
      .draggable(false)
      .syncLoad(true)
      .accessibilityLevel(Constants.ACCESSIBILITY_LEVEL_NO)
  }
}