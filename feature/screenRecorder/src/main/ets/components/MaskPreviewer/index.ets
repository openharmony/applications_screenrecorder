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
import lazy { inputConsumer } from '@kit.InputKit';
import { PcRecordManager } from '../../manager';
import { PcWindowManager } from '../../manager/PcWindowManager';
import {
  COLOR_MASK_BACKGROUND,
  COLOR_TRANSPARENT,
  CURRENT_SELECTED_DISPLAY,
  MASKING_READY_TASK_ID,
  SCREENRECORDER_CURSOR
} from '../../manager/types';
import { ExpansionScreenUtil } from '../../util/ExpansionScreenUtil';

/* instrument ignore file */
const TAG = 'MaskPreviewer';

/**
 * 全局录屏选择display蒙层界面
 *
 * @since 2025-02-05
 */
@Component
export struct MaskPreviewer {
  @State private isHover: boolean = false;
  @StorageLink(CURRENT_SELECTED_DISPLAY) @Watch('currentDisplayUpdate') currentDisplay: number | undefined = undefined;
  @StorageLink(MASKING_READY_TASK_ID) @Watch('maskingReadyTaskIdUpdate') maskingReadyTaskId: number | undefined =
    undefined;
  @State isMaskingReady: boolean = false;
  @State private textInSelectedMask: Resource | undefined = undefined;
  /**
   * 中轴区的高度
   */
  private creaseRectH: number = 0;
  private displayId: number | undefined;
  private maskingReadyTask: number | undefined = undefined;
  private windowManagerInstance: PcWindowManager = PcWindowManager.getInstance();
  private winESCDownOption: inputConsumer.KeyOptions = {
    preKeys: [],
    finalKey: 2070,
    isFinalKeyDown: false,
    finalKeyDownDuration: 0
  };

  aboutToAppear(): void {
    this.displayId = this.getUIContext()?.getSharedLocalStorage()?.get('displayId');
    /* instrument ignore if */
    if (this.displayId == null) {
      this.displayId = undefined;
    }
    /* instrument ignore if */
    if (this.displayId === undefined) {
      LogUtil.warn(TAG, 'displayId is error!');
    }
    this.creaseRectH = px2vp(ExpansionScreenUtil.getCreaseRect()?.height);
    inputConsumer.on('key', this.winESCDownOption, async () => {
      LogUtil.warn(TAG, 'key ESC down, exit smart shot');
      await this.exitScreenRecordMask();
    });
    this.isMaskingReady = false;
    /* instrument ignore if */
    if (AppStorage.get(CURRENT_SELECTED_DISPLAY) === undefined) {
      this.maskingReadyTask = setTimeout(() => {
        LogUtil.info(TAG, 'maskingReadyTask');
        AppStorage.setOrCreate(MASKING_READY_TASK_ID, this.displayId);
      }, 50);
    } else {
      this.isMaskingReady = true;
    }
    LogUtil.info(TAG, 'aboutToAppear.');
  }

  onDidBuild(): void {
    ExpansionScreenUtil.getAllDisplays().then(displays => {
      if (this.displayId !== undefined) {
        this.textInSelectedMask = ExpansionScreenUtil.getTextInSelectMask(this.displayId, displays);
      }
    })
  }

  cancelMaskingReadyTask() {
    /* instrument ignore if */
    if (this.maskingReadyTask !== undefined) {
      clearTimeout(this.maskingReadyTask);
      this.maskingReadyTask = undefined;
    }
  }

  maskingReadyTaskIdUpdate() {
    LogUtil.info(TAG, 'maskingReadyTaskIdUpdate');
    this.cancelMaskingReadyTask();
    this.isMaskingReady = true;
  }

  currentDisplayUpdate() {
    LogUtil.info(TAG, 'currentDisplayUpdate');
    this.cancelMaskingReadyTask();
    this.isMaskingReady = true;
  }

  aboutToDisappear() {
    this.cancelMaskingReadyTask();
    inputConsumer.off('key', this.winESCDownOption);
  }

  private async exitScreenRecordMask(): Promise<void> {
    await this.windowManagerInstance.destroyMaskWindow();
    PcRecordManager.getInstance()!.unRegisterMaskDisplayListener();
  }

  private async onClickAction(event: ClickEvent) {
    LogUtil.warn(TAG, `onClickAction, displayId: ${this.displayId}`);
    PcRecordManager.getInstance()!.startTrigger(this.displayId)
  }

  private async onHoverEvent(isHover: boolean) {
    LogUtil.info(TAG, `onHoverEvent displayId: ${this.displayId}, isHover: ${isHover}`);
    this.isHover = isHover;
    AppStorage.setOrCreate(CURRENT_SELECTED_DISPLAY, this.displayId);
    const windowId: number | undefined = LocalStorage.getShared()?.get('windowId');
    /* instrument ignore if */
    if (isHover && windowId !== undefined) {
      this.windowManagerInstance.setPointerStyle(TAG, windowId, SCREENRECORDER_CURSOR, true);
    }
  }

  private async onMouseEvent(event: MouseEvent) {
    LogUtil.info(TAG, `onMouseEvent, displayId: ${this.displayId}`);
    if (event.button === MouseButton.Right && event.action === MouseAction.Press) {
      LogUtil.info(TAG, 'MouseButton.Right Press, exit Normal shot');
      await this.exitScreenRecordMask();
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      /* instrument ignore if */
      Column() {
        Column() {
          /* instrument ignore if */
          if (!this.isHover && this.isMaskingReady && AppStorage.get(CURRENT_SELECTED_DISPLAY) === undefined &&
          this.textInSelectedMask) {
            Text(this.textInSelectedMask)
              .fontColor(Color.White)
              .fontSize(25)
              .width(400)
              .height('100%')
              .textAlign(TextAlign.Center)
          }
        }
        .backgroundColor((this.isHover || !this.isMaskingReady) ? COLOR_TRANSPARENT : COLOR_MASK_BACKGROUND)
        .width('100%')
        .height('100%')

        Column() {
          Rect()
        }
        .backgroundColor(this.isMaskingReady ? COLOR_MASK_BACKGROUND : COLOR_TRANSPARENT)
        .width('100%')
        .height(this.creaseRectH)
      }
      .width('100%')
      .height('100%')

    }
    .onHover(this.onHoverEvent.bind(this))
    .onClick(this.onClickAction.bind(this))
    .onMouse(this.onMouseEvent.bind(this))
  }
}
