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

// @ts-nocheck

/* instrument ignore file */
const brightnessDarkParam: BrightnessOptions = {
  rate: -0.2067,
  lightUpDegree: 0.14,
  cubicCoeff: -0.6667,
  quadCoeff: 1.3333,
  saturation: 1.4,
  posRGB: [0.3, 0.5, 0.8],
  negRGB: [0.3, 1, 1],
  fraction: 0,
};

const brightnessLightParam: BrightnessOptions = {
  rate: 0.2873,
  lightUpDegree: 0.6793,
  cubicCoeff: 0,
  quadCoeff: 0,
  fraction: 0,
  saturation: 2.0,
  posRGB: [1, 0.5, 1],
  negRGB: [1.2, 1.2, 1],
};

export class BackgroundModifier implements AttributeModifier<CommonAttribute> {
  isDark: boolean = false;

  constructor(dark?: boolean) {
    this.isDark = dark ? dark : false;
  }

  applyNormalAttribute(instance: CommonAttribute): void {
    if (this.isDark) {
      instance.backgroundBrightnessInternal(brightnessDarkParam);
    } else {
      instance.backgroundBrightnessInternal(brightnessLightParam);
    }
  }
}