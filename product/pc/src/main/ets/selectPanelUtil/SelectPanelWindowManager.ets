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
import { common } from '@kit.AbilityKit';
import { display, window } from '@kit.ArkUI';
import { SelectPanelPosition } from './SelectPanelPosition';

/* instrument ignore file */
const TAG: string = 'ScreenRecorder-SelectPanelWindowManager';
const HPR_C_SCREEN_ID = 999;

// vp
const SELECT_PANEL_WINDOW_WIDTH = 360;
const SELECT_PANEL_WINDOW_HEIGHT = 186;

type FinishCallback = () => void;

/**
 * hopper半折态录屏选择面板-窗口管理类
 *
 * @author liyingjie
 * @since 2025-04-21
 */
class SelectPanelWindowManager {
  private mainWindow?: window.Window;
  private exitAnimation?: (onFinished?: FinishCallback) => void;

  async createWindow(context: common.ServiceExtensionContext, isWindowType: boolean, area?: Area): Promise<void> {
    LogUtil.info(TAG, `createWindow, isWindowType:${isWindowType}, area:${JSON.stringify(area)}`);
    try {
      let screenId = isWindowType ? HPR_C_SCREEN_ID : 0;
      LogUtil.info(TAG, `window create begin, screenId = ${screenId}`);
      let config: window.Configuration = {
        name: 'ScreenshotPanel',
        windowType: window.WindowType.TYPE_GLOBAL_SEARCH,
        ctx: context,
        displayId: screenId
      };
      let win = await window.createWindow(config);
      windowManager.setMainWindow(win);
      await win.setUIContent('pages/ScreenRecorderSelectPanel');
      win.setCornerRadius(16);
      await win.setWindowTouchable(true);
      win.setWindowBackgroundColor('#00FFFFFF');
      let positionOffset = await SelectPanelPosition.getPositionOffset(screenId, area);
      await win?.moveWindowTo(positionOffset[0], positionOffset[1]);
      await win.resize(vp2px(SELECT_PANEL_WINDOW_WIDTH), vp2px(SELECT_PANEL_WINDOW_HEIGHT));
      win.on('windowEvent', async (event: window.WindowEventType) => {
        LogUtil.info(TAG, `windowEvent: ${event}`);
        if (event === window.WindowEventType.WINDOW_INACTIVE) {
          windowManager.closeWindowWithAnimation();
        }
      })
      win.on('touchOutside', async () => {
        LogUtil.info(TAG, 'touchOutside');
        this.closeWindowWithAnimation();
      });
      display.on('remove', async () => {
        LogUtil.info(TAG, 'onScreenStatusChange');
        this.closeWindowWithAnimation();
      })
      LogUtil.info(TAG, 'window create end');
      await win.showWindow();
    } catch (e) {
      LogUtil.error(TAG, 'Failed to create window. error' + e);
      context.terminateSelf(); // create window失败直接销毁ability，防止底层bug导致重试仍然失败影响用户体验
    }
  }

  public setMainWindow(mainWindow: window.Window) {
    LogUtil.debug(TAG, 'setMainWindow');
    this.mainWindow = mainWindow;
  }

  public setMainWindowSnapshotSkip() {
    this.mainWindow?.setSnapshotSkip(true);
  }

  public closeWindow(): void {
    LogUtil.info(TAG, 'closeWindow');
    try {
      display.off('remove');
      this.mainWindow?.destroyWindow();
    } catch (e) {
      LogUtil.error(TAG, 'closeWindow error', e);
    } finally {
      this.mainWindow = undefined;
      this.exitAnimation = undefined;
    }
  }

  public registerExitAnimation(animation: (onFinish?: FinishCallback) => void): void {
    LogUtil.debug(TAG, 'registerExitAnimation');
    this.exitAnimation = animation;
  }

  public closeWindowWithAnimation(): void {
    LogUtil.debug(TAG, 'closeWindowWithAnimation')
    this.exitAnimation?.(() => this.closeWindow());
  }
}

export const windowManager: SelectPanelWindowManager = new SelectPanelWindowManager();