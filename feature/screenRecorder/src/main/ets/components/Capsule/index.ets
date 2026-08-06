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

import {
  EVENT_NAME_SET_SCREENRECORD_MIC,
  EventReportUtil,
  GlobalThisUtil,
  LogUtil,
  SetSwitchResult,
  StopRecordTriggerType
} from '@ohos/common';
import { BusinessError, systemDateTime } from '@kit.BasicServicesKit';
import lazy I18n from '@ohos.i18n';
import audio from '@ohos.multimedia.audio';
import windowManager from '@ohos.window';
import { RecorderToast, PcWindowManager, RecorderFileManager } from '../../manager';
import { MicManager } from '../../manager/MicManager';
import { PcRecordManager } from '../../manager/PcRecordManager';
import {
  CAPSULE_DIVIDER_WIDTH,
  CAPSULE_SHADOW_RADIUS,
  CAPSULE_WINDOW_HEIGHT,
  HOUR_TO_SECONDS,
  SECONDS_IN_ONE_MINUTE,
  MILLISECONDS_IN_ONE_SECOND,
  RESERVED_SPACE_MULTIPLES,
  TIME_LENGTH,
  TIME_SEPARATOR,
  TWINKLE_INTERVAL,
  ZERO_TIME_TEXT,
} from './types';

/* instrument ignore file */
const TAG = 'Capsule';

// 录屏胶囊点击或者拖拽阈值，大于15px认为是拖拽，小于15px认为是点击
const MOVE_THRESHOLD = 15;

/**
 * Capsule-shaped toolbar
 *
 * @since 2022-10-19
 */
@Component
export struct Capsule {
  @State isStopIconVisible: boolean = true;
  @State micAreaWidth: number = 0;
  @State timerAreaWidth: number = 0;
  @State isRTL: boolean = false;
  @State recordTimeText: string = ZERO_TIME_TEXT;
  @StorageLink('defaultCapsuleWindowX') windowX: number = 0; // Coordinate-X of the capsule window
  @StorageLink('defaultCapsuleWindowY') windowY: number = 0; // Coordinate-Y of the capsule window
  @StorageLink('isMoveCapsuleWindowComplete') isGestrueComplete: boolean = true;
  @StorageProp('languageCode') @Watch('onLanguageChange') languageCode: string = '';
  @StorageProp('fontSizeScaleCode') @Watch('onFontSizeScaleChange') fontSizeScaleCode: number | undefined = undefined;
  private initWindowX: number = 0;
  private initWindowY: number = 0;
  private initTouchX: number = 0;
  private initTouchY: number = 0;
  private capsuleWindowX: number = 0;
  private capsuleWindowY: number = 0;
  private isMoving: boolean = false;
  private isClicked: boolean = false;
  private lastHours: number = 0;
  private recordTime: Date = new Date(0);
  private nextRunTime: number = 0;
  private twinkleIntervalId: number = 0;
  private recordManager: PcRecordManager = PcRecordManager.getInstance();
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  @State isMicEnabled: boolean = true;
  private audioVolumeGroupManager: audio.AudioVolumeGroupManager | undefined;
  private windowManagerInstance: PcWindowManager = PcWindowManager.getInstance();
  private startTime: number = 0;

  async aboutToAppear() {
    this.isRTL = this.windowManagerInstance.isRTL();
    const groupid = audio.DEFAULT_VOLUME_GROUP_ID;
    this.audioVolumeGroupManager = await audio.getAudioManager().getVolumeManager().getVolumeGroupManager(groupid);
    await this.keyboardMicEvent();
    await MicManager.getInstance().getMicEnabledState(async (enabled) => {
      this.isMicEnabled = enabled && !MicManager.getInstance().getPcMicEnableState();
      LogUtil.info(TAG, 'isMicEnable = ' + this.isMicEnabled);
      if (MicManager.getInstance().getIsMicUnavailable()) {
        this.isMicEnabled = false;
        LogUtil.info(TAG, 'Mic not available, show mic off icon');
      }
      if (enabled && MicManager.getInstance().getPcMicEnableState()) {
        LogUtil.info(TAG, 'Mic status : system switch and recorder switch is different');
        await MicManager.getInstance().setMicUnableForPC();
      }
    });
    this.nextRunTime = new Date().getTime();
    this.startTime = this.getSystemUptime();
    this.runTimer();
    LogUtil.info(TAG, `this.recordTime：${this.recordTime}, CapsuleWindow appear time：${this.recordTimeText}`);
  }

