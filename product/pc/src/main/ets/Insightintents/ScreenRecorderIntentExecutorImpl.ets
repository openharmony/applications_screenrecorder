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

import insightIntent from '@ohos.app.ability.insightIntent';
import InsightIntentExecutor from '@ohos.app.ability.InsightIntentExecutor';
import screenLock from '@ohos.screenLock';
import {
  EventReportUtil,
  LogUtil,
  StartRecordTriggerType,
} from '@ohos/common';
import {
  AI_TRIGGER_TYPE,
  INTENT_NAME_STOP,
  PcRecordManager,
  IntentStopRecordImpl,
} from '@ohos/screen-recorder';

/* instrument ignore file */
const TAG: string = 'IntentExecutor-ScreenRecorder';

export default class ScreenRecorderIntentExecutorImpl extends InsightIntentExecutor {
  private recordManager: PcRecordManager = PcRecordManager.getInstance();

  onExecuteInServiceExtensionAbility(name: string, param: Record<string, Object>):
  insightIntent.ExecuteResult | Promise<insightIntent.ExecuteResult> {
    LogUtil.warn(TAG, `IntentName: ${name}`);

    let result: insightIntent.ExecuteResult;
    result = {
      code: 0,
      result: {
        message: 'Start ScreenRecorder succeed.',
      }
    };

    if (screenLock.isLocked()) {
      LogUtil.info(TAG, 'The screen is locked, so the screen recording request will not be responded to.');
      return result;
    }

    if (!this.recordManager) {
      LogUtil.error(TAG, 'Execute serviceExtension in background mode failed, result:' + result.code);
      return result;
    }

    if (name === INTENT_NAME_STOP) {
      return IntentStopRecordImpl.intentStopRecordHandle(this.recordManager);
    }

    EventReportUtil.setStartType(StartRecordTriggerType.TRIGGERED_TYPE_BY_AI);
    this.recordManager!.trigger(AI_TRIGGER_TYPE, undefined, false);
    LogUtil.info(TAG, 'Execute serviceExtension in background mode finished, result:' + result.code);
    return result;
  }
}