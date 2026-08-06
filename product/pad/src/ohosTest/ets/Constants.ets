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

import Want from '@ohos.app.ability.Want';

export class Constants {
  // 实况胶囊X轴
  public static readonly NOTIFICATION_X: number = 180;
  // 实况胶囊Y轴
  public static readonly NOTIFICATION_Y: number = 60;
  // 轨迹按钮键
  public static readonly TRACK_BUTTON_X: number = 760;
  // 麦克风按钮键
  public static readonly MIC_BUTTON_X: number = 920;
  // 停止按钮键
  public static readonly STOP_BUTTON_X: number = 1100;
  // 实况按钮Y轴
  public static readonly NOTIFICATION_BUTTON_Y: number = 250;

  // 全天开启
  public static readonly START_DARK_MODE_X: number = 1100;
  public static readonly START_DARK_MODE_Y: number = 640;

  // 深色模式
  public static readonly DARK_MODE_X: number = 620;
  public static readonly DARK_MODE_Y: number = 1120;

  // 顺时针旋转180、270
  public static readonly ROTATION_ONE: number = 1;
  public static readonly ROTATION_THREE: number = 3;

  // 音量增加键
  public static readonly KEYCODE_VOLUME_UP: number = 16;
  // 电源键
  public static readonly KEYCODE_POWER: number = 18;

  // 不被识别为左右Back手势的安全距离
  public static readonly BACK_SAFE_DISTANCE: number = 100;
  // 滑动速度-快速
  public static readonly SWIPE_SPEED_FAST: number = 10000;

  // 录屏按钮名称
  public static readonly SCREEN_RECORDER_BTN_NAME: string = '屏幕录制';
  // 录屏胶囊初始中心位置X
  public static readonly CAPSULE_WINDOW_ORIGIN_CENTER_X: number = 981;
  // 录屏胶囊初始中心位置Y
  public static readonly CAPSULE_WINDOW_ORIGIN_CENTER_Y: number = 273;
  // 录屏胶囊初始左上位置X
  public static readonly CAPSULE_WINDOW_ORIGIN_X: number = 729;
  // 录屏胶囊初始左上位置Y
  public static readonly CAPSULE_WINDOW_ORIGIN_Y: number = 208;
  // 录屏胶囊横向移动位置
  public static readonly CAPSULE_WINDOW_MOVE_X: number = -100;
  // 录屏胶囊纵向移动位置
  public static readonly CAPSULE_WINDOW_MOVE_Y: number = 200;
  // 切换语言位置X
  public static readonly SWITCH_LANGUAGE_X: number = 560;
  // 切换语言位置Y
  public static readonly SWITCH_LANGUAGE_Y: number = 760;
  // 通话按钮X
  public static readonly PHONE_CALL_BUTTON_X: number = 630;
  // 通话按钮Y
  public static readonly PHONE_CALL_BUTTON_Y: number = 2300;
  // 挂断按钮X
  public static readonly HAND_UP_BUTTON_X: number = 630;
  // 挂断按钮Y
  public static readonly HAND_UP_BUTTON_Y: number = 2500;
  // 拨号的电话，默认为空号
  public static readonly PHONE_NUMBER: string = '11111';

  // 设置->生物识别和密码->锁屏密码 界面 want
  public static readonly LOCK_SCREEN_PASSWORD_WANT: Want = {
    bundleName: 'com.ohos.settings',
    abilityName: 'com.ohos.settings.MainAbility',
    uri: 'lock_screen_password_title'
  }

  // 设置->显示与亮度
  public static readonly DARK_UI_MODE_WANT: Want = {
    bundleName: 'com.ohos.settings',
    abilityName: 'com.ohos.settings.MainAbility',
    uri: 'display_settings'
  }

  // 设置->语言与地区
  public static readonly LANGUAGES_AND_REGIONS_WANT: Want = {
    bundleName: 'com.ohos.settings',
    abilityName: 'com.ohos.settings.MainAbility',
    uri: 'set_language'
  }

  // 设置 -> 系统 -> 快捷启动与手势
  public static readonly OPEN_QUICK_GESTURES_WANT: Want = {
    bundleName: 'com.ohos.settings',
    abilityName: 'com.ohos.settings.MainAbility',
    uri: 'quick_gestures'
  }
}