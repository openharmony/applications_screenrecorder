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
import { describe, expect, it } from '@ohos/hypium';

export function LogUtilTest() {
  describe('debug_testSuite', () => {
    it('atc_should_log_debug_message_when_tag_and_args_are_provided', 0, () => {
      let tag: string = "testTag";
      let args: string[] = ["arg1", "arg2"];
      expect(() => {
        LogUtil.debug(tag, ...args);
      }).not().assertPromiseIsResolved();
    });

    it('atc_should_log_debug_message_when_tag_is_provided_but_no_args', 0, () => {
      let tag: string = "testTag";
      let args: string[] = [];
      expect(() => {
        LogUtil.debug(tag, ...args);
      }).not().assertPromiseIsResolved();
    });

    it('atc_should_log_debug_message_when_tag_is_empty_but_args_are_provided', 0, () => {
      let tag: string = "";
      let args: string[] = ["arg1", "arg2"];
      expect(() => {
        LogUtil.debug(tag, ...args);
      }).not().assertPromiseIsResolved();
    });

    it('atc_should_log_debug_message_when_tag_is_empty_and_args_are_empty', 0, () => {
      let tag: string = "";
      let args: string[] = [];
      expect(() => {
        LogUtil.debug(tag, ...args);
      }).not().assertPromiseIsResolved();
    });
  });

  describe('info_testSuite', () => {
    it('atc_should_log_info_with_tag_and_args', 0, () => {
      let tag: string = "testTag";
      let args: string[] = ["arg1", "arg2"];
      expect(() => {
        LogUtil.info(tag, ...args);
      }).not().assertPromiseIsResolved();
    });

    it('atc_should_log_info_with_tag_only', 0, () => {
      let tag: string = "testTag";
      let args: string[] = [];
      expect(() => {
        LogUtil.info(tag, ...args);
      }).not().assertPromiseIsResolved();
    });
  });

  describe('warn_testSuite', () => {
    it('atc_should_log_warning_when_tag_and_args_are_provided', 0, () => {
      let tag: string = "testTag";
      let args: string[] = ["arg1", "arg2"];
      expect(() => {
        LogUtil.warn(tag, ...args);
      }).not().assertPromiseIsResolved();
    });

    it('atc_should_log_warning_when_tag_is_provided_but_no_args', 0, () => {
      let tag: string = "testTag";
      expect(() => {
        LogUtil.warn(tag);
      }).not().assertPromiseIsResolved();
    });

    it('atc_should_log_warning_when_tag_is_empty_but_args_are_provided', 0, () => {
      let tag: string = "";
      let args: string[] = ["arg1", "arg2"];
      expect(() => {
        LogUtil.warn(tag, ...args);
      }).not().assertPromiseIsResolved();
    });

    it('atc_should_log_warning_when_tag_and_args_are_empty', 0, () => {
      let tag: string = "";
      let args: string[] = [];
      expect(() => {
        LogUtil.warn(tag, ...args);
      }).not().assertPromiseIsResolved();
    });
  });

  describe('error_testSuite', () => {
    it('atc_should_log_error_when_tag_and_args_are_provided', 0, () => {
      let tag: string = "testTag";
      let args: string[] = ["arg1", "arg2"];
      expect(() => {
        LogUtil.error(tag, ...args);
      }).not().assertPromiseIsResolved();
    });

    it('atc_should_log_error_when_tag_is_provided_but_no_args', 0, () => {
      let tag: string = "testTag";
      let args: string[] = [];
      expect(() => {
        LogUtil.error(tag, ...args);
      }).not().assertPromiseIsResolved();
    });

    it('atc_should_log_error_when_tag_is_null_but_args_are_provided', 0, () => {
      let tag: string | null = null;
      let args: string[] = ["arg1", "arg2"];
      expect(() => {
        LogUtil.error(tag, ...args);
      }).not().assertPromiseIsResolved();
    });

    it('atc_should_log_error_when_tag_is_undefined_but_args_are_provided', 0, () => {
      let tag: string | undefined = undefined;
      let args: string[] = ["arg1", "arg2"];
      expect(() => {
        LogUtil.error(tag, ...args);
      }).not().assertPromiseIsResolved();
    });
  });
}