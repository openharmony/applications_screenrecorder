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
import { GlobalThisUtil } from '@ohos/common';
import { describe, expect, it } from '@ohos/hypium';

export function GlobalThisUtilTest() {
  describe('globalThisUtil_test', () => {
    it('getInstance_test_with_return_same', 0, () => {
      let util1: GlobalThisUtil = GlobalThisUtil.getInstance();
      let util2: GlobalThisUtil = GlobalThisUtil.getInstance();
      expect(util1).assertEqual(util2);
    })

    it('setObject_test_with_same', 0, () => {
      try {
        GlobalThisUtil.getInstance().setObject('test', '123')
      } catch (e) {
        expect().assertFail();
      }
    })

    it('getObject_test_with_same', 0, () => {
      GlobalThisUtil.getInstance().setObject('test', '123');
      expect(GlobalThisUtil.getInstance().getObject('test')).assertEqual('123');
    })

    it('getObject_test_with_diff', 0, () => {
      GlobalThisUtil.getInstance().setObject('test', '123');
      GlobalThisUtil.getInstance().setObject('test', '456');
      expect(GlobalThisUtil.getInstance().getObject('test')).assertEqual('456');
    })
  })
}

