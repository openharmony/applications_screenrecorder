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

import { CommonUtil, GlobalThisUtil, LogUtil, PreferencesKey, PreferenceUtils } from '@ohos/common';
import lazy { ConfigurationConstant } from '@kit.AbilityKit';
import lazy { LengthMetrics } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import common from '@ohos.app.ability.common';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import Want from '@ohos.app.ability.Want';
import dataPreferences from '@ohos.data.preferences';
import lazy uiEffect from '@ohos.graphics.uiEffect';
// import lazy { hdsEffect } from '@kit.UIDesignKit';

/**
 * 控制中心二级页header部分浅色模式提亮参数
 */
// const brightnessBlenderHeader: uiEffect.BrightnessBlender = uiEffect.createBrightnessBlender({
//   linearRate: 0.4,
//   degree: -0.098,
//   cubicRate: 0,
//   quadraticRate: 0,
//   fraction: 0,
//   saturation: 1.5,
//   positiveCoefficient: [1.9, 3.8, 1.3],
//   negativeCoefficient: [0.5, 0.67, 1.3]
// });

/**
 * 控制中心二级页header部分深色模式提亮参数
 */
// const brightnessBlenderHeaderDark: uiEffect.BrightnessBlender = uiEffect.createBrightnessBlender({
//   linearRate: 0.1239,
//   degree: 0.8988,
//   cubicRate: 0,
//   quadraticRate: 0,
//   fraction: 0,
//   saturation: 2,
//   positiveCoefficient: [1.6, 3, 1.5],
//   negativeCoefficient: [1.2, 1.2, 1]
// });
/* instrument ignore file */
const TAG: string = 'ControlPhone';
const PREFERENCES_NAME = 'myPreferences';
const CONTROL_CENTER_BUTTON_TITLE: string = 'control_center_button_title';

@Component
export struct ControlPhone {
  @State isMicEnabled: boolean = false;
  @State showTouchState: boolean = true;
  @State isRecording: boolean = false;
  @State visualEffectCard: uiEffect.VisualEffect = uiEffect.createEffect();
  @State visualEffectCardDark: uiEffect.VisualEffect = uiEffect.createEffect();
  @State isDarkMode: boolean = false;
  private dataPreferences: PreferenceUtils = new PreferenceUtils();
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private context: common.UIExtensionContext =
    this.globalThisInstance!.getObject('screenRecorderControlContext') as common.UIExtensionContext;
  private isDarkModeForBlend: boolean =
    (!!(this.globalThisInstance!.getObject('screenRecorderControlWant') as Want)?.parameters?.isShowAsDarkMode);
  private session: UIExtensionContentSession =
    this.globalThisInstance!.getObject('screenRecorderControlSession') as UIExtensionContentSession;
  private preferenceListen: dataPreferences.Preferences | null = null;

  async aboutToAppear(): Promise<void> {
    LogUtil.info(TAG, 'ControlPhone aboutToAppear');
    this.isDarkMode = this.getDarkMode();
    LogUtil.info(TAG, `isDarkMode: ${this.isDarkMode}`);
    let blender: uiEffect.BrightnessBlender =
      uiEffect.createBrightnessBlender({
        cubicRate: 0,
        quadraticRate: 0,
        linearRate: 1,
        degree: -15 / 255,
        saturation: 1.2,
        fraction: 0,
        positiveCoefficient: [0.4, 0.5, 0.5],
        negativeCoefficient: [0.3, 1, 1]
      })
    let blenderDark: uiEffect.BrightnessBlender =
      uiEffect.createBrightnessBlender({
        cubicRate: 0,
        quadraticRate: 0,
        linearRate: 1,
        degree: 15 / 255,
        saturation: 1,
        fraction: 0,
        positiveCoefficient: [1, 0.7, 1],
        negativeCoefficient: [1, 1, 1]
      })
    this.visualEffectCard.backgroundColorBlender(blender);
    this.visualEffectCardDark.backgroundColorBlender(blenderDark);

    PreferenceUtils.getValue(this.context, 'isMicEnabled', false).then(async (enabled) => {
      this.isMicEnabled = enabled as boolean;
      LogUtil.info(TAG, ' isMicOn = ' + enabled);
    }).catch(() => {
      LogUtil.error(TAG, ' get isMicEnabled failed, error ');
    })

    PreferenceUtils.getValue(this.context, 'showTouchState', 'true').then(async (enabled) => {
      this.showTouchState = enabled === 'true' ? true : false;
      LogUtil.info(TAG, ' isTrackOn = ' + enabled);
    }).catch(() => {
      LogUtil.error(TAG, ' get showTouchState failed, error ');
    })

    try {
      this.setRecordingState();
      this.preferenceListen = await dataPreferences.getPreferences(this.context, PREFERENCES_NAME);
      this.preferenceListen.on('multiProcessChange', this.recordingStateObserver);
    } catch (error) {
      LogUtil.error(TAG, 'aboutToAppear preferenceListen error:' + (error as BusinessError).message);
    }
    CommonUtil.requestFocusAccessibilityWithBundleName(CONTROL_CENTER_BUTTON_TITLE, 'com.ohos.sceneboard');
  }

