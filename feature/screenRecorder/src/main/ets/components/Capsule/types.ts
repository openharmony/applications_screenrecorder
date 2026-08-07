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

export const CAPSULE_DIVIDER_WIDTH = 0.5; // Unit: Vp
export const CAPSULE_SHADOW_RADIUS = 2; // Unit: Vp
export const CAPSULE_WINDOW_HEIGHT = 40; // Unit: Vp

const MINUTES_IN_ONE_HOUR = 60;
export const SECONDS_IN_ONE_MINUTE = 60;
export const MILLISECONDS_IN_ONE_SECOND = 1000;
export const MILLISECONDS_IN_ONE_HOUR = MINUTES_IN_ONE_HOUR * SECONDS_IN_ONE_MINUTE * MILLISECONDS_IN_ONE_SECOND;

export const HOUR_TO_SECONDS = MINUTES_IN_ONE_HOUR * SECONDS_IN_ONE_MINUTE;

// Two times the blur radius is reserved on both sides of the shadow area, which adds up to four times the blur radius.
export const RESERVED_SPACE_MULTIPLES = 4;

export const TWINKLE_INTERVAL = 500; // Unit: millisecond
export const ONE_SECOND = 1;

export const TIME_SEPARATOR = ':';

export const TIME_LENGTH = 2;

export const ZERO_TIME_TEXT = '00:00';
