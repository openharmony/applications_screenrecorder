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
import { curves, LengthMetrics } from '@kit.ArkUI';
import { emitter } from '@kit.BasicServicesKit';
import { BackgroundModifier } from '../selectPanelUtil/BackgroundModifier';
import { windowManager } from '../selectPanelUtil/SelectPanelWindowManager';
import { SystemConfig } from '../selectPanelUtil/SystemConfig';

/* instrument ignore file */
const TAG = 'ScreenRecorder-ScreenRecorderSelectPanel';
const HPR_B_SCREEN_ID = 0;
const HPR_C_SCREEN_ID = 999;
const FULL_SCREEN_RECORDER_SHORTCUT = 'F10';
const SELECT_PANEL_WINDOW_WIDTH = 360;
const SELECT_PANEL_WINDOW_HEIGHT = 186;

export interface selectContents {
  screenName: string | Resource;
  screenIcon: PixelMap | ResourceStr | DrawableDescriptor | ImageContent;
  eventData: emitter.EventData;
}

/**
 * hopper半折态录屏选择面板
 *
 * @author liyingjie
 * @since 2025-04-21
 */
@Entry
@Component
struct ScreenRecorderSelectPanel {
  isDark = false;
  scaleCenterX: number | string = 0;
  scaleCenterY: number | string = '100%';
  @State backgroundOpacity: number = 1;
  @State scaleXY: number = 1;
  private selectContentsList: Array<selectContents> = [{
    screenName: $r('app.string.screen_select_upper'),
    screenIcon: $r('app.media.ic_screen_recorder_select_upper'),
    eventData: { data: { 'displayId': HPR_B_SCREEN_ID, 'isBCRecord': false } }
  }, {
    screenName: $r('app.string.screen_select_lower'),
    screenIcon: $r('app.media.ic_screen_recorder_select_lower'),
    eventData: { data: { 'displayId': HPR_C_SCREEN_ID, 'isBCRecord': false } }
  }, {
    screenName: $r('app.string.screen_select_full'),
    screenIcon: $r('app.media.ic_screen_recorder_select_full'),
    eventData: { data: { 'displayId': HPR_B_SCREEN_ID, 'isBCRecord': true } }
  }];
  modifier: BackgroundModifier = new BackgroundModifier(SystemConfig.isDark());

  aboutToAppear(): void {
    this.isDark = SystemConfig.isDark();
    this.scaleCenterX = SystemConfig.isRTL() ? '100%' : 0;
    this.scaleCenterY = SystemConfig.isWindowType ? '100%' : 0;
    windowManager.registerExitAnimation((onFinish?: () => void) => {
      animateTo({ curve: curves.cubicBezierCurve(0.2, 1, 0.2, 1), duration: 300 }, () => {
        this.backgroundOpacity = 0;
      })
      animateTo({ curve: curves.interpolatingSpring(0, 1, 550, 40), onFinish: onFinish },
        () => {
          this.scaleXY = 0.5;
        })
    })
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      this.systemSceneBg()
      this.panelBuilder()
    }
    .opacity(this.backgroundOpacity)
    .scale({
      x: this.scaleXY,
      y: this.scaleXY,
      centerX: this.scaleCenterX,
      centerY: this.scaleCenterY
    })
    .transition(
      TransitionEffect.OPACITY.animation({ curve: curves.interpolatingSpring(0, 1, 550, 40), duration: 200 })
        .combine(TransitionEffect.scale({
          x: 0,
          y: 0,
          centerX: this.scaleCenterX,
          centerY: this.scaleCenterY
        })))
    .keyboardShortcut(FunctionKey.ESC, [], () => {
      LogUtil.info(TAG, 'ESC click, close window');
      windowManager.closeWindowWithAnimation();
    })
  }

  @Builder
  systemSceneBg() {
    Column() {
      Column()
        .backgroundEffect({ radius: this.isDark ? 120 : 100 })
        .backgroundColor($r('app.color.select_panel_background'))
        .attributeModifier(this.modifier)
        .border({
          radius: $r('sys.float.ohos_id_corner_radius_default_l'),
          width: '1vp',
          color: $r('app.color.select_panel_inner_border'),
        })
        .width('100%')
        .height('100%')
    }
    .border({
      radius: $r('sys.float.ohos_id_corner_radius_default_l'),
      width: '1vp',
      color: $r('app.color.select_panel_out_border'),
    })
  }

  @Builder
  panelBuilder() {
    Flex() {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Start }) {
        this.CenterTitle()
        Column() {
          ForEach(this.selectContentsList, (item: selectContents, index: number) => {
            ScreenSelectItem({
              selectItem: item,
              isFullScreenshot: index === 2
            })
          })
        }
      }
      .width('100%')
    }
    .saturate(1)
    .width(SELECT_PANEL_WINDOW_WIDTH)
    .height(SELECT_PANEL_WINDOW_HEIGHT)
    .defaultFocus(true)
  }

  @Builder
  CenterTitle() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
      Text($r('app.string.control_icon_name'))
        .draggable(false)
        .fontColor($r('sys.color.font_primary'))
        .align(Alignment.Center)
        .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
        .fontWeight(FontWeight.Bold)
        .fontFamily('HarmonyHeiTi')
        .height('100%')
        .margin({
          start: LengthMetrics.resource($r('sys.float.padding_level12'))
        })
    }
    .width('100%')
    .height('56vp')
  }
}

