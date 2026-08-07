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

import deviceInfo from '@ohos.deviceInfo';
import { TipsDialog, uiExtension } from '@kit.ArkUI';
import StartOptions from '@ohos.app.ability.StartOptions';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import Want from '@ohos.app.ability.Want';
import screenshot from '@ohos.screenshot';
import image from '@ohos.multimedia.image';
import missionManager from '@ohos.app.ability.missionManager';
import bundleResourceManager from '@ohos.bundle.bundleResourceManager';
import display from '@ohos.display';
import I18n from '@ohos.i18n';
import media from '@ohos.multimedia.media';
import window from '@ohos.window';
import bundleManager from '@ohos.bundle.bundleManager';
import systemParameterEnhance from '@ohos.systemParameterEnhance';

import { GlobalThisUtil, LogUtil } from '@ohos/common';
import { CommonSelectPicker } from '@ohos/screen-recorder';

class DialogJsonData {
  public choice: string = 'true';
  public displayId: number | null = -1;
  public missionId: number | null = -1;
  public checkBoxSelected: string = 'true';
}

/* instrument ignore file */
const TAG = 'PrivacyDialogPage';
const MAX_WINDOW_NUM: number = 999;
const ZERO_SIZE: number = 0;
const VIRTUAL_SCREEN: number = 1000;
const B_DISPLAY_ID: number = 0;
const C_DISPLAY_ID: number = 999;
const DEBOUNCE_LIMIT_TIME: number = 300;
const SELECT_BACKUP_SLEEP_TIME: number = 200;
const SELECT_SHARE_SLEEP_TIME: number = 300;
const TERMINATE_SLEEP_TIME: number = 300;
const SCREEN_SPACE_WIDTH: number = 36;
const BUTTON_CLICK_TIME: number = 230;
const CHECKBOX_DEFAULT_MARGIN: number = 13;
const CHECKBOX_WIDTH: number = 24;
const HALF_MODULE_WIDTH_RADIO: number = 2;
const EXPANDED_PAD_HEIGHT: number = 209;
const SMALL_DEVICE_HEIGHT: number = 113;
const WINDOW_LIST_MARGIN: number = 10;
const MODULE_IMAGE_HEIGHT_MARGIN: number = 50;
const ROTATE_ANGLE_NUM: number = 90;
const NEGATIVE_ROTATION_NUM: number = 3;
const SCREEN_BUNDLE_NAME: string = 'com.ohos.screenrecorder';

@Entry
@Component
export struct DialogPage {
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State moduleImageWidth: number = 0;
  @State moduleImageHeight: number = 0;
  @State moduleWindowWidth: number = 0;
  @State moduleWindowHeight: number = 0;
  @State windowPictureWidth: number = 0;
  @State windowPictureHeight: number = 0;
  @State displayRatio: number = 1;
  @State isPickerShow: boolean = false;
  @State checkedMissionId: number | null = null;
  @State canStartScreenCapture: boolean = false;
  @State isPortraitScreen: boolean = false; // 竖向展开态
  @State isLandscapeScreen: boolean = false; // 横向展开态
  @State checkBoxOffsetX: number = 0;
  @State isInnerAudioBoxSelected: boolean = false;
  @State checkBoxSelected: boolean = false;
  @State showShareSystemAudioBox: boolean = false;
  @State deviceRotation: number = 0;
  @State isFoldExpandedOrPad: boolean = false;
  @State isSmallDeviceFolded: boolean = false;
  @State isShowPrivacyContent: boolean = true;
  @State status: number = -1;
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private selectWant: Want | undefined = this.globalThisInstance?.getObject('privacyDialogWant') as Want;
  private session: UIExtensionContentSession | undefined =
    this.globalThisInstance?.getObject('privacySession') as UIExtensionContentSession;
  private extensionWindow: uiExtension.WindowProxy | undefined = this.session?.getUIExtensionWindowProxy();
  private appLabel: string = '';
  private showSensitiveCheckBox: boolean = false;
  private imageWindowData: CommonSelectPicker.WindowImageDataSource = new CommonSelectPicker.WindowImageDataSource([]);
  private currentDisplayId: number | undefined = undefined;
  private missionImageMap: Map<number, CommonSelectPicker.WindowImageData> = new Map();
  private excludedWindowIDs: number[] = [];
  private sessionId: number = -1;
  private pickerMode: number | undefined = undefined;
  private debounceCacheId: number | null = null; // 防抖timeoutID
  private displayChangeCallback: Callback<number> | undefined = undefined;
  private foldStatusChangeCallback: Callback<number> | undefined = undefined;
  private windowSizeChangeCallback: Callback<window.Size> | undefined = undefined;
  private displayIdSet: Set<number> = new Set();
  private excludedBundleName: string = '';
  private getFoldProductTypeNum: number = -1;
  private isSmallFoldDevice: boolean = false; // 是否小折叠、阔折叠
  private isTabletDevice: boolean = false;
  private submitJsonData: CommonSelectPicker.JsonData | null = null;

