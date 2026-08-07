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
  beforeEach,
  describe,
  expect,
  it,
  MockKit,
  when,
} from '@ohos/hypium';
import {
  ERROR_CODE_NO_RECORDING,
  RecordManager,
  IntentStopRecordImpl
} from '@ohos/screen-recorder';

/**
 * 小艺停止录屏意图实现类测试用例
 *
 * @since 2025-12-13
 */
export function IntentStopRecordImplTest() {
  describe('intent_stop_record_impl_Test', () => {
    let mocker: MockKit;
    let recordManager: RecordManager = RecordManager.getInstance();

    beforeEach(() => {
      mocker = new MockKit();
    });

    afterEach(() => {
      mocker.clearAll();
    });

    it('atc_should_return_success_when_stopRecorder_returns_true', 0, () => {
      const mockStopRecorder: ESObject = mocker.mockFunc(recordManager, recordManager.stopRecorder);
      when(mockStopRecorder)().afterReturn(true);

      const result: ESObject = IntentStopRecordImpl.intentStopRecordHandle(recordManager);

      expect(result.code).assertEqual(0);
      expect(result.result.message).assertEqual('Stop ScreenRecorder succeed.');
    });

    it('atc_should_return_error_when_stopRecorder_returns_false', 0, () => {
      const mockStopRecorder: ESObject = mocker.mockFunc(recordManager, recordManager.stopRecorder);
      when(mockStopRecorder)().afterReturn(false);

      const result: ESObject = IntentStopRecordImpl.intentStopRecordHandle(recordManager);

      expect(result.code).assertEqual(ERROR_CODE_NO_RECORDING);
      expect(result.result.message).assertEqual('ScreenRecorder is not started');
    });

    it('atc_should_return_fail_when_stopRecorder_throws_error', 0, () => {
      const mockStopRecorder: ESObject = mocker.mockFunc(recordManager, recordManager.stopRecorder);
      when(mockStopRecorder)().afterThrow('test error');

      const result: ESObject = IntentStopRecordImpl.intentStopRecordHandle(recordManager);

      expect(result.code).assertEqual(1);
      expect(result.result.message).assertEqual('Stop ScreenRecorder failed.');
    });
  });
}

