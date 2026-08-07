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

import { LogUtil, SendableObject, VideoDataType, WorkerType } from '@ohos/common';
import { common, sendableContextManager } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import storageManager from '@ohos.file.statvfs';
import worker, { MessageEvents, ThreadWorkerGlobalScope } from '@ohos.worker';
import { MAX_VIDEO_SIZE_IN_BYTE, MIN_FREE_SPACE_IN_BYTE, WATCH_PERIOD } from '../manager/types';

const workerPort: ThreadWorkerGlobalScope = worker.workerPort;
const TAG = 'FileWriteCheckWorkerPort';
let fileWriteCheckTimer: number | null = null;

/* instrument ignore file */
workerPort.onmessage = async (event: MessageEvents) => {
  try {
    LogUtil.info(TAG, 'FileWriteCheckWorkerPort onmessage callback');
    const sendableObject: SendableObject = event.data;
    const sendableContext: sendableContextManager.SendableContext =
      sendableObject.getSendableContext() as sendableContextManager.SendableContext;
    const screenRecorderContext: common.ServiceExtensionContext =
      sendableContextManager.convertToContext(sendableContext) as common.ServiceExtensionContext;

    const type: WorkerType = sendableObject.getWorkerType() as WorkerType;
    if (type !== WorkerType.FILE_WRITE_CHECK) {
      LogUtil.info(TAG, 'FileWriteCheckWorkerPort WorkerType error');
      return;
    }
    const data: VideoDataType = JSON.parse(sendableObject.getData());
    const videoFilePath: string = data.videoFilePath;
    const videoFd: number = data.videoFd;

    fileWriteCheckTimer = setInterval(async () => {
      const freeSpace = await storageManager.getFreeSize(screenRecorderContext!.filesDir);
      if (freeSpace <= MIN_FREE_SPACE_IN_BYTE) {
        workerPort.postMessage({
          type: WorkerType.CHECK_FREE_SPACE
        });
      };

      const size = fs.statSync(videoFd)?.size;
      if (size >= MAX_VIDEO_SIZE_IN_BYTE) {
        workerPort.postMessage({
          type: WorkerType.CHECK_VIDEO_SIZE
        });
      };
    }, WATCH_PERIOD);

  } catch (error) {
    LogUtil.info(TAG, 'onmessage error' + error);
    fileWriteCheckTimer && clearInterval(fileWriteCheckTimer);
  }
}

workerPort.onerror = () => {
  LogUtil.info(TAG, 'FileWriteCheckWorkerPort error occurred.');
  fileWriteCheckTimer && clearInterval(fileWriteCheckTimer);
}
