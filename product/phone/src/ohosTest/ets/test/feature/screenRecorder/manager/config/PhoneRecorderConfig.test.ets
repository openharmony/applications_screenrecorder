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
import { DisplayUtil } from '@ohos/common';
import { PhoneRecorderConfig } from '@ohos/screen-recorder';

export function PhoneRecorderConfigTest() {
  describe('getPhoneVideoConfigTest', () => {

    let mocker: MockKit = new MockKit();
    let phoneConfigInstance: PhoneRecorderConfig = new PhoneRecorderConfig();
    it("getPhoneVideoConfigTest_with_not_three_fold", 0, async () => {
      const config = await phoneConfigInstance.getVideoConfig(0, 0);
      expect(config.fillMode).assertEqual(media.AVScreenCaptureFillMode.SCALE_TO_FILL)
    })

    it("getPhoneVideoConfigTest_with_three_fold", 0, async () => {
      when(mocker.mockFunc(DisplayUtil, DisplayUtil.isThreeFoldScreen))().afterReturn(true);
      const config = await phoneConfigInstance.getVideoConfig(0, 0);
      expect(config.fillMode).assertEqual(media.AVScreenCaptureFillMode.PRESERVE_ASPECT_RATIO);
      mocker.ignoreMock(DisplayUtil, DisplayUtil.isThreeFoldScreen);
    })

    it("getPhoneVideoConfigTest_with_verde_one_handed_mode", 0, async () => {
      when(mocker.mockFunc(DisplayUtil, DisplayUtil.isVerdeProducts))().afterReturn(true);
      when(mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldedStatus))().afterReturn(false);
      when(mocker.mockFunc(DisplayUtil, DisplayUtil.isOneHandedMode))(ArgumentMatchers.any).afterReturn(true);
      const config = await phoneConfigInstance.getVideoConfig(0, 0);
      expect(config.fillMode).assertEqual(media.AVScreenCaptureFillMode.SCALE_TO_FILL);
      mocker.ignoreMock(DisplayUtil, DisplayUtil.isVerdeProducts);
      mocker.ignoreMock(DisplayUtil, DisplayUtil.isFoldedStatus);
      mocker.ignoreMock(DisplayUtil, DisplayUtil.isOneHandedMode);
    })
  });
}