@Component
struct ScreenSelectItem {
  isDark = false;
  selectItem?: selectContents;
  isFullScreenshot = false;
  @State isSelected: boolean = false;
  @State isHovered: boolean = false;

  @Styles
  normalStyles() {
    .border({
      width: '2vp',
      color: Color.Transparent
    })
  }

  @Styles
  focusedStyles() {
    .border({
      width: '2vp',
      color: this.isDark ?
      $r('sys.color.ohos_id_color_focused_outline_dark') :
      $r('sys.color.ohos_id_color_focused_outline')
    })
  }

  aboutToAppear(): void {
    this.isDark = SystemConfig.isDark();
  }

  build() {
    Row() {
      Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
        Image(this.selectItem?.screenIcon)
          .fillColor($r('sys.color.icon_primary'))
          .draggable(false)
          .objectFit(ImageFit.Contain)
          .height('24vp')
          .width('24vp')
          .margin({
            start: LengthMetrics.resource($r('sys.float.padding_level10')),
            end: LengthMetrics.resource($r('sys.float.padding_level6'))
          })
          .borderRadius(6)
          .focusable(true)
          .autoResize(false)
          .interpolation(ImageInterpolation.Medium)

        Text(this.selectItem?.screenName)
          .draggable(false)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .fontFamily('HarmonyHeiTi')
          .width('250vp')
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(1)
          .direction(SystemConfig.isRTL() ? Direction.Rtl : Direction.Ltr)

        if (this.isFullScreenshot) {
          Text(FULL_SCREEN_RECORDER_SHORTCUT)
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor($r('sys.color.font_secondary'))
            .fontWeight(FontWeight.Regular)
            .fontFamily('HarmonyHeiTi')
        }
      }
      .focusable(true)
      .height('40vp')
      .borderRadius($r('sys.float.corner_radius_level6'))
    }
    .backgroundColor(this.getBackgroundColor())
    .onTouch((event) => this.onTouchEvent(event))
    .onClick((event) => this.onClickEvent(event))
    .onHover((isHover) => {
      this.isHovered = isHover || false;
    })
    .stateStyles({
      normal: this.normalStyles,
      focused: this.focusedStyles
    })
    .borderRadius($r('sys.float.corner_radius_level6'))
    .margin({
      left: $r('sys.float.padding_level2'),
      right: $r('sys.float.padding_level2'),
      bottom: $r('sys.float.padding_level1')
    })
    .height('40vp')
  }

  private getBackgroundColor() {
    if (this.isSelected) {
      return this.isDark ?
      $r('sys.color.ohos_id_color_click_effect_dark') :
      $r('sys.color.ohos_id_color_click_effect');
    }
    if (this.isHovered) {
      return this.isDark ?
      $r('sys.color.ohos_id_color_hover_dark') :
      $r('sys.color.ohos_id_color_hover');
    }
    return Color.Transparent;
  }

  private onTouchEvent(event?: TouchEvent) {
    LogUtil.info(TAG, `[onTouchEvent] event: ${JSON.stringify(event)}`);
    if (event?.type == TouchType.Down) {
      this.isSelected = true;
    } else if (event?.type == TouchType.Up) {
      this.isSelected = false;
    }
  }

  private onClickEvent(event?: ClickEvent): void {
    LogUtil.error(TAG, `[onClickEvent] event: ${JSON.stringify(event)}`);
    windowManager.setMainWindowSnapshotSkip();
    emitter.emit('emit_event_choose_panel_result', this.selectItem?.eventData);
    windowManager.closeWindow();
  }
}