  aboutToDisappear() {
    this.twinkleIntervalId && clearTimeout(this.twinkleIntervalId);
    try {
      this.audioVolumeGroupManager?.off('micStateChange');
      LogUtil.info(TAG, 'off micStateChange success');
    } catch (error) {
      LogUtil.error(TAG, 'off micStateChange error:' + error.message);
    }
  }

  private runTimer(): void {
    this.nextRunTime += TWINKLE_INTERVAL;
    let delay: number = this.nextRunTime - new Date().getTime();
    this.twinkleIntervalId = setTimeout(() => {
      this.isStopIconVisible = !this.isStopIconVisible;
      if (this.isStopIconVisible) {
        this.updateRecordTimeText();
      }
      this.runTimer();
    }, delay);
  }

  /* instrument ignore next */
  private async keyboardMicEvent(): Promise<void> {
    try {
      if (this.recordManager.getIsRecording()) {
        this.audioVolumeGroupManager?.on('micStateChange', async (micStateChange) => {
          this.isMicEnabled = !micStateChange.mute;
          LogUtil.warn(TAG, `micStateChange: ${micStateChange.mute}`)
          await MicManager.getInstance().setMicEnabled(this.isMicEnabled, RecorderFileManager.getInstance());
          MicManager.getInstance().setPcMicEnableState(micStateChange.mute);
        });
      }
    } catch (error) {
      LogUtil.error(TAG, `Failed keyboardMicEvent resource: ${error}`);
    }
  }

  private onLanguageChange(): void {
    this.micAreaWidth = 0; // Reset the width of the microphone area to refresh the capsule width
    this.isRTL = I18n.isRTL(this.languageCode);
  }

  private onFontSizeScaleChange(): void {
    LogUtil.info(TAG, 'fontSizeScale Changed');
    this.micAreaWidth = 0;
    this.timerAreaWidth = 0;
    this.windowManagerInstance.setInitialParams(this.getUIContext());
  }