  @Builder
  imageContent(item: CommonSelectPicker.WindowImageData, idx: number) {
    Column() {
      Row() {
        if (item.isDisplay) {
          if (!this.isSmallDeviceFolded) {
            Row()
              .width(0)
              .height($r('app.float.app_icon_size'))
              .visibility(Visibility.Hidden)
              .margin({
                left: this.isRTL() ? 0 : $r('app.float.app_screen_text_margin'),
                right: this.isRTL() ? $r('app.float.app_screen_text_margin') : 0,
              })
          }
          Row() {
            Text($r('app.string.select_window_screen'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Center)
              .maxFontScale(CommonSelectPicker.FontSizeScale.L)
            Text(`${Number(idx) + 1}`)
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Center)
              .maxFontScale(CommonSelectPicker.FontSizeScale.L)
          }
          .height($r('app.float.app_icon_size'))
        } else {
          Stack({ alignContent: Alignment.Start }) {
            if (this.isSmallDeviceFolded) {
              Row() {
                Text(`${item.missionLabel}`)
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontWeight(FontWeight.Medium)
                  .textAlign(TextAlign.Center)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .ellipsisMode(EllipsisMode.END)
                  .wordBreak(WordBreak.BREAK_ALL)
                  .maxFontScale(CommonSelectPicker.FontSizeScale.L)
              }
              .height($r('app.float.app_icon_size'))
            } else {
              Image(item.missionIcon ?? $r('sys.media.ohos_app_icon'))
                .width($r('app.float.app_icon_size'))
                .height($r('app.float.app_icon_size'))
                .draggable(false)
                .objectFit(ImageFit.Cover)
                .syncLoad(true)
                .margin({
                  left: this.isRTL() ? 0 : $r('app.float.app_icon_margin'),
                  right: this.isRTL() ? $r('app.float.app_icon_margin') : 0,
                })
              Text(`${item.missionLabel}`)
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontWeight(FontWeight.Medium)
                .textAlign(TextAlign.Center)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .ellipsisMode(EllipsisMode.END)
                .wordBreak(WordBreak.BREAK_ALL)
                .margin({
                  left: this.isRTL() ? 0 : $r('app.float.app_mission_Label_left'),
                  right: this.isRTL() ? $r('app.float.app_mission_Label_left') : 0,
                })
                .maxFontScale(CommonSelectPicker.FontSizeScale.L)
            }
          }
        }
      }
      .justifyContent(this.isSmallDeviceFolded ? FlexAlign.Center : FlexAlign.Start)
      .width('100%')
      .margin({ bottom: '4vp' })

      RelativeContainer() {
        Stack({ alignContent: Alignment.Center }) {
          if (item.imageWidth && item.imageHeight && item.imageWidth !== 0 && item.imageHeight !== 0 &&
            item.missionShot !== null) {
            if ((item.imageWidth / item.imageHeight).toString().slice(0, 8) ===
            this.displayRatio.toString().slice(0, 8)) {
              Column() {
              }
              .width(this.moduleWindowWidth)
              .height(this.moduleWindowHeight)
              .borderRadius('20vp')
              .borderStyle(BorderStyle.Solid)
              .borderWidth(this.checkedMissionId !== null && this.checkedMissionId === item.missionId ? '3vp' : '0vp')
              .borderColor(this.checkedMissionId !== null && this.checkedMissionId === item.missionId ?
                $r('sys.color.interactive_active') : Color.Transparent)

              Image(item.missionShot)
                .width(this.moduleImageWidth)
                .height(this.moduleImageHeight)
                .borderRadius('16vp')
                .draggable(false)
                .objectFit(ImageFit.Contain)
                .syncLoad(true)
            } else if ((item.imageHeight / item.imageWidth).toString().slice(0, 8) ===
            this.displayRatio.toString().slice(0, 8)) {
              Column() {
              }
              .width(this.moduleWindowWidth)
              .height(this.moduleWindowHeight)
              .borderRadius('20vp')
              .borderStyle(BorderStyle.Solid)
              .borderWidth(this.checkedMissionId !== null && this.checkedMissionId === item.missionId ? '3vp' :
                '0vp')
              .borderColor(this.checkedMissionId !== null && this.checkedMissionId === item.missionId ?
                $r('sys.color.interactive_active') : Color.Transparent)

              Image(item.missionShot)
                .width(this.moduleWindowHeight)
                .height(this.moduleImageWidth)
                .draggable(false)
                .objectFit(ImageFit.Contain)
                .syncLoad(true)
                .borderRadius('16vp')
                .rotate({ z: 1, angle: this.getAngle() })
            } else {
              Column() {
              }
              .width(this.moduleImageWidth)
              .height(this.moduleImageHeight)
              .borderRadius('16vp')
              .backgroundColor(Color.Black)

              if (item.imageWidth / item.imageHeight < this.displayRatio) {
                Image(item.missionShot)
                  .height(this.moduleImageHeight)
                  .objectFit(ImageFit.Contain)
                  .syncLoad(true)
                  .borderStyle(BorderStyle.Solid)
                  .borderWidth(this.checkedMissionId !== null && this.checkedMissionId === item.missionId ? '3vp' :
                    '0vp')
                  .borderColor(this.checkedMissionId !== null && this.checkedMissionId === item.missionId ?
                    $r('sys.color.interactive_active') : Color.Transparent)
                  .borderRadius('10vp')
              } else {
                Image(item.missionShot)
                  .width(this.moduleImageWidth)
                  .objectFit(ImageFit.Contain)
                  .syncLoad(true)
                  .borderStyle(BorderStyle.Solid)
                  .borderWidth(this.checkedMissionId !== null && this.checkedMissionId === item.missionId ? '3vp' :
                    '0vp')
                  .borderColor(this.checkedMissionId !== null && this.checkedMissionId === item.missionId ?
                    $r('sys.color.interactive_active') : Color.Transparent)
                  .borderRadius('10vp')
              }
            }
          }
        }
        .width(this.moduleWindowWidth)
        .height(this.moduleWindowHeight)

        Column() {
          Checkbox()
            .select(this.checkedMissionId !== null && this.checkedMissionId === item.missionId)
            .width(CHECKBOX_WIDTH)
            .height(CHECKBOX_WIDTH)
            .zIndex(1)
            .accessibilityLevel('no')
        }
        .width($r('app.float.app_icon_size'))
        .height($r('app.float.app_icon_size'))
        .zIndex(2)
        .onTouch((event: TouchEvent) => {
          event?.stopPropagation();
        })
        .enabled(false)
        .margin({
          right: this.isRTL() ? 0 : CHECKBOX_DEFAULT_MARGIN,
          left: this.isRTL() ? CHECKBOX_DEFAULT_MARGIN : 0,
          bottom: CHECKBOX_DEFAULT_MARGIN,
        })
        .alignRules({
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
          right: { anchor: '__container__', align: HorizontalAlign.End },
        })
        .translate({ x: this.isRTL() ? this.checkBoxOffsetX : -this.checkBoxOffsetX })
      }
      .width(this.moduleWindowWidth)
      .height(this.moduleWindowHeight)
    }
    .id('album_detail_' + idx)
    .onClick(() => {
      LogUtil.info(TAG, `click and check itemMission: ${item.missionId}`);
      this.checkedMissionId = item.missionId;
    })
    .accessibilityLevel('yes')
    .accessibilityGroup(true)
    .accessibilityChecked(this.checkedMissionId !== null && this.checkedMissionId === item.missionId)
    .accessibilityDescription(this.checkedMissionId !== null && this.checkedMissionId === item.missionId ? ' ' : '')
    .accessibilityText(item.isDisplay ? this.getStringSync($r('app.string.select_window_screen'), idx) :
      item.missionLabel)
  }

