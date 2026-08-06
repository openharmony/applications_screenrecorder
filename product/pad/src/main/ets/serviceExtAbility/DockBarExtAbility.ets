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
import { RecordManager } from '@ohos/screen-recorder';
import Want from '@ohos.app.ability.Want';
import ServiceExtAbility from './ServiceExtAbility';

/* instrument ignore file */
const TAG = 'DockBarExtAbility';

export default class DockBarExtAbility extends ServiceExtAbility {
  async startRequest(want: Want): Promise<void> {
    LogUtil.info(TAG, 'DockBarExtAbility startRequest');
    if (RecordManager.getInstance().getIsRecording()) {
      RecordManager.getInstance().stop(false);
      return;
    }
    super.startRequest(want);
  }
};