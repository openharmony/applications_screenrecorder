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
import { EventReportUtil, GlobalThisUtil, LogUtil } from '@ohos/common';
import { StartRecordTriggerResult } from '@ohos/common/src/main/ets/util/EventReportUtil';
import { SendableObject, VideoDataType, WorkerType } from '@ohos/common/src/main/ets/util/SendableObject';
import { common, sendableContextManager } from '@kit.AbilityKit';
import { worker } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { media } from '@kit.MediaKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AccessManager } from './AccessManager';
import { RecordManager } from './RecordManager';
import { CONNECTOR, SCREEN_RECORD_PREFIX, TIME_LENGTH, TIME_PREFIX, VIDEO_TYPE } from './types';

const TAG = 'RecorderFileManager';

/**
 * 录屏文件管理类
 */
export class RecorderFileManager {
  private static instance: RecorderFileManager;
  private avScreenCaptureRecorder?: media.AVScreenCaptureRecorder;
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private fileWriteWorkThread: worker.ThreadWorker | null = null;
  private videoFd: number = 0;
  private videoAsset?: photoAccessHelper.PhotoAsset;
  private videoFileName: string = '';
  private videoFilePath: string = '';
  private timeStamp: string = '';
  private duringFileWriteCallback: boolean = false;

  public setTimeStamp(timeStamp: string) {
    this.timeStamp = timeStamp;
  }

  public setAvScreenCaptureRecorder(avScreenCaptureRecorder: media.AVScreenCaptureRecorder | undefined) {
    LogUtil.info(TAG, `set avScreenCaptureRecorder: ${avScreenCaptureRecorder}`);
    this.avScreenCaptureRecorder = avScreenCaptureRecorder;
  }

  public getAvScreenCaptureRecorder(): media.AVScreenCaptureRecorder | undefined {
    LogUtil.info(TAG, `get avScreenCaptureRecorder: ${this.avScreenCaptureRecorder}`);
    return this.avScreenCaptureRecorder;
  }

  public getVideoFileName(): string {
    return this.videoFileName;
  }

  public setVideoFileName(fileName: string) {
    this.videoFileName = fileName;
  }

  public getVideoFilePath(): string {
    return this.videoFilePath;
  }

  public setVideoFilePath(path: string) {
    this.videoFilePath = path;
  }

  public getVideoFd(): number {
    return this.videoFd;
  }

  public setVideoFd(videoFd: number) {
    this.videoFd = videoFd;
  }

  public getVideoAsset(): photoAccessHelper.PhotoAsset | undefined {
    return this.videoAsset;
  }

  public setVideoAsset(videoAsset: photoAccessHelper.PhotoAsset | undefined) {
    this.videoAsset = videoAsset;
  }

  static getInstance(): RecorderFileManager {
    if (!RecorderFileManager.instance) {
      RecorderFileManager.instance = new RecorderFileManager();
    }
    return RecorderFileManager.instance;
  }

  /**
   * @throws { Error } createVideoAsset error.
   */
  async createVideoAsset(recorderTimes: number): Promise<void> {
    const createOption: photoAccessHelper.PhotoCreateOptions = {
      subtype: photoAccessHelper.PhotoSubtype.SCREENSHOT,
    };
    try {
      this.setVideoFileName(this.getVideoName(recorderTimes));
      this.videoAsset =
        await AccessManager.getInstance().getPhotoAccessHelper()!.createAsset(this.videoFileName, createOption);
      AppStorage.setOrCreate('videoUri', this.videoAsset.uri);
      LogUtil.info(TAG, 'Success to createAsset');
      this.setVideoFd(await this.videoAsset.open('w'));
      LogUtil.warn(TAG, `Success to open video asset uri  = ${this.videoAsset.uri}, fd = ${this.videoFd}`);
    } catch (error) {
      LogUtil.error(TAG, 'create video asset failed because: ', (error as BusinessError).message);
      EventReportUtil.setStartResult(StartRecordTriggerResult.RESULT_ERROR_BY_MEDIA_LIBRARY_UNAVAILABLE);
      EventReportUtil.setStartFaultReason(error.message);
      EventReportUtil.reportStartRecordEvent();
      await this.setVideoAssetPending();
      // When an error occurs, close the asset, then let the common error processing to deal with the error.
      this.videoAsset && this.videoAsset.close(this.videoFd);
      this.setVideoFd(0);
      throw new Error(error.message);
    }
    LogUtil.info(TAG, `Success to createVideoAsset with video fd: ${this.videoFd}`);
  }

