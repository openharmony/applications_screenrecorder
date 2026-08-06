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
import { display } from '@kit.ArkUI';
import { media } from '@kit.MediaKit';
import { CCMUtil, LogUtil } from '@ohos/common';
import { CCM, CCMItem, TabletScreenRecorderCCMResolution } from '../types';
import { RecorderConfigInterface } from './RecorderConfigInterface';

const DEFAULT_AUDIO_BIT_RATE = 96000;
const DEFAULT_AUDIO_CHANNELS = 1;
const DEFAULT_AUDIO_SAMPLE_RATE = 48000;
const DEFAULT_VIDEO_BIT_RATE = 10000000;
const MODEL_1080P: number = 1920;
const MODEL_720P: number = 1280;
const TAG = 'PadRecorderConfig';

/**
 * PAD 录屏配置类
 */
export class PadRecorderConfig implements RecorderConfigInterface {
  private deviceWidth: number = 0;
  private deviceHeight: number = 0;

  /* instrument ignore next */
  async getVideoConfig(fd: number, displayId: number): Promise<media.AVScreenCaptureRecordConfig> {
    await this.initRecorderRate();
    let recordConfig: media.AVScreenCaptureRecordConfig = {
      fd: fd,
      frameWidth: this.deviceWidth,
      frameHeight: this.deviceHeight,
      videoBitrate: DEFAULT_VIDEO_BIT_RATE,
      audioSampleRate: DEFAULT_AUDIO_SAMPLE_RATE,
      audioChannelCount: DEFAULT_AUDIO_CHANNELS,
      audioBitrate: DEFAULT_AUDIO_BIT_RATE,
      preset: media.AVScreenCaptureRecordPreset.SCREEN_RECORD_PRESET_H264_AAC_MP4,
      displayId: displayId,
      fillMode: media.AVScreenCaptureFillMode.SCALE_TO_FILL,
      strategy: {
        // PAD通话保持录屏
        keepCaptureDuringCall: true
      }
    }

    return recordConfig;
  }

  /* instrument ignore next */
  private async initRecorderRate(): Promise<void> {
    try {
      let currentDisplay: display.Display = display.getDefaultDisplaySync();
      this.deviceWidth = currentDisplay.width;
      this.deviceHeight = currentDisplay.height;
    } catch (err) {
      LogUtil.error(TAG, `get display resolution failed, error code: ${err.code}, error message: ${err.message}`);
      return;
    }

    LogUtil.info(TAG, `deviceWidth: ${this.deviceWidth}, deviceHeight: ${this.deviceHeight}`);
    let maxSide = await this.getMaxSide();
    const deviceRate: number =
      Math.min(this.deviceWidth, this.deviceHeight) / Math.max(this.deviceWidth, this.deviceHeight);
    let minSide = Math.ceil(maxSide * deviceRate / 2) * 2;

    const isWidthGreater = this.deviceWidth > this.deviceHeight;
    this.deviceWidth = isWidthGreater ? maxSide : minSide;
    this.deviceHeight = isWidthGreater ? minSide : maxSide;
    LogUtil.info(TAG, `VideoConfig deviceWidth: ${this.deviceWidth}, deviceHeight: ${this.deviceHeight}`);
  }

  private async getMaxSide(): Promise<number> {
    // 平板根据ccm配置设置分辨率
    const tabletResolutionCCM: CCMItem = CCM.TABLET_SCREEN_RECORDER_RESOLUTION;
    const selectedResolutionString: string =
      await CCMUtil.getCCMParam(tabletResolutionCCM.name, tabletResolutionCCM.key, tabletResolutionCCM.defaultValue) as string;
    const selectedResolutionOrder = Number(selectedResolutionString);
    if (selectedResolutionOrder === TabletScreenRecorderCCMResolution.MODEL_DEVICE) {
      LogUtil.info(TAG, `current device is tablet, choose raw device resolution model.`);
      return Math.max(this.deviceWidth, this.deviceHeight);
    } else if (selectedResolutionOrder === TabletScreenRecorderCCMResolution.MODEL_1080P) {
      LogUtil.info(TAG, `current device is tablet, choose 1080p resolution model.`);
      return MODEL_1080P;
    } else {
      // 默认或者取不到值的情况
      LogUtil.info(TAG, `current device is tablet, choose 720p resolution model.`);
      return MODEL_720P;
    }
  }
}
