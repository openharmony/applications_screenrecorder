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
import { DisplayUtil, GlobalThisUtil, LogUtil } from '@ohos/common';
import { RecorderConfigInterface } from './RecorderConfigInterface';

const DEFAULT_AUDIO_BIT_RATE = 96000;
const DEFAULT_AUDIO_CHANNELS = 1;
const DEFAULT_AUDIO_SAMPLE_RATE = 48000;
const DEFAULT_VIDEO_BIT_RATE = 10000000;
const TAG = 'PhoneRecorderConfig';

/**
 * 手机录屏配置类
 */
export class PhoneRecorderConfig implements RecorderConfigInterface {
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private deviceWidth: number = 0;
  private deviceHeight: number = 0;

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
      strategy: {
        // 手机通话保持录屏
        keepCaptureDuringCall: true
      },
      displayId: displayId,
      fillMode: DisplayUtil.isThreeFoldScreen() ? media.AVScreenCaptureFillMode.PRESERVE_ASPECT_RATIO :
      media.AVScreenCaptureFillMode.SCALE_TO_FILL
    }

    return recordConfig;
  }

  private isVerde():boolean {
    return DisplayUtil.isVerdeProducts() && !DisplayUtil.isFoldedStatus();
  }

  private isHope():boolean {
    return DisplayUtil.isHopeProducts() && DisplayUtil.isFoldedStatus();
  }

  private async initRecorderRate(): Promise<void> {
    let context: Context = this.globalThisInstance!.getObject('screenRecorderContext') as Context;
    // verde hope 产品单手模式
    if ((this.isVerde() || this.isHope()) && DisplayUtil.isOneHandedMode(context)) {
      try {
        const resolutionObjects = await display.getAllDisplayPhysicalResolution();
        resolutionObjects.forEach((item: display.DisplayPhysicalResolution) => {
          if (item.foldDisplayMode === display.FoldDisplayMode.FOLD_DISPLAY_MODE_MAIN) {
            this.deviceWidth = item.physicalWidth;
            this.deviceHeight = item.physicalHeight;
          }
        })
      } catch (error) {
        LogUtil.error(TAG, `get special resolution failed, error code: ${error.code}, error message: ${error.message}`);
        return;
      }
    } else {
      try {
        let currentDisplay: display.Display = display.getDefaultDisplaySync();
        this.deviceWidth = currentDisplay.width;
        this.deviceHeight = currentDisplay.height;
      } catch (err) {
        LogUtil.error(TAG, `get display resolution failed, error code: ${err.code}, error message: ${err.message}`);
        return;
      }
    }

    LogUtil.info(TAG, `deviceWidth: ${this.deviceWidth}, deviceHeight: ${this.deviceHeight}`);
    let maxSide = Math.max(this.deviceWidth, this.deviceHeight);
    let minSide = Math.min(this.deviceWidth, this.deviceHeight);
    if (maxSide > 1920) {
      const deviceRate: number = minSide / maxSide;
      minSide = Math.ceil(1920 * deviceRate / 2) * 2;
      maxSide = 1920;
    }

    const isWidthGreater = this.deviceWidth > this.deviceHeight;
    this.deviceWidth = isWidthGreater ? maxSide : minSide;
    this.deviceHeight = isWidthGreater ? minSide : maxSide;
    LogUtil.info(TAG, `VideoConfig deviceWidth: ${this.deviceWidth}, deviceHeight: ${this.deviceHeight}`);
  }
}
