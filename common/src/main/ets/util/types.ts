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

import commonEvent from '@ohos.commonEventManager';

export const EVENT_NAME = {
  NAVBAR_EVENT: 'NAVBAR_EVENT',
  // 查询录屏存活广播
  JUDGE_ALIVE_EVENT: 'JUDGE_ALIVE_EVENT',
  // 确认录屏存活广播
  IS_ALIVE_EVENT: 'IS_ALIVE_EVENT',
};

export const ALIVE_EVENT_INFO = {
  BUNDLE_NAME: 'com.ohos.screenrecorder',
  PERMISSIONS: 'screenrecorder',
};

export const EVENT_SUBSCRIBER_INFO: commonEvent.CommonEventSubscribeInfo = {
  events: [
    commonEvent.Support.COMMON_EVENT_SCREEN_LOCKED,
    commonEvent.Support.COMMON_EVENT_SHUTDOWN,
  ],
};

/**
 * 超级省电模式/应急模式广播
 */
export const EVENT_POWER_SAVE_MODE_CHANGED = {
  events: [
    commonEvent.Support.COMMON_EVENT_POWER_SAVE_MODE_CHANGED,
  ]
}