  private async setRecordingState(): Promise<void> {
    let recordingTimestamp = await PreferenceUtils.getValue(this.context, PreferencesKey.RECORDING_TIMESTAMP, 0, true);
    recordingTimestamp = recordingTimestamp as number;
    if (Date.now() - recordingTimestamp < 1100) {
      this.isRecording = true;
      LogUtil.info(TAG + ' The screen displays End Recording ')
    } else {
      this.isRecording = false;
      LogUtil.info(TAG + ' The screen displays Start Recording ')
    }
  }

  private recordingStateObserver = async (key: string) => {
    if (key === PreferencesKey.IS_RECORDING) {
      this.isRecording = !this.isRecording;
      LogUtil.info(TAG + ' Update the new status of isRecording ' + this.isRecording)
      return;
    }
  }

  async aboutToDisappear(): Promise<void> {
    this.preferenceListen!.off('multiProcessChange', this.recordingStateObserver);
  }

  private getDarkMode(): boolean {
    return this.context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  async onMicChange(value: boolean) {
    try {
      if (value) {
        LogUtil.info(TAG, 'mic value is true');
        await this.dataPreferences.setPreferenceKeyValue('isMicEnabled', true, this.context);
      } else {
        LogUtil.info(TAG, 'mic value is false');
        await this.dataPreferences.setPreferenceKeyValue('isMicEnabled', false, this.context);
      }
    } catch (err) {
      LogUtil.error(TAG, `The mic switch changes abnormally: ${err.code}`);
    }
  }

  async onTraceChange(value: boolean) {
    try {
      if (value) {
        LogUtil.info(TAG, 'track value is true');
        await this.dataPreferences.setPreferenceKeyValue('showTouchState', 'true', this.context);
      } else {
        LogUtil.info(TAG, 'track value is false');
        await this.dataPreferences.setPreferenceKeyValue('showTouchState', 'false', this.context);
      }
    } catch (err) {
      LogUtil.error(TAG, `The trace switch changes abnormally: ${err.code}`);
    }
  }

  build() {
    Column() {
      RelativeContainer() {
        this.headView();
        this.contentView();
        this.bottomView();
      }
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  headView() {
    Column() {
      Image($r('app.media.dot_video_fill'))
        .width(24)
        .height(24)
        .draggable(false)
        .fillColor($r('sys.color.black'))
        // .advancedBlendMode(uiEffect.createBrightnessBlender(hdsEffect.getBrightnessParam({
        //   scenario: hdsEffect.BrightnessScenario.FOREGROUND_BRIGHTNESS,
        //   level: hdsEffect.BrightnessLevel.BRIGHTNESS_LEVEL_1,
        //   fraction: 0,
        //   isDarkMode: this.isDarkModeForBlend || this.isDarkMode
        // })))
        .margin({ bottom: 8 })
        .align(Alignment.Center)
        .objectFit(ImageFit.Contain)
        .matchTextDirection(true)
      Text($r('app.string.control_icon_name'))
        .fontSize(20)
        .fontColor($r('sys.color.black'))
        // .advancedBlendMode(uiEffect.createBrightnessBlender(hdsEffect.getBrightnessParam({
        //   scenario: hdsEffect.BrightnessScenario.FOREGROUND_BRIGHTNESS,
        //   level: hdsEffect.BrightnessLevel.BRIGHTNESS_LEVEL_1,
        //   fraction: 0,
        //   isDarkMode: this.isDarkModeForBlend || this.isDarkMode
        // })))
        .align(Alignment.Center)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(600) // SemiBold
        .maxFontScale(1)
        .minFontScale(1)
        .lineHeight(27)
        .id(CONTROL_CENTER_BUTTON_TITLE)
    }
    .alignRules({
      top: { anchor: '__container__', align: VerticalAlign.Top }
    })
    .id('headView')
    .width('100%')
    .padding({ top: 16, bottom: 15.5 })
  }

  @Builder
  contentView() {
    Column() {
      List() {
        this.listItemContent(true)
        this.listItemContent(false)
      }
      .backgroundColor('#FFFFFFFF')
      .borderRadius(16)
      .margin({ left: 12, right: 12 })
      .divider({
        strokeWidth: '1px',
        color: $r('sys.color.ohos_id_color_list_separator'),
        startMargin: 12,
        endMargin: 12
      })
      .padding({ top: 4, bottom: 4 })
      // .visualEffect(uiEffect.createEffect().backgroundColorBlender(hdsEffect.getBrightnessParam({
      //   scenario: hdsEffect.BrightnessScenario.BACKGROUND_BRIGHTNESS,
      //   level: hdsEffect.BrightnessLevel.BRIGHTNESS_LEVEL_7,
      //   fraction: 0,
      // })))
    }
    .justifyContent(FlexAlign.Center)
    .alignRules({
      top: { anchor: 'headView', align: VerticalAlign.Bottom },
      bottom: { anchor: 'bottomView', align: VerticalAlign.Top }
    })
  }

  @Builder
  listItemContent(isMicItem: boolean) {
    ListItem() {
      Row() {
        Text(isMicItem ? $r('app.string.pre_authorization_dialog_mic_permission') :
          $r('app.string.control_track_button'))
          .maxFontScale(1.45)
          .minFontScale(1)
          .maxLines(2)
          .width(180)
          .fontColor($r('sys.color.black'))
          .fontWeight(FontWeight.Medium)
          .margin({ start: LengthMetrics.vp(12) })
          // .advancedBlendMode(uiEffect.createBrightnessBlender(hdsEffect.getBrightnessParam({
          //   scenario: hdsEffect.BrightnessScenario.FOREGROUND_BRIGHTNESS,
          //   level: hdsEffect.BrightnessLevel.BRIGHTNESS_LEVEL_1,
          //   fraction: 0,
          //   isDarkMode: this.isDarkModeForBlend || this.isDarkMode
          // })));
        Toggle({ type: ToggleType.Switch, isOn: isMicItem ? this.isMicEnabled : this.showTouchState })
          .switchStyle({
            unselectedColor: $r('sys.color.comp_background_secondary')
          })
          .selectedColor($r('app.color.control_page_switch_color'))
          .onChange(async (isOn: boolean) => {
            LogUtil.info('Component status:' + isOn + ' isMicItem:' + isMicItem);
            if (isMicItem) {
              await this.onMicChange(isOn);
            } else {
              await this.onTraceChange(isOn);
            }
          })
          .margin({ end: LengthMetrics.vp(12) });
      }.constraintSize({
        minHeight: '48%'
      })
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
  }

  @Builder
  bottomView() {
    Column() {
      Text(this.isRecording ? $r('app.string.control_stop_recording') : $r('app.string.control_start_recording'))
        .width('100%')
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Medium)
        .fontSize(16)
        .fontColor(this.isDarkModeForBlend || this.isDarkMode ? $r('sys.color.white') :
          $r('app.color.control_page_button_text_color'))
        .textAlign(TextAlign.Center)
        .padding({ top: 9, bottom: 10 })
        .maxFontScale(1)
        .minFontScale(1)
        .lineHeight(21)
        .stateStyles({
          clicked: {
            .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
            .borderRadius(20)
          }, pressed: {
            .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
            .borderRadius(20)
          }, normal: {
            .backgroundColor('#00000000')
          }
        })
        .onClick(() => {
          this.session.sendData({
            'method': 'hideControlCenter',
          });
          let want: Want = {
            bundleName: 'com.ohos.screenrecorder',
            abilityName: 'com.ohos.screenrecorder.ServiceExtAbility',
          };
          this.context.startServiceExtensionAbility(want).then(() => {
            LogUtil.debug(TAG, `Screen recording invoked successfully.`);
          }).catch(() => {
            LogUtil.debug(TAG, `Failed to invoke screen recording.`);
          });
        })
    }
    .alignItems(HorizontalAlign.Center)
    .margin({
      left: 16,
      right: 16,
      top: 9,
      bottom: 16
    })
    .alignRules({
      bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
    })
    .id('bottomView')
  }
}