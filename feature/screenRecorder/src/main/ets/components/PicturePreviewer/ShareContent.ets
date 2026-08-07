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
import { WindowManager } from '../../manager';
import { BORDER_COLOR_DEFAULT, SHARE_BUTTON_DARK_COLOR, SHARE_BUTTON_HEIGHT, SHARE_BUTTON_LIGHT_COLOR } from './types';

const TAG = 'ShareContent';
@Component
export struct ShareContent {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('thumbWidth') thumbWidth: number = 270;
  private videoUri: string | undefined = '';
  private windowManagerInstance: WindowManager = WindowManager.getInstance();

  build() {
    Button($r('app.string.share'), { type: ButtonType.Capsule })
      .fontSize($r('sys.float.Body_M'))
      .maxFontScale(1)
      .fontColor($r('sys.color.font_emphasize'))
      .width(`${this.thumbWidth}px`)
      .height(SHARE_BUTTON_HEIGHT)
      .shadow(ShadowStyle.OUTER_DEFAULT_XS)
      .backgroundColor(this.isDarkMode ? SHARE_BUTTON_DARK_COLOR : SHARE_BUTTON_LIGHT_COLOR)
      .backdropBlur(0)
      .borderWidth(0)
      .borderColor(BORDER_COLOR_DEFAULT)
      .onClick(() => {
        LogUtil.info(TAG, 'click share button');
        this.windowManagerInstance.startShare(this.videoUri);
      })
      .id('id_share_button')
  }

  aboutToAppear(): void {
    this.videoUri = AppStorage.Get('videoUri');
  }
}