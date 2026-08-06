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

import { SystemConfig } from './SystemConfig';
import { LogUtil } from '@ohos/common';
import { display } from '@kit.ArkUI';

const TAG: string = 'Screenshot-SelectPanelWindowManager';
const HPR_C_SCREEN_ID = 999;

//px
const HPR_C_SCREEN_DFT_WIDTH: number = 2472;
const HPR_C_SCREEN_DFT_HEIGHT: number = 1608;

// vp
const WINDOW_HORIZONTAL_MARGIN = 8;
const WINDOW_DOCK_MARGIN = 8;
const WINDOW_STATUS_MARGIN = 4;
const SELECT_PANEL_WINDOW_WIDTH = 360;
const SELECT_PANEL_WINDOW_HEIGHT = 186;
const HPR_DOCKER_HEIGHT = 73;
const HPR_STATUS_HEIGHT = 40;


/**
 * hopper半折态全屏截屏选择面板位置类
 *
 * @author caijiangtao
 * @since 2026-04-08
 */
export class SelectPanelPosition {
  /**
   * 获取当前屏幕下窗口对应偏移量
   * @returns [positionOffsetX, positionOffsetY]
   */
  static async getPositionOffset(screenId: number, area?: Area): Promise<number[]> {
    let screenWidth = 0;
    let screenHeight = 0;
    let dftDisplay: display.Display | undefined;
    try {
      // 获取屏幕宽高px
      dftDisplay = display.getDisplayByIdSync(screenId);
      LogUtil.info(TAG, `dftDisplay.width = ${dftDisplay.width}(px), dftDisplay.height = ${dftDisplay.height}(px)`);
      screenWidth = dftDisplay.width;
      screenHeight = dftDisplay.height;
    } catch (error) {
      LogUtil.error(TAG, `getDisplaySize failed: { code: ${error?.code}, message: ${error?.message}}`);
      screenWidth = HPR_C_SCREEN_DFT_WIDTH;
      screenHeight = HPR_C_SCREEN_DFT_HEIGHT;
    }

    let positionOffsetX = 0;
    if (SystemConfig.isRTL()) {
      positionOffsetX = vp2px(WINDOW_HORIZONTAL_MARGIN);
      if (area) {
        let prePositionX = (area.globalPosition.x as number) - vp2px(SELECT_PANEL_WINDOW_WIDTH) + (area.width as number)
        positionOffsetX = Math.max(prePositionX, positionOffsetX);
      } else {
        LogUtil.warn(TAG, 'get area failed, create window on default position');
      }
    } else {
      positionOffsetX = screenWidth - vp2px(WINDOW_HORIZONTAL_MARGIN + SELECT_PANEL_WINDOW_WIDTH);
      if (area) {
        positionOffsetX = Math.min(area.globalPosition.x as number, positionOffsetX);
      } else {
        LogUtil.warn(TAG, 'get area failed, create window on default position');
      }
    }
    if (screenId !== HPR_C_SCREEN_ID) {
      let positionOffsetY = vp2px(HPR_STATUS_HEIGHT + WINDOW_STATUS_MARGIN);
      LogUtil.info(TAG, `positionOffsetX=${positionOffsetX}(px), positionOffsetY=${positionOffsetY}(px)`);
      return [positionOffsetX, positionOffsetY];
    }
    // 面板在c面，此时一定没有状态栏。unavailableH就是DockBar的高度。
    // y坐标是截屏按钮的父布局的左下角, 更新为选面面板的右上角角y坐标,
    // positionOffsetY是右上角角y坐标
    let positionOffsetY = 0;
    if (area && area.globalPosition && area.globalPosition.y) {
      // 截屏面板的左下角y坐标，减去选面面板的高度，
      positionOffsetY = area.globalPosition.y as number - vp2px(SELECT_PANEL_WINDOW_HEIGHT);
    }
    if (positionOffsetY <= 0) {
      LogUtil.error(TAG, `get positionOffsetY error, ${JSON.stringify(area)}`);
      positionOffsetY = screenHeight - vp2px(WINDOW_DOCK_MARGIN + HPR_DOCKER_HEIGHT + SELECT_PANEL_WINDOW_HEIGHT);
    }
    LogUtil.info(TAG, `positionOffsetX=${positionOffsetX}(px), positionOffsetY=${positionOffsetY}(px)`);
    return [positionOffsetX, positionOffsetY];
  }
}