  private getSystemUptime() {
    let uptime = 0;
    try {
      uptime = systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE, false);
    } catch (error) {
      LogUtil.error(`systemDateTime Failed to get uptime. message: ${error?.message}, code: ${error?.code}`);
    }
    return uptime;
  }

  private updateRecordTimeText() {
    let time: number = Math.floor((this.getSystemUptime() - this.startTime) / MILLISECONDS_IN_ONE_SECOND);
    const hours = Math.floor(time / HOUR_TO_SECONDS);
    const remainingSeconds = time % HOUR_TO_SECONDS;
    const minutes = Math.floor(remainingSeconds / SECONDS_IN_ONE_MINUTE);
    const seconds = remainingSeconds % SECONDS_IN_ONE_MINUTE;
    const hourStr = hours > 0 ? `${hours}${TIME_SEPARATOR}` : '';
    const minuteStr = minutes.toString().padStart(TIME_LENGTH, '0');
    const secondStr = seconds.toString().padStart(TIME_LENGTH, '0');
    this.recordTimeText = `${hourStr}${minuteStr}${TIME_SEPARATOR}${secondStr}`;

    if (hours > this.lastHours) {
      this.timerAreaWidth = 0;
    }
    this.lastHours = hours;
    LogUtil.info(TAG, `this.recordTime：${this.recordTime}, CapsuleWindow record time：${this.recordTimeText}`);
  }

  private async onStop() {
    if (this.isMoving) {
      return;
    }
    const killProcessTimeoutId = this.globalThisInstance!.getObject('killProcessTimeoutId') as number;
    killProcessTimeoutId && clearTimeout(killProcessTimeoutId);
    this.isClicked = true;
    this.globalThisInstance!.setObject('isProcessing', true);
    this.recordManager.setStopTime(Date.now());
    await this.recordManager.stop();
    EventReportUtil.setStopType(StopRecordTriggerType.TRIGGERED_TYPE_BY_STOP_BUTTON)
    this.globalThisInstance!.setObject('isProcessing', false);
  }

  private async setMicEnabled() {
    if (!this.recordManager) {
      LogUtil.error(TAG, 'recordManager undefined, cannot set mic state');
      return;
    }
    MicManager.getInstance().checkPcMicState();
    if (MicManager.getInstance().getPcMicEnableState()) {
      RecorderToast.getInstance().showToast('hw_video_close_mic');
      return;
    }
    let result = await MicManager.getInstance().setMicEnabled(!this.isMicEnabled, RecorderFileManager.getInstance());
    if (result) {
      LogUtil.info(TAG, 'setMicEnable success');
      EventReportUtil.setSwitchMicResult(SetSwitchResult.RESULT_SUCCESS);
      this.isMicEnabled = !this.isMicEnabled;
      if (this.isMicEnabled) {
        MicManager.getInstance().setIsMicUnavailable(false);
      }
    } else {
      LogUtil.error(TAG, 'setMicEnable failed');
      EventReportUtil.setSwitchMicResult(SetSwitchResult.RESULT_FAILED);
    }
    EventReportUtil.reportEvent(EVENT_NAME_SET_SCREENRECORD_MIC,
      {
        'TYPE': EventReportUtil.getSwitchMicType(),
        'RESULT': EventReportUtil.getSwitchMicResult()
      }
    );
  }

  @Styles
  normalStyles() {
    .backgroundColor($r('app.color.capsule_normal_background'))
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('app.color.capsule_pressed_background'))
  }

  @Builder
  buildMicArea() {
    Flex() {
      Row() {
        Image(this.isMicEnabled && !MicManager.getInstance().getIsMicUnavailable() ? $r('app.media.ic_mic_open') :
          $r('app.media.ic_mic_close'))
          .width($r('app.float.mic_icon_open_size'))
          .height($r('app.float.mic_icon_open_size'))
          .draggable(false)
      }
      .height('100%')
      .width($r('app.float.mic_icon_open_size'))
      .align(Alignment.Center)
      .onAreaChange((_, area: Area) => {
        LogUtil.debug(TAG, `Image final width: ${area.width}`);
      })

      Text($r('app.string.microphone'))
        .fontWeight(FontWeight.Medium)
        .fontSize($r('sys.float.ohos_id_text_size_body3'))
        .fontColor(this.isMicEnabled && !MicManager.getInstance().getIsMicUnavailable() ? $r('app.color.mic_active') :
          $r('app.color.mic_inactive'))
        .height('100%')
        .width('100%')
        .textAlign(TextAlign.Start)
        .onAreaChange((_, area: Area) => {
          LogUtil.debug(TAG, `Text microphone final width: ${area.width}`);
        })
        .margin({
          left: this.isRTL ? 0 : $r('app.float.mic_label_icon_margin'),
          right: this.isRTL ? $r('app.float.mic_label_icon_margin') : 0,
        })
    }
    .padding({
      left: this.isRTL ? $r('app.float.capsule_divider_margin') : $r('app.float.capsule_padding_horizontal'),
      right: this.isRTL ? $r('app.float.capsule_padding_horizontal') : $r('app.float.capsule_divider_margin'),
    })
    .backgroundColor($r('app.color.capsule_normal_background'))
    .borderRadius({
      topLeft: this.isRTL ? 0 : $r('app.float.capsule_border_radius'),
      bottomLeft: this.isRTL ? 0 : $r('app.float.capsule_border_radius'),
      topRight: this.isRTL ? $r('app.float.capsule_border_radius') : 0,
      bottomRight: this.isRTL ? $r('app.float.capsule_border_radius') : 0,
    })
    .align(Alignment.Center)
    .width('100%')
    .height('100%')
    .gesture(
      TapGesture()
        .onAction(() => {
          LogUtil.info(TAG, `onAction setMicEnabled--isMoving:${this.isMoving}`);
          if (!this.isMoving) {
            this.setMicEnabled();
          }
        })
    )
  }

  @Builder
  buildTimerArea() {
    Flex() {
      Row() {
        if (this.isStopIconVisible) {
          Image($r('app.media.ic_screen_end'))
            .width($r('app.float.end_icon_open_size'))
            .height($r('app.float.end_icon_open_size'))
            .draggable(false)
        }
      }
      .height('100%')
      .width($r('app.float.end_icon_open_size'))
      .align(Alignment.Center)

      Column() {
        Text(this.recordTimeText)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.ohos_id_text_size_body3'))
          .height('100%')
          .width('100%')
      }
      .width('100%')
      .margin({
        left: this.isRTL ? 0 : $r('app.float.timer_label_icon_margin'),
        right: this.isRTL ? $r('app.float.timer_label_icon_margin') : 0,
      })
    }
    .padding({
      right: this.isRTL ? $r('app.float.capsule_divider_margin') : $r('app.float.capsule_padding_horizontal'),
      left: this.isRTL ? $r('app.float.capsule_padding_horizontal') : $r('app.float.capsule_divider_margin'),
    })
    .stateStyles({
      pressed: this.pressedStyles,
      normal: this.normalStyles,
    })
    .align(Alignment.Center)
    .width('100%')
    .height('100%')
    .borderRadius({
      topRight: this.isRTL ? 0 : $r('app.float.capsule_border_radius'),
      bottomRight: this.isRTL ? 0 : $r('app.float.capsule_border_radius'),
      topLeft: this.isRTL ? $r('app.float.capsule_border_radius') : 0,
      bottomLeft: this.isRTL ? $r('app.float.capsule_border_radius') : 0,
    })
    .id('id_stop_button')
    .gesture(
      TapGesture()
        .onAction(() => {
          LogUtil.info(TAG, `onAction onStop--isMoving:${this.isMoving}`);
          if (!this.isMoving) {
            this.onStop();
          }
        })
    )
  }

  @Builder
  preBuildText() {
    if (!this.micAreaWidth || !this.timerAreaWidth) {
      Stack() {
        Text() {
          Span($r('app.string.microphone'))
            .fontWeight(FontWeight.Medium)
            .fontSize($r('sys.float.ohos_id_text_size_body3'))
            .fontColor($r('app.color.transparent'))
        }
        .padding({
          left: this.isRTL ? 0 : $r('app.float.mic_pre_build_padding'),
          right: this.isRTL ? $r('app.float.mic_pre_build_padding') : 0,
        })
        .onAreaChange((_, area: Area) => {
          if (typeof area.width === 'number') {
            this.micAreaWidth = area.width;
          }
        })

        Text() {
          Span(this.recordTimeText)
            .fontWeight(FontWeight.Regular)
            .fontSize($r('sys.float.ohos_id_text_size_body3'))
            .fontColor($r('app.color.transparent'))
        }
        .padding({
          left: this.isRTL ? 0 : $r('app.float.timer_pre_build_padding'),
          right: this.isRTL ? $r('app.float.timer_pre_build_padding') : 0,
        })
        .onAreaChange((_, area: Area) => {
          if (typeof area.width === 'number') {
            this.timerAreaWidth = area.width;
          }
        })
      }
    }
  }

  @Builder
  buildCapsuleContent() {
    if (this.micAreaWidth && this.timerAreaWidth) {
      Flex() {
        Column() {
          this.buildMicArea()
        }
        .width(this.micAreaWidth)
        .onAreaChange((_, area: Area) => {
          LogUtil.debug(TAG, `Real micAreaWidth: ${area.width}`);
          LogUtil.debug(TAG, `Target micAreaWidth: ${this.micAreaWidth}`);
        })

        Column() {
          Column()
            .backgroundColor($r('app.color.capsule_divider'))
            .height($r('app.float.capsule_divider_height'))
            .width($r('app.float.capsule_divider_width'))
        }
        .padding({
          top: $r('app.float.capsule_divider_margin'),
          bottom: $r('app.float.capsule_divider_margin'),
        })
        .backgroundColor($r('app.color.capsule_normal_background'))
        .height('100%')
        .width($r('app.float.capsule_divider_width'))

        Column() {
          this.buildTimerArea()
        }
        .width(this.timerAreaWidth)
      }
      .backgroundColor($r('app.color.capsule_background'))
      .align(Alignment.Center)
      .height($r('app.float.capsule_height'))
      .width(this.micAreaWidth + CAPSULE_DIVIDER_WIDTH + this.timerAreaWidth)
      .borderRadius($r('app.float.capsule_border_radius'))
      .onAreaChange((_, area: Area) => {
        if (typeof area.width === 'number') {
          this.windowManagerInstance.setCapsuleWindowSize(
            vp2px(area.width + CAPSULE_SHADOW_RADIUS * RESERVED_SPACE_MULTIPLES),
            vp2px(CAPSULE_WINDOW_HEIGHT),
          );
        }
      })
    }
  }

  build() {
    Stack() {
      this.preBuildText()
      this.buildCapsuleContent()
    }
    .height('100%')
    .width('100%')
    .alignContent(Alignment.Center)
    .onTouch(async (event?: TouchEvent) => {
      if (event) {
        const capsuleWindow: windowManager.Window = this.windowManagerInstance.getCapsuleWindow();
        if (event.type === TouchType.Down) {
          LogUtil.info(TAG, `Touch Down event`);
          this.isMoving = false;
          let properties = capsuleWindow?.getWindowProperties();
          let touchPoint = event.touches[0];
          if (properties) {
            this.initWindowX = properties.windowRect.left
            this.initWindowY = properties.windowRect.top
          } else {
            this.initWindowX = touchPoint.displayX - touchPoint.windowX
            this.initWindowY = touchPoint.displayY - touchPoint.windowY
          }
          this.initTouchX = touchPoint.displayX;
          this.initTouchY = touchPoint.displayY;
          this.capsuleWindowX = this.initWindowX;
          this.capsuleWindowY = this.initWindowY;
          try {
            capsuleWindow.startMoving().then(() => {
              LogUtil.info('Succeeded in starting moving window.')
            }).catch((err: BusinessError) => {
              LogUtil.error(`Failed to start moving. Cause code: ${err?.code}, message: ${err?.message}`);
            });
          } catch (exception) {
            LogUtil.error(`Failed to start moving window.
              Cause code: ${exception?.code}, message: ${exception?.message}`);
          }
        }
        if (event.type === TouchType.Move) {
          this.capsuleWindowX = this.initWindowX + vp2px(event.touches[0].displayX - this.initTouchX);
          this.capsuleWindowY = this.initWindowY + vp2px(event.touches[0].displayY - this.initTouchY);
          LogUtil.info(TAG, `Touch Move capsuleWindowX:${this.capsuleWindowX} this.initWindowX:${this.initWindowX}`);
          if (Math.abs(this.capsuleWindowX - this.initWindowX) >= MOVE_THRESHOLD) {
            this.isMoving = true;
          }
        }
        if (event.type === TouchType.Up) {
          LogUtil.info(TAG, 'Touch up');
          if (this.isClicked) {
            this.isClicked = false;
            return;
          }
          setTimeout(async () => {
            LogUtil.info(TAG, `moveCapsuleWindow end, isGestrueComplete = ${this.isGestrueComplete}`);
            await this.windowManagerInstance.stopMovingCapsuleWindow(this.capsuleWindowX, this.capsuleWindowY);
          }, 50)
        }
      }
    })
  }
}