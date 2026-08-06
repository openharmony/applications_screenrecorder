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
import image from '@ohos.multimedia.image';

import { LogUtil } from '@ohos/common';

const TAG: string = 'CommonSelectPicker';

export namespace CommonSelectPicker {
  export enum FontSizeScale {
    /**
     * 小
     */
    SM = 0.85,
    /**
     * 标准
     */
    MD = 1.0,
    /**
     * 大
     */
    L = 1.15,
    /**
     * 超大
     */
    XL = 1.3,
    /**
     * 特大
     */
    XXL = 1.45,
    /**
     * 特大1档
     */
    XXL1 = 1.75,
    /**
     * 特大2档
     */
    XXL2 = 2,
    /**
     * 特大3档
     */
    XXL3 = 3.2,
  }

  export enum FoldPhoneTypeValue {
    /**
     * 无效值
     */
    INVALID_VALUE = -1,
    /**
     * 直板机
     */
    STRAIGHT = 0,
    /**
     * 大折（内折） X5
     */
    LARGE_FOLD = 1,
    /**
     * 小折叠（只有内折） pocket
     */
    SMALL_FOLD = 2,
    /**
     * 外折 XS2
     */
    EXTERNAL_FOLD = 3,
    /**
     * 扩展新形态
     */
    EXPANDING_NEX_FORMS = 4,
    /**
     * super fold
     */
    EXPANDING_SUPER_FOLD = 5,
    /**
     * 三折叠 GRL
     */
    THREE_FOLD_EXPANDING = 6,
    /**
     * 扩展新形态
     */
    NEXT_SUPER_FOLD_EXPANDING = 7,
  }

  @Observed
  export class WindowImageData {
    public missionShot: image.PixelMap | null = null;
    public missionId: number | null = null;
    public missionLabel: string | null = null;
    public missionIcon?: string | null = null;
    public isDisplay?: boolean = false;
    public imageWidth?: number = 0;
    public imageHeight?: number = 0;
  }

  export class JsonData {
    public choice: string = 'true';
    public displayId: number | number[] | null = -1;
    public missionId: number | null = -1;
    public checkBoxSelected: string = 'true';
    public isInnerAudioBoxSelected?: string = 'true';
  }

  export class BasicDataSource implements IDataSource {
    private listeners: DataChangeListener[] = [];
    private originWindowImageDataList: WindowImageData[] = [];
    public static ERROR_WINDOW_IMAGE_DATA: WindowImageData = {
      missionShot: null,
      missionId: null,
      missionIcon: null,
      missionLabel: null,
      isDisplay: false,
      imageWidth: 0,
      imageHeight: 0,
    };

    public totalCount(): number {
      return this.originWindowImageDataList.length;
    }

    public getData(index: number): WindowImageData {
      if (index < 0 || index >= this.originWindowImageDataList.length) {
        LogUtil.error(TAG, 'Invalid index');
        return BasicDataSource.ERROR_WINDOW_IMAGE_DATA;
      }
      return this.originWindowImageDataList[index];
    }

    public getAllDataList(): WindowImageData[] {
      return this.originWindowImageDataList;
    }

    registerDataChangeListener(listener: DataChangeListener): void {
      if (this.listeners.indexOf(listener) < 0) {
        LogUtil.info(TAG, 'add listener');
        this.listeners.push(listener);
      }
    }

    unregisterDataChangeListener(listener: DataChangeListener): void {
      const pos = this.listeners.indexOf(listener);
      if (pos >= 0) {
        LogUtil.info(TAG, 'remove listener');
        this.listeners.splice(pos, 1);
      }
    }

    notifyDataReload(): void {
      this.listeners.forEach((listener: DataChangeListener) => {
        try {
          listener.onDataReloaded();
        } catch (err) {
          LogUtil.error(TAG, `Listener notifyDataReload error: ${err?.message}`);
        }
      });
    }

    notifyDataAdd(index: number): void {
      this.listeners.forEach((listener: DataChangeListener) => {
        try {
          listener.onDataAdd(index);
        } catch (err) {
          LogUtil.error(TAG, `Listener notifyDataAdd error: ${err?.message}`);
        }
      });
    }

    notifyDataChange(index: number): void {
      this.listeners.forEach((listener: DataChangeListener) => {
        try {
          listener.onDataChange(index);
        } catch (err) {
          LogUtil.error(TAG, `Listener notifyDataChange error: ${err?.message}`);
        }
      });
    }

    notifyDataDelete(index: number): void {
      this.listeners.forEach((listener: DataChangeListener) => {
        try {
          listener.onDataDelete(index);
        } catch (err) {
          LogUtil.error(TAG, `Listener onDataDelete error: ${err?.message}`);
        }
      });
    }

    notifyDataMove(from: number, to: number): void {
      this.listeners.forEach((listener: DataChangeListener) => {
        try {
          listener.onDataMove(from, to);
        } catch (err) {
          LogUtil.error(TAG, `Listener onDataMove error: ${err?.message}`);
        }
      });
    }

    notifyDatasetChange(operations: DataOperation[]): void {
      this.listeners.forEach((listener: DataChangeListener) => {
        try {
          listener.onDatasetChange(operations);
        } catch (err) {
          LogUtil.error(TAG, `Listener onDatasetChange error: ${err?.message}`);
        }
      });
    }
  }

  export class WindowImageDataSource extends BasicDataSource {
    private windowImageDataList: WindowImageData[] = [];

    constructor(windowImageDataList: WindowImageData[]) {
      super();
      this.windowImageDataList = windowImageDataList;
    }

    public totalCount(): number {
      return this.windowImageDataList.length;
    }

    public getData(index: number): WindowImageData {
      if (index < 0 || index >= this.windowImageDataList.length) {
        LogUtil.error(TAG, 'Invalid index');
        return BasicDataSource.ERROR_WINDOW_IMAGE_DATA;
      }
      return this.windowImageDataList[index];
    }

    public getAllDataList(): WindowImageData[] {
      return this.windowImageDataList;
    }

    public pushData(data: WindowImageData): void {
      this.windowImageDataList.push(data);
      this.notifyDataAdd(this.windowImageDataList.length - 1);
    }

    public clear() {
      try {
        this.windowImageDataList.forEach((item: WindowImageData) => {
          try {
            if (item.missionShot !== null) {
              item.missionShot.release();
              item.missionShot = null;
            }
          } catch (err) {
            LogUtil.error(TAG, `Failed to release missionShot: ${err?.message}`);
          }
        })
        this.windowImageDataList = [];
        this.notifyDataReload();
      } catch (err) {
        LogUtil.error(TAG, `Failed to windowImageDataSource clear. Cause: ${err?.message}`);
      }
    }
  }

  export enum PickerMode {
    WINDOW_ONLY = 0,
    SCREEN_ONLY = 1,
    SCREEN_AND_WINDOW = 2,
  }
}