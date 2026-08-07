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
import { describe, expect, it } from '@ohos/hypium';
import ExtAbilityProxy from '../../../main/ets/proxy/ExtAbilityProxy';

export function ScreenRecorderAbilityTest() {
  describe('ScreenRecorderAbilityTest', () => {
    it('test_undefined_name', 0, () => {
      expect(ExtAbilityProxy.checkFileName(undefined)).assertTrue();
    })

    it('test_legitimate_name', 0, () => {
      expect(ExtAbilityProxy.checkFileName('zhhgg.mp4')).assertTrue();
    })

    it('test_exceed_max_length_name', 0, () => {
      let fileName: string = 'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz' +
        'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz' +
        'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz';
      expect(ExtAbilityProxy.checkFileName(fileName)).assertFalse();
    })

    it('test_illegal_start_name', 0, () => {
      expect(ExtAbilityProxy.checkFileName('.124')).assertFalse();
    })

    it('test_illegal_name', 0, () => {
      expect(ExtAbilityProxy.checkFileName('[zhsg.mp4')).assertFalse();
    })

    it('test_illegal_end_name', 0, () => {
      expect(ExtAbilityProxy.checkFileName('zhahsh.mp3')).assertFalse();
    })
  })
}

