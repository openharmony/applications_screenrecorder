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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import { Driver, ON } from '@ohos.UiTest';
import { TestConstants } from './common/TestConstants';
import { Point } from '@kit.TestKit';
import { ExpansionScreenUtil } from '@ohos/screen-recorder';

const DELEGATOR: abilityDelegatorRegistry.AbilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();
const TAG: string = 'expandScreenDTTest';

// 副屏的卡片node id
const spliceScreenId: string = 'list_image_12_card';
// 选择模式的node id
const selectModeId: string = 'devicesSettings_selection';
// 扩展显示器
const expandScreenNodeId: string = 'Selection_MenuItem_2';
// 主屏
const mainScreenNodeId: string = 'Selection_MenuItem_0';
// 镜像屏选项
const mirrorScreenNodeId: string = 'Selection_MenuItem_1';
// 仅在xxx显示
const onlySecondScreenNodeId: string = 'Selection_MenuItem_10';
// 录屏悬浮胶囊停止按钮
const stopRecordId: string = 'id_stop_button';

const driver: Driver = Driver.create();

export default function abilityTest() {
  describe('expandScreenTest', () => {
    beforeAll(async () => {
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND)
      await startSettingModePage();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND)
      // 选择副屏的缩略图
      let btn = await driver.findComponent(ON.id(spliceScreenId));
      await btn?.click();
      // 打开选择模式menu 选择扩展屏
      await choseModeInSettings(expandScreenNodeId);
      console.log(TAG, `beforeAll`);
    })


    it('second_to_extend_second_screen_test', TestConstants.TEST_LEVEL_ONE, async () => {
      // 副屏（仅在xxx显示），录副屏--->副屏（扩展屏）。 预期结果：结束录屏。
      await selectFirstScreenModeAndStart(onlySecondScreenNodeId, false, TestConstants.DELAY_ONE_SECOND);
      await changeSecondScreenMode(expandScreenNodeId);
    })

    it('second_to_mirror_second_screen_test', TestConstants.TEST_LEVEL_ONE, async () => {
      // 副屏（仅在xxx显示），录副屏--->副屏（镜像屏）。 预期结果：结束录屏。
      await selectFirstScreenModeAndStart(onlySecondScreenNodeId, false, TestConstants.DELAY_ONE_SECOND);
      await changeSecondScreenMode(mirrorScreenNodeId);
    })

    // 设置扩展屏模式
    it('extend_to_mirror_first_screen_test', TestConstants.TEST_LEVEL_ONE, async () => {
      // 副屏（扩展屏），录主屏--->副屏（镜像屏）。 预期结果：继续录屏。
      await selectFirstScreenModeAndStart(expandScreenNodeId, false);
      await changeSecondScreenMode(mirrorScreenNodeId);
      await clickStopRecordButton();
    })

    it('mirror_to_expand_first_screen_test', TestConstants.TEST_LEVEL_ONE, async () => {
      // 副屏（镜像屏），录主屏--->副屏（扩展屏）。 预期结果：结束录屏。
      await selectFirstScreenModeAndStart(mirrorScreenNodeId, false);
      await changeSecondScreenMode(expandScreenNodeId);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await clickStopRecordButton();
    })

    it('mirror_to_second_first_screen_test', TestConstants.TEST_LEVEL_ONE, async () => {
      // 副屏（镜像屏），录主屏--->副屏（仅在xxx显示）。 预期结果：结束录屏。
      await selectFirstScreenModeAndStart(mirrorScreenNodeId, false, TestConstants.DELAY_ONE_SECOND);
      await changeSecondScreenMode(onlySecondScreenNodeId);
    })


    it('main_to_second_second_screen_test', TestConstants.TEST_LEVEL_ONE, async () => {
      // 副屏（主显示器），录副屏--->副屏（仅在xxx显示）。 预期结果：继续录屏。
      await selectFirstScreenModeAndStart(mainScreenNodeId, false);
      await changeSecondScreenMode(onlySecondScreenNodeId);
      await clickStopRecordButton();
    })

    it('second_to_main_second_screen_test', TestConstants.TEST_LEVEL_ONE, async () => {
      // 副屏（仅在xxx显示），录副屏--->副屏（主显示器）。 预期结果：继续录屏。(手动测试会继续录屏，dt会结束)
      await selectFirstScreenModeAndStart(onlySecondScreenNodeId, false);
      await changeSecondScreenMode(mainScreenNodeId);
    })

    it('extend_to_second_first_screen_test', TestConstants.TEST_LEVEL_ONE, async () => {
      // 副屏（扩展屏），录主屏--->副屏（仅在xxx显示）。 预期结果：结束录屏。
      await selectFirstScreenModeAndStart(expandScreenNodeId, false);
      await changeSecondScreenMode(onlySecondScreenNodeId);
    })

    it('extend_to_main_first_screen_test', TestConstants.TEST_LEVEL_ONE, async () => {
      // 副屏（扩展屏），录主屏--->副屏（主显示器）。 预期结果：结束录屏。
      await selectFirstScreenModeAndStart(expandScreenNodeId, false);
      await changeSecondScreenMode(mainScreenNodeId);
    })

    it('extend_to_mirror_second_screen_test', TestConstants.TEST_LEVEL_ONE, async () => {
      // 副屏（扩展屏），录副屏--->副屏（镜像屏）。 预期结果：结束录屏。
      await selectFirstScreenModeAndStart(expandScreenNodeId, true);
      await changeSecondScreenMode(mirrorScreenNodeId);
    })

    it('extend_to_second_second_screen_test', TestConstants.TEST_LEVEL_ONE, async () => {
      // 副屏（扩展屏），录副屏--->副屏（仅在xxx显示）。 预期结果：结束录屏。
      await selectFirstScreenModeAndStart(expandScreenNodeId, true);
      await changeSecondScreenMode(onlySecondScreenNodeId);
    })

    it('extend_to_main_second_screen_test', TestConstants.TEST_LEVEL_ONE, async () => {
      // 副屏（扩展屏），录副屏--->副屏（主显示器）。 预期结果：结束录屏。
      await selectFirstScreenModeAndStart(expandScreenNodeId, true);
      await changeSecondScreenMode(mainScreenNodeId);
    })

    it('main_to_mirror_first_screen_test', TestConstants.TEST_LEVEL_ONE, async () => {
      // 副屏（主显示器），录主屏--->副屏（镜像屏）。 预期结果：结束录屏。
      await selectFirstScreenModeAndStart(mainScreenNodeId, true);
      await changeSecondScreenMode(mirrorScreenNodeId);
    })


    it('main_to_expand_first_screen_test', TestConstants.TEST_LEVEL_ONE, async () => {
      // 副屏（主显示器），录主屏--->副屏（扩展屏）。 预期结果：结束录屏。
      await selectFirstScreenModeAndStart(mainScreenNodeId, true);
      await changeSecondScreenMode(expandScreenNodeId);
    })

    it('main_to_second_first_screen_test', TestConstants.TEST_LEVEL_ONE, async () => {
      // 副屏（主显示器），录主屏--->副屏（仅在xxx显示）。 预期结果：结束录屏。
      await selectFirstScreenModeAndStart(mainScreenNodeId, true);
      await changeSecondScreenMode(onlySecondScreenNodeId);
    })

    it('main_to_mirror_second_screen_test', TestConstants.TEST_LEVEL_ONE, async () => {
      // 副屏（主显示器），录副屏--->副屏（镜像屏）。 预期结果：结束录屏。
      await selectFirstScreenModeAndStart(mainScreenNodeId, false);
      await changeSecondScreenMode(mirrorScreenNodeId);
    })

    it('main_to_expand_second_screen_test', TestConstants.TEST_LEVEL_ONE, async () => {
      // 副屏（主显示器），录主屏--->副屏（扩展屏）。 预期结果：结束录屏。
      await selectFirstScreenModeAndStart(mainScreenNodeId, false);
      await changeSecondScreenMode(expandScreenNodeId);
    })


    beforeEach(async () => {
      console.log(TAG, `beforeEach`);
      // // 打开选择模式menu 选择扩展屏
      await choseModeInSettings(expandScreenNodeId);
      await driver.delayMs(TestConstants.DELAY_300_MILLISECOND)
    })

    afterEach(async () => {
      console.log(TAG, `afterEach`);
    })

    afterAll(() => {
      console.log(TAG, `afterAll`);
    })
  })

  const startSettingModePage = async () => {
    // 将Had链接扩展屏，打开设置窗口最大化。
    try {
      await driver.delayMs(TestConstants.DELAY_300_MILLISECOND)
      try {
        // 进入‘显示和亮度’页面
        await DELEGATOR.startAbility({
          'bundleName': TestConstants.SETTINGS_BUNDLE_NAME,
          'abilityName': TestConstants.SETTINGS_MAIN_ABILITY_NAME,
          'uri': TestConstants.DISPLAY_ENTRY,
        }).then(() => {
          console.info(` com.ohos.settings.MainAbility start success`);
        });
      } catch (error) {
        console.info(`Failed to startAbility.  { code: ${error?.code}, message: ${error?.message}}`);
      }
      await driver.delayMs(TestConstants.DELAY_300_MILLISECOND)
      // 选择副屏的缩略图
      let btn = await driver.findComponent(ON.id(spliceScreenId));
      await btn?.click();
    } catch (error) {
      console.info(`Failed to startAbility.failed: { code: ${error?.code}, message: ${error?.message}}`);
    }
  }

  /**
   * 选择模式录屏，然后切换模式
   *
   * @param modeNameOfStart 初始模式
   * @param isRecorderSecondScreen true 录副屏，false 录主屏
   */
  const selectFirstScreenModeAndStart =
    async (modeNameOfStart: string, isRecorderSecondScreen: boolean = false,
      delay: number = TestConstants.DELAY_300_MILLISECOND) => {

      // 打开选择模式menu 选择扩展屏
      await choseModeInSettings(modeNameOfStart);
      await driver.delayMs(delay);
      if (isRecorderSecondScreen) {
        // 选副屏录制
        await startRecordOnSecondScreen();
      } else {
        await clickDockBarRecordButton(0);
      }
    }

  const choseModeInSettings = async (itemNodeId: string) => {
    try {
      await driver.delayMs(TestConstants.DELAY_300_MILLISECOND);

      // 打开选择模式menu
      let btn = await driver.findComponent(ON.id(selectModeId));
      await btn?.click();
      await driver.delayMs(TestConstants.DELAY_300_MILLISECOND);
      // 选择1个选项
      btn = await driver.findComponent(ON.id(itemNodeId));
      await btn?.click();
      if (itemNodeId == onlySecondScreenNodeId) {
        await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      }
    } catch (error) {
      console.info(`choseModeInSettings .failed: { code: ${error?.code}, message: ${error?.message}}`);
    }
  }

  const startRecordOnSecondScreen = async () => {
    console.log(TAG, `startRecordOnSecondScreen`);
    await driver.delayMs(TestConstants.DELAY_300_MILLISECOND);
    let displays = await ExpansionScreenUtil.getAllDisplays();
    if (displays.length === 1) {
      await clickDockBarRecordButton(0);
      return;
    }
    let otherScreenId: number = (await ExpansionScreenUtil.getAllDisplays())[1]?.id;
    console.log(TAG, `otherScreenId ${otherScreenId}`);
    if (otherScreenId == undefined) {
      otherScreenId = 12;
      console.error(TAG, `set otherScreenId ${otherScreenId}`);
    }
    await clickDockBarRecordButton(otherScreenId);
  }

  const clickDockBarRecordButton = async (displayId: number) => {
    try {

      console.log(TAG, `clickRecordButton ${displayId}`);
      await driver.delayMs(TestConstants.DELAY_300_MILLISECOND);
      let btn = await driver.findComponent(ON.id('DockStatusBarComponent_arrowbutton'));
      await btn?.click();
      await driver.delayMs(TestConstants.DELAY_300_MILLISECOND);
      btn = await driver.findComponent(ON.id('RemotePluginComponent_PluginComponent_status_bar_pc_screenrecorder'));
      await btn?.click();
      await driver.delayMs(TestConstants.DELAY_300_MILLISECOND);
      let point: Point = {
        x: 2,
        y: 2,
        displayId
      };
      await driver.clickAt(point);
    } catch (error) {
      console.info(`clickRecordButton .failed: { code: ${error?.code}, message: ${error?.message}}`);
    }

  }

  const changeSecondScreenMode = async (itemNodeId: string) => {
    await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
    let stopRecordBtn = await driver.findComponent(ON.id(stopRecordId));
    expect(stopRecordBtn !== null).assertTrue();
    await choseModeInSettings(itemNodeId);
  }

  const clickStopRecordButton = async () => {
    try {
      await driver.delayMs(TestConstants.DELAY_300_MILLISECOND);
      let stopRecordBtn = await driver.findComponent(ON.id(stopRecordId));
      expect(stopRecordBtn !== null).assertTrue();
      await stopRecordBtn?.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
    } catch (error) {
      console.info(`clickStopRecordButton.failed: { code: ${error?.code}, message: ${error?.message}}`);
    }
  }
}



