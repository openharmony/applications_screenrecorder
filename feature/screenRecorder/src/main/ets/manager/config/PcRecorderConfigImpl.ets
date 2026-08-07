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
import { RecorderConfigInterface } from './RecorderConfigInterface';
import { ExpansionScreenUtil } from '../../util/ExpansionScreenUtil';
import { CCM } from '../types';

/* instrument ignore file */
const DEFAULT_AUDIO_BIT_RATE = 96000;
const DEFAULT_AUDIO_CHANNELS = 1;
const DEFAULT_AUDIO_SAMPLE_RATE = 48000;
const DEFAULT_VIDEO_BIT_RATE = 10000000;
const TAG = 'PcRecorderConfig';

/**
 * Pc 录屏配置实现类
 */
export class PcRecorderConfig implements RecorderConfigInterface {
  private isBcRecorder: boolean = false;
  private deviceWidth: number = 0;
  private deviceHeight: number = 0;

  /**
   * 设置是否是BC录屏
   *
   * @param value 值
   */
  /* instrument ignore next */
  public setIsBcRecorder(value: boolean): void {
    this.isBcRecorder = value;
  }

  /* instrument ignore next */
  async getVideoConfig(fd: number, displayId: number): Promise<media.AVScreenCaptureRecordConfig> {
    await this.initRecorderRate(displayId);
    const privacyStratagy: string =
      await CCMUtil.getCCMParam(CCM.SCREEN_RECORDER_PRIVACY_STRATAGY.name,
        CCM.SCREEN_RECORDER_PRIVACY_STRATAGY.key, CCM.SCREEN_RECORDER_PRIVACY_STRATAGY.defaultValue) as string;
    const privacyMaskMode: number = Number(privacyStratagy);
    LogUtil.warn(TAG, `CCM privacyStratagy: ${privacyStratagy} --- privacyMaskMode: ${privacyMaskMode}`);
    let recordConfig: media.AVScreenCaptureRecordConfig = {
      fd: fd,
      frameWidth: this.deviceWidth,
      frameHeight: this.deviceHeight,
      videoBitrate: DEFAULT_VIDEO_BIT_RATE,
      audioSampleRate: DEFAULT_AUDIO_SAMPLE_RATE,
      audioChannelCount: DEFAULT_AUDIO_CHANNELS,
      audioBitrate: DEFAULT_AUDIO_BIT_RATE,
      preset: media.AVScreenCaptureRecordPreset.SCREEN_RECORD_PRESET_H264_AAC_MP4,
      strategy: {
        // hpr特有
        enableDeviceLevelCapture: this.isBcRecorder,
        privacyMaskMode: privacyMaskMode
      },
      displayId: displayId,
      fillMode: media.AVScreenCaptureFillMode.PRESERVE_ASPECT_RATIO
    }

    return recordConfig;
  }

  /* instrument ignore next */
  private async initRecorderRate(displayId: number): Promise<void> {
    /* instrument ignore if */
    if (this.isBcRecorder) {
      this.deviceWidth = ExpansionScreenUtil.getPcBCWidth() as number;
      this.deviceHeight = ExpansionScreenUtil.getPcBCHeight(await ExpansionScreenUtil.getAllDisplays()) as number;
      LogUtil.info(TAG,
        `VideoConfig deviceWidth: ${this.deviceWidth}, deviceHeight: ${this.deviceHeight}, isBcRecorder`);
      return;
    }

    try {
      let currentDisplay: display.Display =
        displayId ? display.getDisplayByIdSync(displayId) : display.getDefaultDisplaySync();
      this.deviceWidth = Math.ceil(currentDisplay.width / 2) * 2;
      this.deviceHeight = Math.ceil(currentDisplay.height / 2) * 2;
    } catch (err) {
      LogUtil.error(TAG, `getVideoConfig failed, error code: ${err.code}, message: ${err.message}`);
    }
    LogUtil.info(TAG, `VideoConfig deviceWidth: ${this.deviceWidth}, deviceHeight: ${this.deviceHeight}`);
  }
}
