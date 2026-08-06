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
import {
  beforeAll,
  describe,
  expect,
  it,
  MockKit,
  when
} from '@ohos/hypium';
import { PcRecorderConfig } from '@ohos/screen-recorder';
import { CCMUtil } from '@ohos/common/src/main/ets/util';

export function PcRecorderConfigImplTest() {
  describe('getPcVideoConfigTest', () => {
    let pcRecorderConfig: PcRecorderConfig;
    beforeAll(() => {
      pcRecorderConfig = new PcRecorderConfig();
    });

    let mocker: MockKit = new MockKit();
    let pcConfigInstance: PcRecorderConfig = new PcRecorderConfig();
    it("getPcVideoConfigTest_with_not_bc_recorder", 0, async () => {
      const config = await pcConfigInstance.getVideoConfig(0, 1);
      expect(config.fillMode).assertEqual(media.AVScreenCaptureFillMode.PRESERVE_ASPECT_RATIO)
    })

    it("getPcVideoConfigTest_with_not_bc_recorder_and_displayId_undefined", 0, async () => {
      const config = await pcConfigInstance.getVideoConfig(0, 0);
      expect(config.fillMode).assertEqual(media.AVScreenCaptureFillMode.PRESERVE_ASPECT_RATIO)
    })

    it("getPcVideoConfigTest_with_not_bc_recorder_and_displayId_not_exit", 0, async () => {
      const config = await pcConfigInstance.getVideoConfig(0, -5);
      expect(config.fillMode).assertEqual(media.AVScreenCaptureFillMode.PRESERVE_ASPECT_RATIO)
    })

    it('atc_should_return_correct_config_when_all_operations_succeed', 0, async () => {
      pcRecorderConfig.setIsBcRecorder(false);
      const defaultAudioBitRate = 96000;
      const defaultAudioChannels = 1;
      const defaultAudioSampleRate = 48000;
      const defaultVideoBitRate = 10000000;
      const testName: string = 'test_name';
      const testKey: string = 'test_key';
      let mockFunc: Function = mocker.mockFunc(CCMUtil, CCMUtil.getCCMParam);
      when(mockFunc)(testName, testKey, '0').afterReturn('0');
      const result: ESObject = await pcRecorderConfig.getVideoConfig(123, 1);

      expect(result.fd).assertEqual(123);
      expect(result.frameWidth).assertEqual(0);
      expect(result.frameHeight).assertEqual(0);
      expect(result.videoBitrate).assertEqual(defaultVideoBitRate);
      expect(result.audioSampleRate).assertEqual(defaultAudioSampleRate);
      expect(result.audioChannelCount).assertEqual(defaultAudioChannels);
      expect(result.audioBitrate).assertEqual(defaultAudioBitRate);
      expect(result.preset).assertEqual(media.AVScreenCaptureRecordPreset.SCREEN_RECORD_PRESET_H264_AAC_MP4);
      expect(result.strategy.enableDeviceLevelCapture).assertFalse();
      expect(result.displayId).assertEqual(1);
      expect(result.fillMode).assertEqual(media.AVScreenCaptureFillMode.PRESERVE_ASPECT_RATIO);
    });

    it('atc_should_set_isBcRecorder_to_true_when_value_is_true', 0, () => {
      const pcRecorderConfig: ESObject = new PcRecorderConfig();
      pcRecorderConfig.setIsBcRecorder(true);
      expect(pcRecorderConfig['isBcRecorder']).assertTrue();
    });

    it('atc_should_set_isBcRecorder_to_false_when_value_is_false', 0, () => {
      const pcRecorderConfig: ESObject = new PcRecorderConfig();
      pcRecorderConfig.setIsBcRecorder(false);
      expect(pcRecorderConfig['isBcRecorder']).assertFalse();
    });
  });
}