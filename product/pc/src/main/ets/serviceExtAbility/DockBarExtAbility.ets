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
import { ConfigurationConstant } from '@kit.AbilityKit';
import { emitter } from '@kit.BasicServicesKit';
import Want from '@ohos.app.ability.Want';
import { windowManager } from '../selectPanelUtil/SelectPanelWindowManager';
import { SystemConfig } from '../selectPanelUtil/SystemConfig';
import ServiceExtAbility from './ServiceExtAbility';
import { ExpansionScreenUtil } from '@ohos/screen-recorder';

/* instrument ignore file */
const TAG = 'DockBarExtAbility';

export default class DockBarExtAbility extends ServiceExtAbility {
  async startRequest(want: Want): Promise<void> {
    LogUtil.info(TAG, 'DockBarExtAbility startRequest');
    const displays = await ExpansionScreenUtil.getAllDisplays();
    if (!displays || displays.length == 0) {
      LogUtil.error(TAG, `normalScreenshot displays is invalid.`);
      return;
    }
    if (RecordManager.getInstance().getIsRecording()) {
      RecordManager.getInstance().stop(false);
      return;
    }
    if (ExpansionScreenUtil.isNormalHalfFoldedWithoutExpansion(displays)) {
      this.showChoosePanel(want);
    } else {
      super.startRequest(want);
    }
  }

  /**
   * 显示选面面板, displayId, 0是上半屏，999是下半屏，isBCRecord是true表示截全屏B+C
   */
  showChoosePanel(want: Want) {
    LogUtil.info(TAG, 'showChoosePanel');
    let isWindowType: boolean = true;
    let area: Area | undefined = undefined;
    if (want?.parameters) {
      isWindowType = want.parameters?.['isWindowType'] as boolean ?? true;
      area = want.parameters?.['area'] as Area;
      LogUtil.info(TAG, `isWindowType = ${isWindowType}, iconPositionX = ${area?.globalPosition.x}`);
    }
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    SystemConfig.updateDisplayConfig(this.context, isWindowType);
    windowManager.createWindow(this.context, isWindowType, area);
    emitter.on('emit_event_choose_panel_result', async (data: emitter.EventData) => {
      emitter.off('emit_event_choose_panel_result');
      let eventData: Record<string, object> = data?.data as Record<string, object>;
      let displayId: number = Number(eventData?.displayId);
      let isBCRecord: boolean = Boolean(eventData?.isBCRecord);
      if (displayId === undefined || Number.isNaN(displayId) || isBCRecord === undefined) {
        LogUtil.error(TAG, `showChoosePanel with error, display: ${displayId}, isBCRecord: ${isBCRecord}`);
        return;
      }
      LogUtil.info(TAG, `choose panel result, display: ${displayId}, isBCRecord: ${isBCRecord}`);
      await this.proxy?.onRequest(want, displayId, isBCRecord);
    })
  }
};