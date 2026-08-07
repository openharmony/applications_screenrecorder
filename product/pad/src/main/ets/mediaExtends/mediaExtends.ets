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
import media from '@ohos.multimedia.media';
import hiLog from '@ohos.hilog';

const TAG = 'MediaExtends'
const DOMAIN = 0x77AF;
const FORMAT = '%{public}s';
const PREFIX = '[ScreenRecorder]';

/**
 * AVScreenCapture notification mediaExtend
 *
 * @since 2025-7-11
 */
export default class MediaExtends {
  static async getAVScreenCaptureConfigurableParameters(sessionId: number): Promise<string> {
    try {
      let privacyResult = await media.getAVScreenCaptureConfigurableParameters(sessionId);
      return privacyResult;
    } catch (error) {
      hiLog.error(DOMAIN, PREFIX, FORMAT,
        `tag: ${TAG} --> getAVScreenCaptureConfigurableParameters error: ${error}`);
      return '';
    }
  }
}