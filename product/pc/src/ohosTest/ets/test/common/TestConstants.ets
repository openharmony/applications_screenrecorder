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

export class TestConstants {
  // TAG
  public static readonly TAG = 'DTTest';
  // 测试用例级别 0
  public static readonly MAIN_DISPLAY_ID: number = 0;
  public static readonly TEST_LEVEL_ZERO: number = 0;
  // 测试用例级别 1
  public static readonly TEST_LEVEL_ONE: number = 1;
  // 测试用例级别 2
  public static readonly TEST_LEVEL_TWO: number = 2;
  // 延迟 300MS
  public static readonly DELAY_300_MILLISECOND: number = 300;
  // 延迟 100MS
  public static readonly DELAY_100_MILLISECOND: number = 100;
  // 延迟 1s
  public static readonly DELAY_ONE_SECOND: number = 1000;
  // 延迟 2s
  public static readonly DELAY_TWO_SECOND: number = 2000;
  // 延迟 3s
  public static readonly DELAY_THREE_SECOND: number = 3000;
  // 延迟 4s
  public static readonly DELAY_FOUR_SECOND: number = 4000;
  // 延迟 5s
  public static readonly DELAY_FIVE_SECOND: number = 5000;
  // 音量减小键
  public static readonly KEYCODE_VOLUME_DOWN: number = 17;
  // 电源键
  public static readonly KEYCODE_POWER: number = 18;
  // F10
  public static readonly KEYCODE_F10: number = 2099;
  // 滑动速度-快速
  public static readonly SWIPE_SPEED_FAST: number = 10000;
  // 拖拽速度-最快速
  public static readonly DRAG_SPEED_FASTEST: number = 40000;
  // 不被识别为左右Back手势的安全距离
  public static readonly BACK_SAFE_DISTANCE: number = 100;
  // 折叠屏类型参数：ICL
  public static readonly FOLD_SCREEN_TYPE_ICL = '1,2,0,0';
  // 折叠屏类型参数：LEM
  public static readonly FOLD_SCREEN_TYPE_LEM = '2,2,0,0';
  // 折叠屏类型参数：HPR
  public static readonly FOLD_SCREEN_TYPE_HPR = '5,2,0,0';
  // 折叠屏类型参数：VDE
  public static readonly FOLD_SCREEN_TYPE_VDE = '4,2,0,0';
  // 折叠屏类型参数：GRL
  public static readonly FOLD_SCREEN_TYPE_GRL = '6,1,0,0';
  // 折叠屏类型参数key
  public static readonly FOLD_SCREEN_PRODUCT_PROPERTY = 'const.window.foldscreen.type';
  static readonly SETTINGS_BUNDLE_NAME: string = 'com.ohos.settings';
  static readonly SETTINGS_MAIN_ABILITY_NAME: string = 'com.ohos.settings.MainAbility';
  static readonly DISPLAY_ENTRY = 'display_settings'
  public static readonly SELECT_DISPLAY_ID = 'selectDisplayId';
  public static readonly IS_RECORDING = 'isRecording';
  // 设置->主界面 want
  public static readonly SETTINGS_MAIN_WANT: Want = {
    bundleName: 'com.ohos.settings',
    abilityName: 'com.ohos.settings.MainAbility',
  }
}

