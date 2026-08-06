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

import { power } from '@kit.BasicServicesKit';
import common from '@ohos.app.ability.common';
import { GlobalThisUtil, LogUtil } from '@ohos/common';
import { RecordManager } from '../manager/RecordManager';
import { RecorderFileManager } from '../manager/RecorderFileManager';

const TAG = 'Recorder_Util';
const MSG_KILL_PROCESS_DELAY = 3000; // the delay of sending kill screen recorder process message

/**
 * Recorder Util
 *
 * @since 2023-09-25
 */
export class RecorderUtil {
  static async postKillProcessMessage(): Promise<void> {
    // remove kill process message
    const killProcessTimeoutId = GlobalThisUtil.getInstance()!.getObject('killProcessTimeoutId') as number;
    killProcessTimeoutId && clearTimeout(killProcessTimeoutId);

    GlobalThisUtil.getInstance()!.setObject('killProcessTimeoutId', setTimeout(() => {
      if (RecordManager.getInstance()!.getIsRecording() ||
        GlobalThisUtil.getInstance()!.getObject('isProcessing') as boolean ||
        GlobalThisUtil.getInstance()!.getObject('isMaskWindowExisting') as boolean ||
        GlobalThisUtil.getInstance()!.getObject('isPreViewWindowExisting') as boolean ||
        GlobalThisUtil.getInstance()!.getObject('isShareWindowExisting') as boolean) {
        LogUtil.warn(TAG,
          'The process cannot be killed because the screen recording is not stopped or there is unfinished request.');
        return;
      }
      const toastContext = GlobalThisUtil.getInstance()!.getObject('toastContext') as common.ServiceExtensionContext;
      if (toastContext) {
        LogUtil.info(TAG, 'toastContext is still alive, kill ToastExtensionAbility.');
        toastContext!.terminateSelf();
      }
      const context =
        GlobalThisUtil.getInstance()!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
      context!.terminateSelf();
    }, MSG_KILL_PROCESS_DELAY));
  }

  /**
   * 进入超级省电模式/应急模式停止录屏
   *
   * @param recordManager 录制管理类
   * @param context 上下文
   */
  static async powerSaveModeStopRecording(recordManager: RecordManager,
    context: common.ServiceExtensionContext): Promise<void> {
    LogUtil.warn(TAG, 'power save mode changed, stop recording');
    try {
      if (power.getPowerMode() !== power.DevicePowerMode.MODE_EXTREME_POWER_SAVE) {
        LogUtil.warn(TAG, 'current power is not MODE_EXTREME_POWER_SAVE, return!');
        return;
      }
      if (!recordManager.getIsStart()) {
        await RecorderFileManager.getInstance().setVideoAssetPending();
        await recordManager.release();
      }
      if (recordManager.getIsRecording() && recordManager.getIsStart()) {
        await recordManager!.stop(true);
      }
      context.terminateSelf();
    } catch (error) {
      LogUtil.error(TAG,
        `powerSaveModeStopRecording failed, code:${error?.code} message:${error?.message}`);
    }
  }
}