  @Builder
  PreviewComponentBuilder() {
    Column() {
      Scroll() {
        Column() {
          Column() {
            List() {
              LazyForEach(this.imageWindowData, (item: CommonSelectPicker.WindowImageData, idx: number) => {
                ListItem() {
                  this.imageContent(item, idx);
                }
                .width(this.windowPictureWidth)
                .height(this.windowPictureHeight)
                .margin({
                  right: 2,
                })
              }, (item: CommonSelectPicker.WindowImageData, idx: number) => JSON.stringify(item) + idx)
            }
            .cachedCount(4)
            .scrollBar(BarState.Off)
            .divider(null)
            .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
            .chainAnimation(false)
            .listDirection(Axis.Horizontal)
            .width('100%')
            .padding({
              left: 8,
            })
          }
          .width('100%')
          .margin({
            top: this.isSmallDeviceFolded ? 8 : 12,
          })

          if (this.isShowPrivacyContent) {
            Column() {
              Column() {
              }
              .backgroundColor($r('sys.color.comp_divider'))
              .width('100%')
              .height('1vp')
            }
            .margin({
              top: $r('app.float.list_margin_8'),
              bottom: $r('app.float.list_margin_12'),
              left: $r('app.float.list_margin_28'),
              right: $r('app.float.list_margin_28'),
            })

            Column() {
              Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                Row() {
                  Text($r('app.string.share_audio'))
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .maxFontScale(CommonSelectPicker.FontSizeScale.XXL)
                    .align(Alignment.Start)
                    .width('100%')
                }
                .margin({
                  left: this.isRTL() ? $r('sys.float.padding_level4') : 0,
                  right: this.isRTL() ? 0 : $r('sys.float.padding_level4'),
                })
                .align(Alignment.Start)

                Checkbox()
                  .width($r('app.float.text_checkbox_size'))
                  .height($r('app.float.text_checkbox_size'))
                  .select(this.isInnerAudioBoxSelected)
                  .shape(CheckBoxShape.CIRCLE)
                  .onChange((value: boolean) => {
                    this.isInnerAudioBoxSelected = value;
                  })
              }
              .width('100%')
              .constraintSize({
                minHeight: $r('app.float.text_line_size')
              })
              .padding({
                left: $r('app.float.list_padding_12'),
                right: $r('app.float.list_padding_12'),
              })
              .visibility(this.showShareSystemAudioBox ? Visibility.Visible : Visibility.None)

              Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                Row() {
                  Text($r('app.string.screen_privacy_protection'))
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .maxFontScale(CommonSelectPicker.FontSizeScale.XXL)
                    .align(Alignment.Start)
                    .width('100%')
                }
                .margin({
                  left: this.isRTL() ? $r('sys.float.padding_level4') : 0,
                  right: this.isRTL() ? 0 : $r('sys.float.padding_level4'),
                })
                .align(Alignment.Start)

                Checkbox()
                  .width($r('app.float.text_checkbox_size'))
                  .height($r('app.float.text_checkbox_size'))
                  .select(this.checkBoxSelected)
                  .shape(CheckBoxShape.CIRCLE)
                  .onChange((value: boolean) => {
                    this.checkBoxSelected = value;
                  })
              }
              .width('100%')
              .constraintSize({
                minHeight: $r('app.float.text_line_size')
              })
              .padding({
                left: $r('app.float.list_padding_12'),
                right: $r('app.float.list_padding_12'),
              })
              .visibility(this.showSensitiveCheckBox ? Visibility.Visible : Visibility.None)

              Column() {
                Text($r('app.string.privacy_window_content', this.appLabel))
                  .fontSize($r('sys.float.ohos_id_text_size_body3'))
                  .width('100%')
                  .maxFontScale(CommonSelectPicker.FontSizeScale.XXL)
              }
              .margin({
                top: $r('app.float.privacy_window_content_top'),
              })
              .padding({
                left: $r('app.float.list_padding_12'),
                right: $r('app.float.list_padding_12'),
              })
            }
            .margin({
              left: $r('app.float.list_margin_16'),
              right: $r('app.float.list_margin_16'),
              bottom: $r('app.float.list_margin_4'),
            })
          }
        }
      }
      .scrollBar(BarState.Off)
      .scrollable(ScrollDirection.Vertical)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .height(`calc(100% - 68vp)`)
      .align(Alignment.TopStart)