  async setVideoAssetPending() {
    await this.videoAsset!.setPending(true);
    LogUtil.info(TAG, `Set the screen recording file to pending.`);
  }

  async releaseVideoAsset(isClose?: boolean): Promise<void> {
    let videoAsset = this.getVideoAsset();
    if (!videoAsset) {
      LogUtil.info(TAG, 'Video asset was already released');
      return;
    }
    try {
      if (!isClose) {
        videoAsset && videoAsset.close(this.videoFd);
      }
      RecorderFileManager.getInstance().setVideoFd(0);
      RecorderFileManager.getInstance().setVideoAsset(undefined);
      this.globalThisInstance.setObject('fileName', undefined);
      LogUtil.warn(TAG, 'Success to release video asset.');
    } catch (error) {
      await RecordManager.getInstance().handleError(error, 'release_video_asset', true);
    }
  }

  startFileWriteCheckWorker() {
    if (this.fileWriteWorkThread) {
      LogUtil.info(TAG, 'the file write work thread already exists');
      this.fileWriteWorkThread.terminate();
    }
    this.fileWriteWorkThread = new worker.ThreadWorker('../worker/FileWriteCheckWorker');
    const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    const sendableContext: sendableContextManager.SendableContext =
      sendableContextManager.convertFromContext(context);
    const data: VideoDataType = {
      videoFilePath: RecorderFileManager.getInstance().getVideoFilePath(),
      videoFd: RecorderFileManager.getInstance().getVideoFd()
    };
    LogUtil.info(TAG, 'start file write work thread');
    const sendableObject: SendableObject =
      new SendableObject(sendableContext, WorkerType.FILE_WRITE_CHECK, JSON.stringify(data));
    this.fileWriteWorkThread.postMessageWithSharedSendable(sendableObject);

    this.fileWriteWorkThread.onmessage = async (event) => {
      const type: WorkerType = event.data.type;
      if (this.duringFileWriteCallback) {
        LogUtil.info(TAG, 'The callback for the file write check is being executed');
        return;
      }
      this.duringFileWriteCallback = true;
      await RecordManager.getInstance().dealByType(type);
      LogUtil.info(TAG, 'The callback for the file write check has been executed');
      this.duringFileWriteCallback = false;
    };
  }

  async releaseFileWatcher(): Promise<void> {
    try {
      if (!this.fileWriteWorkThread) {
        LogUtil.info(TAG, 'the file_write_check work thread object does not exist.');
      } else {
        this.fileWriteWorkThread.terminate();
        this.fileWriteWorkThread = null;
        LogUtil.info(TAG, 'release FileWriteWorkThread success');
      }
    } catch (error) {
      LogUtil.info(TAG, 'FileWriteWorkThread error' + error);
    }
  }

  async releaseScreenCaptureRecorder(): Promise<void> {
    if (!this.avScreenCaptureRecorder) {
      LogUtil.info(TAG, 'Video recorder was already released');
      return;
    }
    try {
      await this.avScreenCaptureRecorder.release();
      this.avScreenCaptureRecorder = undefined;
      LogUtil.warn(TAG, 'Success to destroy video recorder.');
    } catch (error) {
      await RecordManager.getInstance().handleError(error, 'release_video_recorder', true);
      await RecordManager.getInstance().stop();
    }
  }

  getVideoName(recorderTimes: number): string {
    const fileName = this.globalThisInstance.getObject('fileName') as string;
    if (fileName) {
      LogUtil.warn(TAG, `use custom file name: ${fileName}`);
      return fileName;
    }

    if (!this.timeStamp) {
      this.timeStamp = this.generateTimestamp();
    }

    return `${SCREEN_RECORD_PREFIX}${CONNECTOR}${this.timeStamp}${CONNECTOR}${recorderTimes}${VIDEO_TYPE}`;
  }

  private generateTimestamp(): string {
    const date = new Date();
    const year = date.getFullYear().toString();
    const month = (date.getMonth() + 1).toString().padStart(TIME_LENGTH, TIME_PREFIX);
    const day = date.getDate().toString().padStart(TIME_LENGTH, TIME_PREFIX);
    const hour = date.getHours().toString().padStart(TIME_LENGTH, TIME_PREFIX);
    const minute = date.getMinutes().toString().padStart(TIME_LENGTH, TIME_PREFIX);
    const second = date.getSeconds().toString().padStart(TIME_LENGTH, TIME_PREFIX);

    return `${year}${month}${day}${CONNECTOR}${hour}${minute}${second}`;
  }
}

