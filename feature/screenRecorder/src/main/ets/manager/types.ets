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

import { CommonUtil } from '@ohos/common';
import { CAPSULE_SHADOW_RADIUS } from '../components/Capsule/types';

export const VIDEO_SOURCE_RGB = 2;

export const FD_PREFIX = 'fd://';

export const TIME_LENGTH = 2;

export const TIME_PREFIX = '0';

export const SCREEN_RECORD_PREFIX = 'SVID';

export const SCREEN_RECORD_SUFFIX = '1';

export const VIDEO_TYPE = '.mp4';

export const CONNECTOR = '_';

export const VIRTUAL_SCREEN_NAME = 'screenRecord';

export const CAPSULE_PAGE = 'pages/CapsulePage';

export const PREVIEW_PAGE = 'pages/PreviewPage';

export const MASK_PAGE = 'pages/MaskPage';

export const SHARE_EMPTY_PAGE = 'pages/EmptyPage';

export const SHARE_UI_ABILITY_NAME = 'ShareUIAbility';

export const CAPSULE_WINDOW_NAME = 'CapsuleWindow';

export const PREVIEW_WINDOW_NAME = 'PreviewWindow';

export const MASK_WINDOW_NAME = 'MaskWindow';

export const TWO_SIDE = 2;

export interface ResolutionModel {
  maxSide: number;
  minSide: number;
}

// 分辨率方案
export class SupportResolution {
  public static readonly MODEL_1080P: ResolutionModel = { maxSide: 1920, minSide: 1080 };
  public static readonly MODEL_720P: ResolutionModel = { maxSide: 1280, minSide: 720 };
}

export interface CCMItem {
  name: string;
  key: string; // CCM系统key
  path: string; // CCM系统相对路径项
  type: string; // CCM系统参数值类型
  defaultValue?: string; // 默认值
}

export enum TabletScreenRecorderCCMResolution {
  DEFAULT = 0, // 默认采用720p
  MODEL_DEVICE = 1, // 采用设备分辨率
  MODEL_1080P = 2
}

export class CCM {
  // 平板录屏分辨率ccm配置项
  public static readonly TABLET_SCREEN_RECORDER_RESOLUTION: CCMItem = {
    name: 'tablet_screen_recorder_resolution',
    key: 'const.screenrecorder.resolution',
    path: 'etc/param/defaults.para',
    type: 'integer',
    defaultValue: '1',
  }

  // 录屏隐私遮蔽策略配置项
  public static readonly SCREEN_RECORDER_PRIVACY_STRATAGY: CCMItem = {
    name: 'screen_recorder_privacy_stratagy',
    key: 'const.screenrecorder.privacy_stratagy',
    path: 'etc/param/defaults.para',
    type: 'integer',
    defaultValue: '0',
  }
}

// The space reserved for shadows needs to be subtracted from the following three parameters:
const PHONE_MARGIN_VERTICAL = 12;
const TABLET_MARGIN_VERTICAL = 8;

export const CAPSULE_WINDOW_MARGIN_VERTICAL =
  (CommonUtil.checkIfDeviceIsPhone() ? PHONE_MARGIN_VERTICAL : TABLET_MARGIN_VERTICAL) -
    TWO_SIDE * CAPSULE_SHADOW_RADIUS; // Unit: vp

const PHONE_MARGIN_TOP = 68;
const TABLET_MARGIN_TOP = 60;

export const CAPSULE_WINDOW_MARGIN_TOP =
  (CommonUtil.checkIfDeviceIsPhone() ? PHONE_MARGIN_TOP : TABLET_MARGIN_TOP) -
    TWO_SIDE * CAPSULE_SHADOW_RADIUS; // Unit: vp

export const SCREEN_CUT_AREA_HEIGHT = 38;

export const GESTURE_AREA_HEIGHT = 38;

export const DISAPPEAR_INTERVAL = 3000;

export const WINDOW_BORDER_WIDTH = 6;

export const ZOOM_RATIO = 0.25;

export const STATE_BAR_HEIGHT = 60;

export const BUTTON_DISTANCE_FROM_BOTTOM_TV = 36;

export const BUTTON_DISTANCE_FROM_BOTTOM = 64;

export const PC_DOCK_BAR_HEIGHT = 88;

export const PC_DISTANCE_FROM_BOTTOM = PC_DOCK_BAR_HEIGHT + 24;

export const EXPANDING_NEW_FORMS_EXTERNAL_BOTTOM_MARGIN = 24;

export const SUCCESS_CODE = 0;

export const ERROR_CODE = 1;

const MIN_FREE_SPACE_IN_MB = 128; // 128 MB,the minimum free space required