      Column() {
        Button($r('app.string.select_window_button_share'),
          { buttonStyle: ButtonStyleMode.EMPHASIZED, type: ButtonType.Capsule })
          .width('100%')
          .borderRadius($r('sys.float.corner_radius_level4'))
          .fontSize($r('sys.float.ohos_id_text_size_button1'))
          .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
          .enabled(this.canStartScreenCapture)
          .height($r('app.float.select_window_button_share_height'))
          .onClick(() => {
            this.debounce(() => {
              this.handleSelectShareBtn();
            }, BUTTON_CLICK_TIME);
          })
          .maxFontScale(CommonSelectPicker.FontSizeScale.XXL)
      }
      .margin({
        bottom: $r('app.float.select_window_button_share_margin'),
        left: $r('app.float.select_window_button_share_margin'),
        right: $r('app.float.select_window_button_share_margin'),
      })
      .padding({
        top: $r('app.float.select_window_button_share_paddingTop'),
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  dialogControllerImage: CustomDialogController = new CustomDialogController({
    builder: TipsDialog({
      imageRes: $r('app.media.PrivacyDialogIcon'),
      imageSize: ({ width: 32, height: 32 }),
      title: $r('app.string.privacy_dialog_title', this.appLabel),
      content: $r('app.string.privacy_dialog_content'),
      primaryButton: {
        value: $r('app.string.privacy_dialog_Deny'),
        action: () => {
          this.onCancel();
        }
      },
      isChecked: this.checkBoxSelected,
      checkTips: this.showSensitiveCheckBox ? $r('app.string.screen_privacy_protection') : undefined,
      onCheckedChange: () => {
        this.checkBoxSelected = !this.checkBoxSelected;
        LogUtil.info(TAG, `this.checkBoxSelected: ${this.checkBoxSelected}`);
      },
      secondaryButton: {
        value: $r('app.string.privacy_dialog_Allow'),
        action: () => {
          this.onAccept();
        }
      }
    }),
    alignment: DialogAlignment.Center,
    autoCancel: false,
    onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
      LogUtil.info(TAG, `dialog onWillDismiss: ${dismissDialogAction.reason}`);
    }
  })

  async aboutToAppear(): Promise<void> {
    try {
      this.getWantParms();
      if (this.isPickerShow) {
        this.deviceRotation = display.getDefaultDisplaySync().rotation;
        this.initDeviceInfo();
        this.handleFoldedState();
        this.initWindowProperties();
        await this.getCurrentAllScreenShot();
        this.getMissionIdOrDisplayId();
        await this.getCurrentAllMissionsShot();
        this.getMissionIdOrDisplayId();
        this.setFoldListener();
        this.setRotationListener();
        this.isShowPrivacyContent = this.imageWindowData.totalCount() > 0;
        this.session?.setWindowPrivacyMode(true);
      } else {
        this.dialogControllerImage.open();
      }
    } catch (err) {
      LogUtil.error(TAG, `Failed to aboutToAppear. Cause: ${err?.message}`);
    }
  }

  aboutToDisappear(): void {
    try {
      LogUtil.info(TAG, 'aboutToDisappear');
      this.session?.setWindowPrivacyMode(false);
      this.handleReleaseImagePixel();
      this.checkedMissionId = null;
      this.imageWindowData.clear();
      if (this.debounceCacheId !== null) {
        clearTimeout(this.debounceCacheId);
        this.debounceCacheId = null;
      }
      this.handleCancelListeningCallback();
      this.handleReportAVScreenCaptureUserChoice();
    } catch (err) {
      LogUtil.error(TAG, `Failed to aboutToDisappear. Cause: ${err?.message}`);
    }
  }

  onPageShow(): void {
    LogUtil.info(TAG, 'onPageShow');
  }

  onPageHide(): void {
    LogUtil.info(TAG, 'onPageHide');
  }

  private handleReportAVScreenCaptureUserChoice(): void {
    try {
      let jsonData: CommonSelectPicker.JsonData = {
        choice: 'false',
        displayId: -1,
        missionId: -1,
        checkBoxSelected: this.checkBoxSelected ? 'true' : 'false',
        isInnerAudioBoxSelected: this.isInnerAudioBoxSelected ? 'true' : 'false',
      }
      if (this.submitJsonData) {
        LogUtil.info(TAG, 'report choice is valid');
        jsonData = this.submitJsonData;
      }
      LogUtil.info(TAG, 'handleReportAVScreenCaptureUserChoice start');
      media.reportAVScreenCaptureUserChoice(this.sessionId, JSON.stringify(jsonData));
    } catch (err) {
      LogUtil.error(TAG, `Failed to handleReportAVScreenCaptureUserChoice. Cause: ${err?.message}`);
    }
  }

  private handleCancelListeningCallback(): void {
    try {
      LogUtil.info(TAG, 'handleCancelListeningCallback');
      if (this.windowSizeChangeCallback) {
        this.extensionWindow?.off('windowSizeChange', this.windowSizeChangeCallback);
      }
      if (this.foldStatusChangeCallback) {
        display.off('foldStatusChange', this.foldStatusChangeCallback);
      }
      if (this.displayChangeCallback) {
        display.off('change', this.displayChangeCallback);
      }
      this.windowSizeChangeCallback = undefined;
      this.foldStatusChangeCallback = undefined;
      this.displayChangeCallback = undefined;
    } catch (err) {
      LogUtil.error(TAG, `Failed to handleCancelListeningCallback, error: ${err?.message}`);
    }
  }

  private getWantParms(): void {
    try {
      let wantParams: Record<string, Object> | undefined = this.selectWant?.parameters as Record<string, Object>;
      if (wantParams === undefined) {
        LogUtil.error(TAG, 'wantParams is undefined');
        return;
      }
      this.getExcludedBundleName(wantParams);
      let wantShowShareSystemAudioBox: boolean = wantParams?.showShareSystemAudioBox as boolean;
      if (wantShowShareSystemAudioBox !== undefined && typeof wantShowShareSystemAudioBox === 'boolean') {
        this.showShareSystemAudioBox = wantShowShareSystemAudioBox;
        this.isInnerAudioBoxSelected = wantShowShareSystemAudioBox;
      }
      let wantCheckBoxSelected: string = wantParams?.checkBoxSelected as string;
      if (wantCheckBoxSelected !== undefined) {
        this.checkBoxSelected = wantCheckBoxSelected === '1';
      }
      let wantShowSensitiveCheckBox: string = wantParams?.showSensitiveCheckBox as string;
      if (wantShowSensitiveCheckBox !== undefined) {
        this.showSensitiveCheckBox = wantShowSensitiveCheckBox === '1';
      }
      let appLabel: string = wantParams?.appLabel as string;
      if (appLabel !== undefined) {
        this.appLabel = appLabel.toString();
      }
      let sessionIdStr = wantParams?.sessionId as string;
      if (sessionIdStr !== undefined) {
        let sessionId = Number(sessionIdStr);
        if (!Number.isNaN(sessionId)) {
          this.sessionId = sessionId;
        }
      }
      LogUtil.info(TAG, `wantParams showShareSystemAudioBox: ${this.showShareSystemAudioBox} ` +
        `isInnerAudioBoxSelected: ${this.isInnerAudioBoxSelected} checkBoxSelected: ${this.checkBoxSelected} ` +
        `wantShowSensitiveCheckBox: ${this.showSensitiveCheckBox} appLabel: ${this.appLabel} app: ${this.sessionId}`);

      this.excludedWindowIDs = wantParams?.excludedWindowIDs as number[] ?? [];
      this.pickerMode = wantParams?.pickerMode as number;
      this.isPickerShow = this.pickerMode !== undefined;
      LogUtil.info(TAG, `wantParams pickerMode: ${this.pickerMode} excludedWindowIDs: ${this.excludedWindowIDs}`);
    } catch (err) {
      LogUtil.error(TAG, `getWantParms error: ${err?.message}`);
    }
  }

  private getExcludedBundleName(wantParams: Record<string, Object>) {
    try {
      let callerUidStr: string = wantParams?.callerUid as string;
      if (callerUidStr === undefined) {
        LogUtil.error(TAG, `callerUidStr is undefined`);
        return;
      }
      let callerUid = Number(callerUidStr);
      if (Number.isNaN(callerUid)) {
        LogUtil.error(TAG, `callerUid is invalid`);
        return;
      }
      let data: string = bundleManager.getBundleNameByUidSync(callerUid);
      if (!data) {
        LogUtil.error(TAG, 'Failed to get bundle name');
        return;
      }
      LogUtil.info(TAG, `wantParams callerData: ${data}`);
      this.excludedBundleName = data;
    } catch (err) {
      LogUtil.error(TAG, `getExcludedBundleName error: ${err?.message}`);
    }
  }

  async updateWindowData(): Promise<void> {
    try {
      LogUtil.info(TAG, 'updateWindowData start');
      this.handleReleaseImagePixel();
      this.handleFoldedState();
      await this.getCurrentAllScreenShot();
      await this.getCurrentAllMissionsShot();
      this.getMissionIdOrDisplayId();
      LogUtil.info(TAG, 'updateWindowData end');
    } catch (err) {
      LogUtil.error(TAG, `updateWindowData error, reason: ${err?.message}`);
    }
  }

  private judgeHorizontalsOrVerticals(): void {
    try {
      let displayInfo = display.getDefaultDisplaySync();
      let orientation: number = displayInfo.orientation;
      if (display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_HALF_FOLDED) {
        this.isPortraitScreen = false;
        this.isLandscapeScreen = false;
        return;
      }
      this.isPortraitScreen =
        orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED;
      this.isLandscapeScreen =
        orientation === display.Orientation.LANDSCAPE || orientation === display.Orientation.LANDSCAPE_INVERTED;
      LogUtil.info(TAG,
        `judgeLandscapeOrPortrait orientation ${orientation} isPortraitScreen: ${this.isPortraitScreen} ` +
          `isLandscapeScreen: ${this.isLandscapeScreen}`);
    } catch (err) {
      LogUtil.error(TAG, `judgeHorizontalsOrVerticals failed, err: ${err?.message}`);
    }
  }

  private initWindowProperties(): void {
    try {
      let windowProperties: uiExtension.WindowProxyProperties | undefined = this.extensionWindow?.properties;
      this.windowWidth = this.handlePx2vp(windowProperties?.uiExtensionHostWindowProxyRect?.width);
      this.windowHeight = this.handlePx2vp(windowProperties?.uiExtensionHostWindowProxyRect?.height);
      this.updatePictureSize(this.windowWidth, this.windowHeight);
      this.windowSizeChangeCallback = (newSize: window.Size) => {
        LogUtil.info(TAG, 'windowSizeChangeCallback start');
        this.windowWidth = this.handlePx2vp(newSize.width);
        this.windowHeight = this.handlePx2vp(newSize.height);
        this.updatePictureSize(this.windowWidth, this.windowHeight);
      }
      this.extensionWindow?.on('windowSizeChange', this.windowSizeChangeCallback);
    } catch (err) {
      LogUtil.error(TAG, `Failed to initWindowProperties, error: ${err?.message}`);
    }
  }

  private updatePictureSize(width: number, height: number): void {
    LogUtil.info(TAG, 'updatePictureSize start');
    this.judgeHorizontalsOrVerticals();
    if (height === ZERO_SIZE || width === ZERO_SIZE) {
      this.displayRatio = 1;
      LogUtil.info(TAG, `zero height ratio: ${this.displayRatio}`);
    } else {
      // 计算窗口宽高比
      this.displayRatio = width / height;
      LogUtil.info(TAG, `winWidth: ${width}, winHeight: ${height}, ratio: ${this.displayRatio}`);
    }
    if (this.isFoldExpandedOrPad) {
      this.moduleImageHeight = EXPANDED_PAD_HEIGHT;
      this.moduleImageWidth = EXPANDED_PAD_HEIGHT * this.displayRatio;
    } else if (this.isSmallDeviceFolded) {
      this.moduleImageHeight = SMALL_DEVICE_HEIGHT;
      this.moduleImageWidth = SMALL_DEVICE_HEIGHT * this.displayRatio;
    } else {
      this.moduleImageWidth = (width - SCREEN_SPACE_WIDTH) / HALF_MODULE_WIDTH_RADIO;
      this.moduleImageHeight = this.moduleImageWidth / this.displayRatio;
    }
    this.moduleWindowWidth = this.moduleImageWidth + WINDOW_LIST_MARGIN;
    this.moduleWindowHeight = this.moduleImageHeight + WINDOW_LIST_MARGIN;
    this.windowPictureWidth = this.moduleImageWidth + WINDOW_LIST_MARGIN;
    this.windowPictureHeight = this.moduleImageHeight + MODULE_IMAGE_HEIGHT_MARGIN;
    LogUtil.info(TAG,
      `moduleImageWidth: ${this.moduleImageWidth}, moduleImageHeight: ${this.moduleImageHeight}, moduleWindowWidth: ` +
        `${this.moduleWindowWidth}, moduleWindowHeight: ${this.moduleWindowHeight}, ratio: ${this.displayRatio}`);
  }

  private initDeviceInfo(): void {
    this.isTabletDevice = this.isTabletProduct();
    this.getFoldProductTypeNum = this.getFoldProductType();
    this.isSmallFoldDevice = [
      CommonSelectPicker.FoldPhoneTypeValue.SMALL_FOLD,
      CommonSelectPicker.FoldPhoneTypeValue.EXPANDING_NEX_FORMS,
    ].includes(this.getFoldProductTypeNum);
  }

  private isTabletProduct(): boolean {
    let deviceType: string = deviceInfo.deviceType;
    LogUtil.info(TAG, `deviceType: ${deviceType}`);
    return deviceType === 'tablet';
  }

  private isSmallFoldProduct(): boolean {
    // 小折叠、阔折叠
    return [
      CommonSelectPicker.FoldPhoneTypeValue.SMALL_FOLD,
      CommonSelectPicker.FoldPhoneTypeValue.EXPANDING_NEX_FORMS,
    ].includes(this.getFoldProductType());
  }

  private getFoldProductType(): number {
    try {
      let productValue: string = systemParameterEnhance.getSync('const.window.foldscreen.type', '0,0,0,0');
      LogUtil.info(TAG, `getFoldProductType productValue: ${productValue}`);
      const result: string[] = productValue?.split(',');
      if (result === undefined) {
        return CommonSelectPicker.FoldPhoneTypeValue.INVALID_VALUE;
      }
      if (result.length === 0) {
        return CommonSelectPicker.FoldPhoneTypeValue.INVALID_VALUE;
      }
      let res: number = Number.parseInt(result[0]);
      if (Number.isNaN(res)) {
        LogUtil.error(TAG, 'Invalid product value format');
        return CommonSelectPicker.FoldPhoneTypeValue.INVALID_VALUE;
      }
      return res;
    } catch (err) {
      LogUtil.error(TAG, `getFoldProductType: isDevicePortrait failed. error: ${err?.code} ${err?.message}`);
    }
    return CommonSelectPicker.FoldPhoneTypeValue.INVALID_VALUE;
  }

  private handleFoldedState(): void {
    try {
      this.judgeHorizontalsOrVerticals();
      this.status = display.getFoldStatus();
      LogUtil.info(TAG, `handleFoldedState status: ${this.status} `);
      if (this.status === display.FoldStatus.FOLD_STATUS_EXPANDED ||
        this.status === display.FoldStatus.FOLD_STATUS_EXPANDED_WITH_SECOND_EXPANDED || this.isTabletDevice) {
        if (!this.isSmallFoldDevice) {
          LogUtil.info(TAG, 'handleFoldedState foldExpanded start');
          // 表示设备当前折叠状态为完全展开或者平板
          this.isFoldExpandedOrPad = true;
        } else {
          this.isFoldExpandedOrPad = false;
        }
        this.isSmallDeviceFolded = false;
      } else if (this.status === display.FoldStatus.FOLD_STATUS_HALF_FOLDED || this.status ===
      display.FoldStatus.FOLD_STATUS_EXPANDED_WITH_SECOND_HALF_FOLDED) {
        LogUtil.debug(TAG, 'handleFoldedState is half folded FOLD_STATUS_HALF_FOLDED');
        // 表示设备当前折叠状态为半折叠。半折叠指完全展开和折叠之间的状态
        this.isFoldExpandedOrPad = true;
        this.isSmallDeviceFolded = false;
      } else if (this.status === display.FoldStatus.FOLD_STATUS_FOLDED) {
        // 表示设备当前折叠状态为折叠
        LogUtil.debug(TAG, 'handleFoldedState is folded.');
        this.isFoldExpandedOrPad = false;
        this.isSmallDeviceFolded = this.isSmallFoldDevice;
      } else {
        this.isFoldExpandedOrPad = false;
        this.isSmallDeviceFolded = false;
        LogUtil.debug(TAG, 'handleFoldedState nothing');
      }
      LogUtil.info(TAG, `handleFoldedState status: ${this.status} isPortraitScreen: ${this.isPortraitScreen} ` +
        `isLandscapeScreen: ${this.isLandscapeScreen} isSmallDeviceFolded: ${this.isSmallDeviceFolded} ` +
        `isFoldExpandedOrPad: ${this.isFoldExpandedOrPad}`);
    } catch (err) {
      LogUtil.error(TAG, `handleFoldedState failed, message: ${err?.message}.`);
    }
  }

  private getAngle(): number {
    if (this.deviceRotation === NEGATIVE_ROTATION_NUM) {
      return -ROTATE_ANGLE_NUM;
    } else {
      return ROTATE_ANGLE_NUM;
    }
  }

  private setFoldListener(): void {
    try {
      if (!display.isFoldable()) {
        LogUtil.info(TAG, 'device not foldable, need return');
        return;
      }
      this.foldStatusChangeCallback = async (status) => {
        LogUtil.info(TAG, `setFoldListener status: ${status}`);
        this.handleFoldedState();
      };
      display.on('foldStatusChange', this.foldStatusChangeCallback);
    } catch (err) {
      LogUtil.error(TAG, `setFoldListener error: ${err?.message}`);
    }
  }

  private setRotationListener(): void {
    try {
      this.displayChangeCallback = () => {
        let newRotation: number = display.getDefaultDisplaySync().rotation;
        if (newRotation !== this.deviceRotation) {
          this.deviceRotation = newRotation;
          this.handleFoldedState();
        }
      };
      display.on('change', this.displayChangeCallback);
    } catch (err) {
      LogUtil.error(TAG, `setRotationListener error: ${err?.message}`);
    }
  }

  async getCurrentAllScreenShot(refresh: boolean = true): Promise<void> {
    try {
      if (this.pickerMode === undefined || this.pickerMode === CommonSelectPicker.PickerMode.WINDOW_ONLY) {
        LogUtil.info(TAG, `pickerMode is ${this.pickerMode}, getScreenShot need return.`);
        return;
      }
      let allDisplays: display.Display[] = await display.getAllDisplays();
      if (allDisplays.length === 0) {
        LogUtil.error(TAG, 'allDisplays is empty.');
        return;
      }
      if (allDisplays.length === 1 && this.checkedMissionId === null) {
        this.checkedMissionId = null;
        LogUtil.info(TAG, 'Only one screen, and select by default.');
      }
      for (let i = 0; i < allDisplays.length; i++) {
        let currentDisplayId: number = allDisplays[i].id;
        if (currentDisplayId === undefined) {
          continue;
        }
        LogUtil.info(TAG, `currentDisplay in: ${currentDisplayId}`);
        this.currentDisplayId = currentDisplayId
        if (this.currentDisplayId >= VIRTUAL_SCREEN) {
          LogUtil.info(TAG, 'The current screen is a virtual screen, not need to be displayed.');
          continue;
        }
        await this.getScreenShot(this.currentDisplayId, refresh);
      }
      LogUtil.info(TAG, `screenImageList length: ${allDisplays.length}`);
    } catch (err) {
      LogUtil.error(TAG, `Failed to get current all ScreenShot. error: ${err?.message}`);
    }
  }

  async getScreenShot(displayId: number, refresh: boolean = true): Promise<void> {
    let screenshotOptions: screenshot.ScreenshotOptions = {
      'rotation': 0,
      'displayId': displayId,
    };
    try {
      let screenPixelMap: image.PixelMap = await screenshot.save(screenshotOptions);
      let imageInfo: image.ImageInfo = await screenPixelMap.getImageInfo();
      if (this.missionImageMap.has(displayId)) {
        return;
      }
      let screenImageObj: CommonSelectPicker.WindowImageData = {
        missionShot: screenPixelMap,
        missionId: displayId,
        missionIcon: null,
        missionLabel: displayId.toString(),
        isDisplay: true,
        imageWidth: imageInfo?.size?.width ?? 0,
        imageHeight: imageInfo?.size?.height ?? 0,
      };
      this.displayIdSet.add(displayId);
      this.missionImageMap.set(displayId, screenImageObj);
      if (refresh) {
        this.imageWindowData.pushData(screenImageObj);
      }
    } catch (err) {
      LogUtil.error(TAG, `Failed to save screenshot. error: ${err?.message}`);
    }
  }

  async getCurrentAllMissionsShot(refresh: boolean = true): Promise<void> {
    try {
      if (this.pickerMode === undefined || this.pickerMode === CommonSelectPicker.PickerMode.SCREEN_ONLY) {
        LogUtil.info(TAG, `pickerMode is ${this.pickerMode}, getMissionsShot need return.`);
        return;
      }
      let missionImageList: missionManager.MissionInfo[] = await missionManager.getMissionInfos('', MAX_WINDOW_NUM);
      if (!missionImageList || missionImageList.length === 0) {
        LogUtil.info(TAG, `missionImageList is null.`);
        return;
      }
      for (const item of missionImageList) {
        let missionId: number = item.missionId;
        let bundleName: string | undefined = item.want?.bundleName;
        if (bundleName && bundleName === this.excludedBundleName) {
          LogUtil.info(TAG, `current bundleName is show picker, need continue.`);
          continue;
        }
        await this.getMissionInfo(missionId, refresh);
      }
      LogUtil.info(TAG, `missionImageList totalCount: ${this.imageWindowData.totalCount()}`);
    } catch (err) {
      LogUtil.error(TAG, `getCurrentAllMissionsShot error: ${err.code}, ${err?.message}`);
    }
  }

  async getMissionInfo(missionId: number, refresh: boolean): Promise<void> {
    try {
      let isExcluded: boolean = this.excludedWindowIDs?.includes(missionId) ?? false;
      if (isExcluded) {
        LogUtil.info(TAG, `mission: ${missionId}, isExcluded: ${isExcluded}`);
        return;
      }
      let missionInfo: missionManager.MissionInfo = await missionManager.getMissionInfo('', missionId);
      let missionShot: missionManager.MissionSnapshot =
        await missionManager.getMissionSnapShot('', missionInfo.missionId);
      let missionShotImage: image.PixelMap = missionShot.snapshot as image.PixelMap;
      if (!missionShot.ability) {
        LogUtil.error(TAG, 'missionShot.ability is null');
        return;
      }
      if (!missionShotImage) {
        LogUtil.error(TAG, 'missionShotImage is null');
        return;
      }
      let bundleName: string = missionShot.ability.bundleName;
      await this.getMissionsLabel(missionInfo.missionId, bundleName, missionShotImage, refresh);
    } catch (err) {
      LogUtil.error(TAG, `getMissionInfo failed : ${err?.message}`);
    }
  }

  async getMissionsLabel(missionId: number, bundleName: string, missionShotImage: image.PixelMap,
    refresh: boolean): Promise<void> {
    try {
      let bundleFlags: bundleResourceManager.ResourceFlag = bundleResourceManager.ResourceFlag.GET_RESOURCE_INFO_ALL;
      if (bundleName === SCREEN_BUNDLE_NAME) {
        LogUtil.info(TAG, 'bundleName is screenRecorder need return');
        return;
      }
      if (bundleName === '' || bundleName === undefined) {
        return;
      }
      let resourceInfo: bundleResourceManager.BundleResourceInfo =
        bundleResourceManager.getBundleResourceInfo(bundleName.toString(), bundleFlags);
      let missionLabel: string = resourceInfo.label;
      let missionIcon: string = resourceInfo.icon;
      let imageInfo: image.ImageInfo = await missionShotImage.getImageInfo();
      if (imageInfo === undefined) {
        LogUtil.warn(TAG, `${bundleName} failed to obtain the image pixel map information`);
      }
      if (!this.missionImageMap.has(missionId)) {
        let missionImageData: CommonSelectPicker.WindowImageData = {
          missionShot: missionShotImage,
          missionId: missionId,
          missionLabel: missionLabel,
          missionIcon: missionIcon,
          isDisplay: false,
          imageWidth: imageInfo?.size?.width ?? 0,
          imageHeight: imageInfo?.size?.height ?? 0,
        }
        this.missionImageMap.set(missionId, missionImageData);
        if (refresh) {
          this.imageWindowData.pushData(missionImageData);
        }
      }
    } catch (err) {
      LogUtil.error(TAG, `getMissionsLabel failed : ${err?.message}`);
    }
  }

  private getMissionIdOrDisplayId(): void {
    try {
      let wantDisplayIds: number[] | undefined = this.selectWant?.parameters?.displayIds as number[];
      let wantMissionIds: number[] | undefined = this.selectWant?.parameters?.missionIds as number[];
      wantDisplayIds = Array.isArray(wantDisplayIds) ? wantDisplayIds : undefined;
      wantMissionIds = Array.isArray(wantMissionIds) ? wantMissionIds : undefined;
      LogUtil.info(TAG, `wantParams wantDisplay: ${wantDisplayIds}, wantMission: ${wantMissionIds}`);

      let wantDisplayId: number | undefined = undefined;
      let wantMissionId: number | undefined = undefined;
      if (wantDisplayIds != undefined && wantDisplayIds.length > 0) {
        wantDisplayId = wantDisplayIds[0];
      }
      if (wantMissionIds !== undefined && wantMissionIds.length > 0) {
        wantMissionId = wantMissionIds[0];
      }
      if (this.missionImageMap.size > 0 && (this.pickerMode === CommonSelectPicker.PickerMode.WINDOW_ONLY ||
        ((this.pickerMode === undefined || this.pickerMode === CommonSelectPicker.PickerMode.SCREEN_AND_WINDOW) &&
          wantMissionId !== undefined && wantMissionId >= 0))
      ) {
        let getDataMissionId: number = this.imageWindowData.getData(0)?.missionId as number ?? -1;
        this.checkedMissionId = wantMissionId !== undefined && this.missionImageMap.has(wantMissionId) ? wantMissionId :
          getDataMissionId;
        this.canStartScreenCapture = true;
        LogUtil.info(TAG, `getMissionIdOrDisplayId, select window: ${this.checkedMissionId}`);
      } else if (this.missionImageMap.size === 0 && this.pickerMode === CommonSelectPicker.PickerMode.WINDOW_ONLY) {
        this.checkedMissionId = null;
        this.canStartScreenCapture = false;
        LogUtil.info(TAG, `getMissionIdOrDisplayId, show window only and window list is empty`);
      } else {
        let currentDisplayId: number = Number(wantDisplayId);
        if (Number.isNaN(currentDisplayId)) {
          LogUtil.info(TAG, 'Invalid displayId');
          this.checkedMissionId = 0;
        } else {
          this.checkedMissionId = currentDisplayId;
        }
        if (this.imageWindowData.totalCount() > 0) {
          this.canStartScreenCapture = true;
        }
        LogUtil.info(TAG, `currentDisplay: ${currentDisplayId}, checkedMission: ${this.checkedMissionId}`);
      }
    } catch (err) {
      LogUtil.error(TAG, `getMissionIdOrDisplayId error: ${err?.message}`);
    }
  }

  private debounce(func: () => void, wait: number = 1000): void {
    try {
      if (this.debounceCacheId !== null) {
        LogUtil.info(TAG, 'debounce clearTimeout');
        clearTimeout(this.debounceCacheId);
      }
      let timeoutID: number = setTimeout(() => {
        typeof func === 'function' && func();
        clearTimeout(timeoutID);
        this.debounceCacheId = null;
      }, wait);
      this.debounceCacheId = timeoutID;
    } catch (err) {
      LogUtil.error(TAG, `debounce error: ${err?.message}`);
    }
  }

  private isRTL(): boolean {
    try {
      const systemLocale: string = I18n.System.getSystemLocale();
      return I18n.isRTL(systemLocale);
    } catch (err) {
      LogUtil.error(TAG, `getSystemLocale failed, message: ${err?.message}.`);
      return false;
    }
  }

  private sleep(time: number): Promise<void> {
    return new Promise((resolve: () => void) => setTimeout(resolve, time));
  }

  public getStringSync(resource: ResourceStr, idx: number | null): string {
    if (typeof resource === 'string') {
      return resource;
    }
    const context: Context | undefined = this.globalThisInstance?.getObject('privacyDialogContext') as Context;
    if (!context) {
      LogUtil.error(TAG, 'getStringSync context is null.');
      return '';
    }
    try {
      let strSync: string = context.resourceManager.getStringSync(resource.id)
      if (idx === null) {
        return strSync;
      }
      return `${strSync}${Number(idx) + 1}`;
    } catch (err) {
      LogUtil.error(TAG, 'getStringSync error.', err?.message);
    }
    return '';
  }

  private handleReleaseImagePixel(): void {
    try {
      LogUtil.info(TAG, 'handleReleaseImagePixel');
      this.missionImageMap.forEach((item: CommonSelectPicker.WindowImageData) => {
        try {
          if (item.missionShot !== null) {
            item.missionShot.release();
            item.missionShot = null;
          }
        } catch (err) {
          LogUtil.error(TAG, `Failed to release missionImageMap missionShot: ${err?.message}`);
        }
      })
      this.missionImageMap.clear();
    } catch (err) {
      LogUtil.error(TAG, `Failed to handleReleaseImagePixel. Cause: ${err?.message}`);
    }
  }

  private handlePx2vp(size: number | undefined): number {
    try {
      if (size === undefined) {
        return 0;
      }
      return this.getUIContext().px2vp(size);
    } catch (err) {
      LogUtil.error(TAG, `Failed to handlePx2vp. Cause: ${err?.message}`);
    }
    return 0;
  }

  private async handleTerminateSelf(): Promise<void> {
    try {
      if (this.session) {
        LogUtil.info(TAG, 'handleTerminateSelf start');
        await this.sleep(TERMINATE_SLEEP_TIME);
        await this.session.terminateSelf();
      }
    } catch (err) {
      LogUtil.error(TAG, `Failed in handleTerminateSelf. reason: ${err?.message}`);
    }
  }

  private onCancel(): void {
    LogUtil.info(TAG, `Callback when the onCancel button is clicked, checkBoxSelected: ${this.checkBoxSelected}`)
    this.isPickerShow = false;
    this.globalThisInstance?.setObject('UserChoice', 'false');
    this.globalThisInstance?.setObject('userCheckBoxSelect', this.checkBoxSelected);
    this.dialogControllerImage.close();
    this.handleTerminateSelf();
    this.handleDialogReport('false');
  }

  private onAccept(): void {
    LogUtil.info(TAG, `Callback when the onAccept button is clicked, checkBoxSelected: ${this.checkBoxSelected}`)
    this.globalThisInstance?.setObject('UserChoice', 'true');
    this.globalThisInstance?.setObject('userCheckBoxSelect', this.checkBoxSelected);
    this.dialogControllerImage.close();
    this.handleTerminateSelf();
    this.handleDialogReport('true');
  }

  private async handleDialogReport(userChoice: string): Promise<void> {
    try {
      let checkBoxSelected: boolean = this.checkBoxSelected;
      LogUtil.info(TAG, `handleDialogReport userChoice: ${userChoice}, checkBoxSelected: ${checkBoxSelected}`);
      const jsonData: CommonSelectPicker.JsonData = {
        choice: userChoice,
        displayId: -1,
        missionId: -1,
        checkBoxSelected: checkBoxSelected ? 'true' : 'false',
      }
      this.submitJsonData = jsonData;
    } catch (err) {
      LogUtil.error(TAG, `reportAVScreenCaptureUserChoice error: ${err?.message}`);
    }
  }

  private async handleSelectBackBtn(): Promise<void> {
    try {
      LogUtil.info(TAG, 'click back button');
      this.isPickerShow = false;
      const jsonData: CommonSelectPicker.JsonData = {
        choice: 'false',
        displayId: -1,
        missionId: -1,
        checkBoxSelected: this.checkBoxSelected ? 'true' : 'false',
        isInnerAudioBoxSelected: this.isInnerAudioBoxSelected ? 'true' : 'false',
      }
      LogUtil.info(TAG, `back button json: ${JSON.stringify(jsonData)}`);
      this.submitJsonData = jsonData;
      this.globalThisInstance?.setObject('isReportedToServer', true);
      this.globalThisInstance?.setObject('userCheckBoxSelect', this.checkBoxSelected);
      this.globalThisInstance?.setObject('userCheckAudioSelect', this.isInnerAudioBoxSelected);
      await this.handleTerminateSelf();
    } catch (err) {
      LogUtil.error(TAG, `Failed in handleSelectBackBtn, err: ${err?.message} `);
    }
  }

  private async handleSelectShareBtn(): Promise<void> {
    try {
      LogUtil.info(TAG, 'click start share button');
      this.isPickerShow = false;
      let displayId: number | number[] | null = -1;
      let checkedMissionId: number | null = this.checkedMissionId;
      if (this.checkedMissionId !== null && this.displayIdSet.has(this.checkedMissionId)) {
        displayId = this.checkedMissionId;
        checkedMissionId = -1;
      }
      let jsonData: CommonSelectPicker.JsonData = {
        choice: 'true',
        displayId: displayId,
        missionId: checkedMissionId,
        checkBoxSelected: this.checkBoxSelected ? 'true' : 'false',
        isInnerAudioBoxSelected: this.isInnerAudioBoxSelected ? 'true' : 'false',
      };
      if (jsonData.missionId && jsonData.missionId !== -1) {
        LogUtil.info(TAG, `Drag the selected window to the foreground.`);
        let startOptions: StartOptions = {
          displayId: -1,
        }
        LogUtil.info(TAG, 'set displayId is -1');
        await missionManager.moveMissionToFront(jsonData.missionId, startOptions);
      }
      LogUtil.info(TAG, `report the choice data json: ${JSON.stringify(jsonData)}`);
      this.submitJsonData = jsonData;
      this.globalThisInstance?.setObject('isReportedToServer', true);
      this.globalThisInstance?.setObject('userCheckBoxSelect', this.checkBoxSelected);
      this.globalThisInstance?.setObject('userIsInnerAudioBoxSelected', this.isInnerAudioBoxSelected);
      await this.handleTerminateSelf();
    } catch (err) {
      LogUtil.error(TAG, `Failed in handleSelectShareBtn, err: ${err?.message}`);
    }
  }

  build() {
    Row() {
      Column() {
      }
      .width('100%')
      .height('100%')
      .bindSheet($$this.isPickerShow, this.PreviewComponentBuilder(), {
        title: { title: $r('app.string.select_window_name') },
        maskColor: $r('sys.color.ohos_id_color_mask_thin'),
        backgroundColor: $r('sys.color.ohos_id_color_panel_bg'),
        height: SheetSize.LARGE,
        blurStyle: BlurStyle.COMPONENT_ULTRA_THICK,
        dragBar: false,
        showClose: true,
        enableOutsideInteractive: false,
        preferType: SheetType.CENTER,
        // modalTransition: ModalTransition.NONE,
        onWillDismiss: ((dismissSheetAction: DismissSheetAction) => {
          if (dismissSheetAction.reason !== DismissReason.TOUCH_OUTSIDE) {
            LogUtil.info(TAG, 'BindSheet DialogPage onWillDismiss.');
            this.debounce(() => {
              dismissSheetAction.dismiss();
              this.handleSelectBackBtn();
            }, BUTTON_CLICK_TIME);
          }
        }),
        onWillSpringBackWhenDismiss: (() => {
        }),
      })
      .onTouchIntercept((data) => {
        return HitTestMode.Block;
      })
    }
    .width('100%')
  }
}