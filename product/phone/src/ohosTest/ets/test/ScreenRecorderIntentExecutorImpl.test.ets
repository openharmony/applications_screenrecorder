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

import {
  afterEach,
  describe,
  beforeEach,
  MockKit,
  it,
  expect,
  when, afterAll
} from '@ohos/hypium';
import { EventReportUtil, StartRecordTriggerType } from '@ohos/common';
import { INTENT_NAME_STOP, ERROR_CODE_NO_RECORDING, RecordManager } from '@ohos/screen-recorder';
import ScreenRecorderIntentExecutorImpl from '../../../main/ets/Insightintents/ScreenRecorderIntentExecutorImpl';

/**
 * 小艺录屏意图执行测试用例类
 *
 * @since 2025-12-13
 */
export default function ScreenRecorderIntentExecutorTest() {
  describe('onExecuteInServiceExtensionAbility', () => {
    const screenRecodeIntentName: string = 'ScreenRecord';
    let screenrecorderintentexecutorimpl: ScreenRecorderIntentExecutorImpl;
    let mocker: MockKit;

    beforeEach(() => {
      screenrecorderintentexecutorimpl = new ScreenRecorderIntentExecutorImpl();
      mocker = new MockKit();
    });

    afterEach(() => {
      mocker.clearAll();
    });

    afterAll(() => {
      EventReportUtil.setStartType(StartRecordTriggerType.TRIGGERED_TYPE_BY_CONTROL_CENTER);
    })

    it('atc_should_call_stop_handle_when_intent_is_screen_recode', 2, async () => {
      const result: ESObject =
        screenrecorderintentexecutorimpl.onExecuteInServiceExtensionAbility(screenRecodeIntentName, {});

      expect(result.code).assertEqual(0);
    });

    it('atc_should_call_stop_handle_when_intent_is_stop', 2, async () => {
      const result: ESObject =
        screenrecorderintentexecutorimpl.onExecuteInServiceExtensionAbility(INTENT_NAME_STOP, {});

      expect(result.code).assertEqual(ERROR_CODE_NO_RECORDING);
      expect(result.result.message).assertEqual('ScreenRecorder is not started');
    });

    it('atc_should_return_success_when_recordManager_not_exist', 2, () => {
      const mockStopRecorder: ESObject = mocker.mockFunc(RecordManager, RecordManager.getInstance);
      when(mockStopRecorder)().afterReturn(undefined);

      const result: ESObject =
        screenrecorderintentexecutorimpl.onExecuteInServiceExtensionAbility(screenRecodeIntentName, {});

      expect(result.code).assertEqual(0);
      expect(result.result.message).assertEqual('Start ScreenRecorder succeed.');
      mocker.clearAll();
    });
  });
}