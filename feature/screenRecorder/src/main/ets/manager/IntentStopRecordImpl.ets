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
import { EventReportUtil, LogUtil, StopRecordTriggerType } from '@ohos/common';
import { ERROR_CODE_NO_RECORDING, RecordManager } from './index';

const TAG: string = 'IntentStopRecordImpl';
const INTENT_HANDLE_SUCCESS_CODE: number = 0;
const INTENT_HANDLE_FAIL_CODE: number = 1;

/**
 * 处理小艺停止录屏意图
 */
export class IntentStopRecordImpl {
  /**
   * 小艺停止录屏意图处理
   *
   * @param recordManager 录屏管理类
   * @returns 意图处理结果
   */
  public static intentStopRecordHandle(recordManager: RecordManager): insightIntent.ExecuteResult {
    LogUtil.info(TAG, 'stop recorder');
    let result: insightIntent.ExecuteResult;
    try {
      EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_INSIGHT_INTENT_EXECUTOR);
      const res = recordManager.stopRecorder();
      result = {
        code: res ? INTENT_HANDLE_SUCCESS_CODE : ERROR_CODE_NO_RECORDING,
        result: {
          message: res ? 'Stop ScreenRecorder succeed.' : 'ScreenRecorder is not started',
        }
      }
      LogUtil.info(TAG, `stop recorder result: ${result.code}`);
    } catch (err) {
      LogUtil.error(TAG, `stop recorder failed, error: ${err?.code}`);
      result = {
        code: INTENT_HANDLE_FAIL_CODE,
        result: {
          message: 'Stop ScreenRecorder failed.',
        },
      };
    }
    return result;
  }
}