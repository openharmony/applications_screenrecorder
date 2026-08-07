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

import {
  LogUtil,
  PreferencesKey,
  PreferenceUtils,
  SendableObject,
  WorkerType
} from '@ohos/common';
import { common, sendableContextManager } from '@kit.AbilityKit';
import worker, { MessageEvents, ThreadWorkerGlobalScope } from '@ohos.worker';

const workerPort: ThreadWorkerGlobalScope = worker.workerPort;
let isRecordingTimer: number;
const dataPreferences = new PreferenceUtils();
const TAG = 'TimestampWorkerPort'
/* instrument ignore file */
workerPort.onmessage = async (event: MessageEvents) => {
  try {
    const sendableObject: SendableObject = event.data;
    const type: WorkerType = sendableObject.getWorkerType() as WorkerType;
    if (type !== WorkerType.SET_TIMER) {
      LogUtil.info(TAG, 'the set timer method is not executed.');
      return;
    }
    const sendableContext: sendableContextManager.SendableContext =
      sendableObject.getSendableContext() as sendableContextManager.SendableContext;
    const screenRecorderContext: common.ServiceExtensionContext =
      sendableContextManager.convertToContext(sendableContext) as common.ServiceExtensionContext;
    dataPreferences.setPreferenceKeyValue(PreferencesKey.RECORDING_TIMESTAMP, Date.now(), screenRecorderContext);
    isRecordingTimer = setInterval(async () => {
      dataPreferences.setPreferenceKeyValue(PreferencesKey.RECORDING_TIMESTAMP, Date.now(), screenRecorderContext);
    }, 1000);
  } catch (error) {
    LogUtil.info(TAG, 'onmessage error' + error);
    isRecordingTimer && clearInterval(isRecordingTimer);
  }
}

workerPort.onerror = () => {
  LogUtil.info(TAG, 'timerWorkerPort error occurred.');
  isRecordingTimer && clearInterval(isRecordingTimer);
}