export const MIN_FREE_SPACE_IN_BYTE = MIN_FREE_SPACE_IN_MB * 1024 * 1024;

export const WATCH_PERIOD = 1000;

const MAX_VIDEO_SIZE_IN_GB = 3; // 3 GB,the maximum video size

export const MAX_VIDEO_SIZE_IN_BYTE = MAX_VIDEO_SIZE_IN_GB * 1024 * 1024 * 1024;

export const TIME_TO_PREPARE_DATA = 200; // Time to wait for data from render-service

export const THUMB_WIDTH = 240;

export const THUMB_HEIGHT = 160;

export const THUMB_WIDTH_TV = 270;

export const THUMB_HEIGHT_TV = 149;

export interface FreeScreenArea {
  maxCoordinateX: number;
  maxCoordinateY: number;
  minCoordinateX: number;
  minCoordinateY: number;
}

export const HALF = 0.5;

export const COLOR_TRANSPARENT = '#00000000';

export const COLOR_MASK_BACKGROUND = '#664d4d4d';

export const COLOR_SHADOW = '#33000000';

export const MOVE_OUT_DURATION = 350;

export const FADE_OUT_DURATION = 150;

export const FADE_OUT_DELAY = 50;

export const FADE_OUT_OPACITY_START = 1;

export const FADE_OUT_OPACITY_END = 0;

export const SPRING_MASS = 1;

export const SPRING_STIFFNESS = 228;

export const SPRING_DAMPING = 30;

// 48是 pointer.PointerStyle.SCREENRECORDER_CURSOR
export const SCREENRECORDER_CURSOR = 48;

export const CURRENT_SELECTED_DISPLAY = 'currentSelectedDisplay';

export const MASKING_READY_TASK_ID = 'maskingReadyTaskId';

// Name for sub window
export const PREVIEW_SUB_WINDOW_NAME = 'ScreenRecorderSubWindow';

export const SHARE_WINDOW_NAME = 'ScreenRecorderShareWindow';

// Initialized position value
export const INIT_POSITION_VALUE = 0;

// Initialized scale value
export const INIT_SCALE_VALUE = 4;

// Initialized scale value
export const MIDDLE_SCALE_VALUE = 0.98;

// Initialized scale value
export const FINAL_SCALE_VALUE = 1;

// Position zoom ratio
export const POSITION_ZOOM_RATIO = 0.5;

// Initialized sub window blur value
export const INIT_SUB_WINDOW_BLUR_VALUE = 200;

// Do not set this parameter to 0. Otherwise, the blur effect will be turned off.
export const FINAL_SUB_WINDOW_BLUR_VALUE = 0.1;

export const POSITION_AND_SCALE_ANIMATION_TIMEOUT = 350;

export const SCALE_ANIMATION_DELAY = 350;

export const SCALE_ANIMATION_TIMEOUT = 250;

export const BLUR_ANIMATION_DELAY = 100;

export const BLUR_ANIMATION_TIMEOUT = 500;

export const SHARE_BUTTON_OPACITY_DELAY = 200;

export const SHARE_BUTTON_OPACITY_TIMEOUT = 150;

export const INIT_THUMB_BORDER_OPACITY_VALUE = 0;

export const FINAL_THUMB_BORDER_OPACITY_VALUE = 1;

export const OPACITY_ANIMATION_DELAY = 100;

export const OPACITY_ANIMATION_TIMEOUT = 100;

export const FONT_SIZE_UNIT = 'px';

export const CONTROL_PANEL_FADE_OUT_TIME = 400;

export const DEFAULT_TRIGGER_TYPE = 'default_trigger_type';

export const AI_TRIGGER_TYPE = 'ai_dispatch_trigger';

export const LIGHT_NOTIFICATION_COLOR = '#E84026';

export const DARK_NOTIFICATION_COLOR = '#D94838';

export const MOVEOUT_THRESHOLD = 3;

// if version is 15 or later, need to use new snapshot interface.
export const VALIDATE_SDK_VERSION = 15;

export const SELECT_DISPLAY_ID = 'selectDisplayId';

/**
 * 解决悬浮窗显示时会获焦问题，导致其他界面失焦消失
 * 修改方案：显示前先设置窗口无法获焦，显示后，延时100ms再设置可获焦
 * (此为规避方案，等升级API20后考虑切换新接口)
 */
export const CAPSULE_WINDOW_SET_FOCUS_ABLE_DELAY = 100;

// 小艺语音停止录屏意图名称
export const INTENT_NAME_STOP: string = 'StopScreenRecord';

// 小艺语音停止录屏没有录屏结果码，前4位1033为小艺分配给录屏的应用编码，后4位为错误码
export const ERROR_CODE_NO_RECORDING: number = 10330001;