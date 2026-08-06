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
import { Trace, TraceConst } from '@ohos/common';
import { describe, expect, it } from '@ohos/hypium';

export function TraceTaskTest() {
  describe('trace_test', () => {
    it('trace_test_with_no_id', 0, () => {
      const startTime = Date.now();
      Trace.begin(TraceConst.START_SCREEN_RECORDING_TRACE_MEDIA);
      Trace.end(TraceConst.START_SCREEN_RECORDING_TRACE_MEDIA);
      const endTime = Date.now();
      expect(endTime).not().assertLess(startTime);
    });

    it('trace_test_with_id_name_exit', 0, () => {
      const startTime = Date.now();
      Trace.begin(TraceConst.START_SCREEN_RECORDING_TRACE_MEDIA);
      Trace.end('stop_trace');
      Trace.end(TraceConst.START_SCREEN_RECORDING_TRACE_MEDIA);
      const endTime = Date.now();
      expect(endTime).not().assertLess(startTime);
    })
  })
}

