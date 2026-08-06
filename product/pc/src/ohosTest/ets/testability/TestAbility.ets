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

import { GlobalThisUtil, LogUtil } from '@ohos/common';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import { Hypium } from '@ohos/hypium';
import testsuite from '../test/List.test';

type AbilityDelegator = AbilityDelegatorRegistry.AbilityDelegator;
type AbilityDelegatorArgs = AbilityDelegatorRegistry.AbilityDelegatorArgs;
const TAG = 'TestAbility';

/**
 * ScreenRecorder Test Ability
 *
 * @since 2023-07-15
 */
export default class TestAbility extends UIAbility {
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    LogUtil.info(TAG, 'TestAbility onCreate');
    this.globalThisInstance!.setObject('screenRecorderContext', this.context);
    const abilityDelegator: AbilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
    const abilityDelegatorArguments: AbilityDelegatorArgs = AbilityDelegatorRegistry.getArguments();

    LogUtil.info(TAG, 'start run testcase!!!');
    Hypium.hypiumTest(abilityDelegator, abilityDelegatorArguments, testsuite);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    LogUtil.info(TAG, 'TestAbility onWindowStageCreate');
    windowStage.loadContent('testability/pages/TestPage', (err, data) => {
      if (err.code) {
        LogUtil.error(TAG, 'Phone TestAbility, Failed to load the content. Cause: ', JSON.stringify(err) ?? '');
        return;
      }
      LogUtil.info(TAG, 'Phone TestAbility, Succeeded in loading the content. Data: ', JSON.stringify(data) ?? '');
    });
  }
}