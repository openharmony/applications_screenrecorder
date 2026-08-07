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

import { KeyCode } from '@ohos.multimodalInput.keyCode';

/**
 * GlobalThisHelper
 *
 * @since 2025-04-23
 */
export class InputUtil {
  /**
   * 重新定义用户输入的字符
   *
   * @param keyCode 用户输入的字符code
   * @param isShiftPressed 是否按shift
   * @return 重定义的字符
   */

  private static keyCodeMap = new Map<number, string>()
    .set(KeyCode.KEYCODE_ESCAPE, 'C')
    .set(KeyCode.KEYCODE_DEL, '')
    .set(KeyCode.KEYCODE_FORWARD_DEL, 'C')
    .set(KeyCode.KEYCODE_NUMPAD_DIVIDE, '÷')
    .set(KeyCode.KEYCODE_SLASH, '÷')
    .set(KeyCode.KEYCODE_NUMPAD_MULTIPLY, '×')
    .set(KeyCode.KEYCODE_NUMPAD_SUBTRACT, '-')
    .set(KeyCode.KEYCODE_MINUS, '-')
    .set(KeyCode.KEYCODE_NUMPAD_ADD, '+')
    .set(KeyCode.KEYCODE_PLUS, '+')
    .set(KeyCode.KEYCODE_NUMPAD_DOT, '.')
    .set(KeyCode.KEYCODE_PERIOD, '.')
    .set(KeyCode.KEYCODE_5, '5')
    .set(KeyCode.KEYCODE_8, '8')
    .set(KeyCode.KEYCODE_9, '9')
    .set(KeyCode.KEYCODE_0, '0')
    .set(KeyCode.KEYCODE_EQUALS, '=')
    .set(KeyCode.KEYCODE_NUMPAD_ENTER, '(')
    .set(KeyCode.KEYCODE_NUMPAD_EQUALS, '(')
    .set(KeyCode.KEYCODE_NUMPAD_LEFT_PAREN, '(')
    .set(KeyCode.KEYCODE_NUMPAD_RIGHT_PAREN, ')');

  private static keyCodeMapShiftPressed = new Map<number, string>()
    .set(KeyCode.KEYCODE_ESCAPE, 'C')
    .set(KeyCode.KEYCODE_DEL, '')
    .set(KeyCode.KEYCODE_FORWARD_DEL, 'C')
    .set(KeyCode.KEYCODE_NUMPAD_DIVIDE, '÷')
    .set(KeyCode.KEYCODE_SLASH, '÷')
    .set(KeyCode.KEYCODE_NUMPAD_MULTIPLY, '×')
    .set(KeyCode.KEYCODE_NUMPAD_SUBTRACT, '-')
    .set(KeyCode.KEYCODE_MINUS, '-')
    .set(KeyCode.KEYCODE_NUMPAD_ADD, '+')
    .set(KeyCode.KEYCODE_PLUS, '+')
    .set(KeyCode.KEYCODE_NUMPAD_DOT, '.')
    .set(KeyCode.KEYCODE_PERIOD, '.')
    .set(KeyCode.KEYCODE_5, '%')
    .set(KeyCode.KEYCODE_8, '×')
    .set(KeyCode.KEYCODE_9, '(')
    .set(KeyCode.KEYCODE_0, ')')
    .set(KeyCode.KEYCODE_EQUALS, '+')
    .set(KeyCode.KEYCODE_NUMPAD_ENTER, '(')
    .set(KeyCode.KEYCODE_NUMPAD_EQUALS, '(')
    .set(KeyCode.KEYCODE_NUMPAD_LEFT_PAREN, '(')
    .set(KeyCode.KEYCODE_NUMPAD_RIGHT_PAREN, ')');

  public static keyForString(keyCode: number, isShiftPressed: boolean): string {
    let result: string;
    if (isShiftPressed) {
      result = this.keyCodeMapShiftPressed.get(keyCode);
    } else {
      result = this.keyCodeMap.get(keyCode);
    }
    if (result === undefined || result === null) {
      if (keyCode >= KeyCode.KEYCODE_NUMPAD_0 && keyCode <= KeyCode.KEYCODE_NUMPAD_9) {
        result = (keyCode - KeyCode.KEYCODE_NUMPAD_0).toString();
      }
      if (keyCode >= KeyCode.KEYCODE_0 && keyCode <= KeyCode.KEYCODE_9) {
        result = (keyCode - KeyCode.KEYCODE_0).toString();
      }
    }
    return result === null || result === undefined ? 'error' : result;
  }

  /**
   * 重新定义用户输入的字符包含回车键
   *
   * @param keyCode 用户输入的字符code
   * @param isShiftPressed 是否按shift
   * @param isShiftPressed 是否按shift
   * @return 重定义的字符
   */
  public static keyToString(keyCode: number, isShiftPressed: boolean): string {
    if (keyCode === KeyCode.KEYCODE_ENTER || keyCode === KeyCode.KEYCODE_NUMPAD_ENTER) {
      return '=';
    } else {
      return this.keyForString(keyCode, isShiftPressed);
    }
  }
}