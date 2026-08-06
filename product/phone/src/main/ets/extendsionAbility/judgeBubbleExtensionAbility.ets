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
import { WorkSchedulerExtensionAbility, workScheduler } from '@kit.BackgroundTasksKit';
import {
  LogUtil, ALIVE_EVENT_INFO, EVENT_NAME, CommonEventUtil, SettingDataUtil
} from '@ohos/common'
import commonEventManager from '@ohos.commonEventManager';
import { BusinessError } from '@ohos.base';

const TAG = 'judgeBubbleExtensionAbility';
const SETTINGS_INPUT_SHOW_TOUCH_HINT = 'settings.input.show_touch_hint';

/* instrument ignore file */
export default class JudgeBubbleExtensionAbility extends WorkSchedulerExtensionAbility {
  private isRecorderAliveSub: CommonEventUtil | undefined = undefined;

  async isRecorderAlive(): Promise<boolean> {
    return new Promise(async (resolve) => {
      const timer = setTimeout(() => {
        LogUtil.warn(TAG, `not get recorderIsAlive`);
        resolve(false);
      }, 2000);

      this.isRecorderAliveSub =
        new CommonEventUtil([EVENT_NAME.IS_ALIVE_EVENT], async () => {
          clearTimeout(timer);
          LogUtil.warn(TAG, `get recorderIsAlive`);
          resolve(true);
        });
      this.isRecorderAliveSub.subscribe(ALIVE_EVENT_INFO.BUNDLE_NAME, ALIVE_EVENT_INFO.PERMISSIONS);
    });
  }

  onWorkStart(workInfo: workScheduler.WorkInfo) {
    LogUtil.warn(TAG, `onWorkStart`);
    try {
      commonEventManager.publish(EVENT_NAME.JUDGE_ALIVE_EVENT,
        { bundleName: ALIVE_EVENT_INFO.BUNDLE_NAME, subscriberPermissions: [ALIVE_EVENT_INFO.PERMISSIONS] },
        (err: BusinessError) => {
          if (err) {
            LogUtil.error(`Failed to publish common event. Code is ${err.code}, message is ${err.message}`);
            return;
          }
          LogUtil.info(TAG, `publish JUDGE_ALIVE_EVENT success`);
        });
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(`Failed to publish common event. Code is ${err.code}, message is ${err.message}`);
    }

    this.isRecorderAlive().then(async (res) => {
      const isRecording = res as boolean;
      LogUtil.info(TAG, `isRecording = ${isRecording}`);
      this.isRecorderAliveSub?.unsubscribe();
      if (isRecording) {
        return;
      }
      const state: boolean = SettingDataUtil.setSettingDataSync(this.context, SETTINGS_INPUT_SHOW_TOUCH_HINT, 'false');
      LogUtil.warn(TAG, `Set ShowTouch off ${state ? 'success' : 'fail'}`);
      if(state){
        try {
          workScheduler.stopAndClearWorks();
          LogUtil.warn(TAG, `stopAndClearWorks success`);
        } catch (e) {
          LogUtil.error(`Failed to stopAndClearWorks. Code is ${e.code}, message is ${e.message}`);
        }
      }
    }).catch(() => {
      LogUtil.error(TAG, ' get isRecording state failed, error ');
    })

  }

  onWorkStop(workInfo: workScheduler.WorkInfo) {
    LogUtil.info(TAG, `onWorkStop, workInfo is ${JSON.stringify(workInfo)}`);
  }
}