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

import { media } from '@kit.MediaKit';
import { ArgumentMatchers, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { CCMUtil } from '@ohos/common';
import { PadRecorderConfig } from '@ohos/screen-recorder';

export function PadRecorderConfigTest() {
  describe('getPadVideoConfigTest', () => {

    let mocker: MockKit = new MockKit();
    let padConfigInstance: PadRecorderConfig = new PadRecorderConfig();
    it("getPadVideoConfigTest_with_not_three_fold", 0, async () => {
      const config = await padConfigInstance.getVideoConfig(0, 0);
      expect(config.fillMode).assertEqual(media.AVScreenCaptureFillMode.SCALE_TO_FILL)
    })

    it("getPadVideoConfigTest_with_chose_device_rate", 0, async () => {
      when(mocker.mockFunc(CCMUtil, CCMUtil.getCCMParam))(ArgumentMatchers.any, ArgumentMatchers.any).afterReturn('1');
      const config = await padConfigInstance.getVideoConfig(0, 0);
      expect(config.fillMode).assertEqual(media.AVScreenCaptureFillMode.SCALE_TO_FILL);
      mocker.ignoreMock(CCMUtil, CCMUtil.getCCMParam);
    })

    it("getPadVideoConfigTest_with_chose_720P", 0, async () => {
      when(mocker.mockFunc(CCMUtil, CCMUtil.getCCMParam))(ArgumentMatchers.any, ArgumentMatchers.any).afterReturn('0');
      const config = await padConfigInstance.getVideoConfig(0, 0);
      expect(Math.max(config.frameHeight as number, config.frameWidth as number)).assertEqual(1280);
      mocker.ignoreMock(CCMUtil, CCMUtil.getCCMParam);
    })

    it("getPadVideoConfigTest_with_chose_1080P", 0, async () => {
      when(mocker.mockFunc(CCMUtil, CCMUtil.getCCMParam))(ArgumentMatchers.any, ArgumentMatchers.any).afterReturn('2');
      const config = await padConfigInstance.getVideoConfig(0, 0);
      expect(Math.max(config.frameHeight as number, config.frameWidth as number)).assertEqual(1920);
      mocker.ignoreMock(CCMUtil, CCMUtil.getCCMParam);
    })
  });
}

