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

import { sendableContextManager } from '@kit.AbilityKit';

/* instrument ignore file */
const TAG = 'SendableObject';
export const enum WorkerType {
  DEFAULT = 'DEFAULT',
  SET_TIMER = 'SET_TIMER',
  FILE_WRITE_CHECK = 'FILE_WRITE_CHECK',
  VIDEO_FILE_CHANGE = 'VIDEO_FILE_CHANGE',
  CHECK_FREE_SPACE = 'CHECK_FREE_SPACE',
  CHECK_VIDEO_SIZE = 'CHECK_VIDEO_SIZE',
};

export interface VideoDataType {
  videoFilePath : string,
  videoFd: number
}

@Sendable
export class SendableObject {
  constructor(sendableContext: sendableContextManager.SendableContext, type: WorkerType = WorkerType.DEFAULT, data: string = '') {
    this.sendableContext = sendableContext;
    this.type = type;
    this.data = data;
  }

  private sendableContext: sendableContextManager.SendableContext;
  private type: WorkerType;
  private data: string;

  public getSendableContext() {
    return this.sendableContext;
  }

  public getWorkerType() {
    return this.type;
  }

  public getData() {
    return this.data;
  }
}