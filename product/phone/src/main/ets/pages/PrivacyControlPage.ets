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
import { CommonUtil, GlobalThisUtil, LogUtil } from '@ohos/common';
import window from '@ohos.window';
import { Want } from '@kit.AbilityKit';
import { ComposeListItem, display } from '@kit.ArkUI';
import { media } from '@kit.MediaKit';
import { JSON } from '@kit.ArkTS';

/* instrument ignore file */
const TAG: string = 'PrivacyControlPage';
const SYSTEM_PRIVACY: number = 0;
const APP_PRIVACY: number = 1;

interface PrivacyJsonData {
  appPrivacyProtectionSwitch: string
  systemPrivacyProtectionSwitch: string
}

interface StopJsonData {
  stopRecording: string
}

/**
 * AVScreenCapture notification privacy control page
 *
 * @since 2025-7-11
 */
@Entry
@Component
export struct PrivacyControlPage {
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private appLabel: string = '';
  private captureSessionId: number = 0;
  private systemSwitchStatus: boolean = false;
  private appSwitchStatus: boolean = false;
  @State isAppearedFromBelow: boolean = true;
  @StorageProp('bindSheetShow') bindSheetShow: boolean | undefined = true;

  aboutToAppear(): void {
    LogUtil.info(TAG, 'aboutToAppear');
    this.getBasicInfo();
    this.getSwitchStatus();
    this.isAppearedFromBelow = this.checkIsAppearedFromBelow();
  }

  aboutToDisappear(): void {
    LogUtil.info(TAG, 'aboutToDisappear');
  }

  getBasicInfo() {
    try {
      let privateWant: Want = this.globalThisInstance!.getObject('privacyControlWant') as Want;
      if (privateWant.parameters?.appLabel !== undefined) {
        this.appLabel = (privateWant.parameters?.appLabel).toString();
        LogUtil.info(TAG, 'appLabel: ' + this.appLabel);
      }
      if (privateWant.parameters?.sessionId !== undefined) {
        this.captureSessionId = Number(privateWant.parameters?.sessionId);
        LogUtil.info(TAG, 'sessionId: ' + this.captureSessionId);
      }
    } catch (err) {
      LogUtil.error(TAG, 'getBasicInfo error: ' + JSON.stringify(err));
    }
  }

  getSwitchStatus() {
    try {
      let privacyJSON: object = this.globalThisInstance!.getObject('privacyControlData') as object;
      LogUtil.info(TAG, `privacyJSON: ${JSON.stringify(privacyJSON)}`);
      this.systemSwitchStatus = privacyJSON?.['systemPrivacyProtectionSwitch'] as boolean;
      this.appSwitchStatus = privacyJSON?.['appPrivacyProtectionSwitch'] as boolean;
      LogUtil.info(TAG, `getSwitchStatus ${this.systemSwitchStatus}, ${this.appSwitchStatus}`);
    } catch (err) {
      LogUtil.error(TAG, 'getSwitchStatus error: ' + JSON.stringify(err));
    }
  }

  checkIsAppearedFromBelow(): boolean {
    try {
      if (!CommonUtil.checkIfDeviceIsPhone()) {
        LogUtil.info(TAG, 'not phone device');
        return false;
      }
      if (!CommonUtil.isFoldableDevice()) {
        LogUtil.info(TAG, 'phone device and cannot fold');
        return true;
      }
      if (CommonUtil.isSingleDisplayPocketFoldDevice() && CommonUtil.isExpandedDevice()) {
        LogUtil.info(TAG, 'phone device and in small fold state, and start from below');
        return true;
      }
      if (display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_FOLDED ||
        display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_FOLDED_WITH_SECOND_EXPANDED ||
        display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_FOLDED_WITH_SECOND_HALF_FOLDED) {
        LogUtil.info(TAG, 'single display mode, start from below');
        return true;
      }
    } catch (error) {
      LogUtil.error(TAG, 'isAppearedFromBelow error:' + error.message);
    }
    return false;
  }

  @Builder
  composeItemBuilder(privacyMode: number) {
    ListItem() {
      ComposeListItem({
        contentItem: ({
          primaryText: privacyMode === SYSTEM_PRIVACY ? $r('app.string.private_protect_system') :
          $r('app.string.private_protect_app'),
          secondaryText: privacyMode === SYSTEM_PRIVACY ? $r('app.string.private_protect_system_content') :
          $r('app.string.private_protect_app_content')
        }),
        operateItem: ({
          switch: {
            isCheck: privacyMode === SYSTEM_PRIVACY ? this.systemSwitchStatus : this.appSwitchStatus,
            onChange: async (switchStatus: boolean) => {
              let logInfo = privacyMode === SYSTEM_PRIVACY ? 'system' : 'app';
              LogUtil.info(`${logInfo} component status: ${switchStatus}`);
              if (privacyMode === SYSTEM_PRIVACY) {
                this.systemSwitchStatus = switchStatus;
              } else {
                this.appSwitchStatus = switchStatus;
              }
              const jsonData: PrivacyJsonData = {
                appPrivacyProtectionSwitch: this.appSwitchStatus ? 'true' : 'false',
                systemPrivacyProtectionSwitch: this.systemSwitchStatus ? 'true' : 'false'
              }
              await media.reportAVScreenCaptureUserChoice(this.captureSessionId, JSON.stringify(jsonData));
            }
          }
        })
      })
    }
  }

  @Builder
  privacyController() {
    Column() {
      Column() {
        List() {
          this.composeItemBuilder(SYSTEM_PRIVACY);
          this.composeItemBuilder(APP_PRIVACY);
        }
        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
        .borderRadius(20)
        .margin({ top: 8, bottom: 16 })
        .padding({ top: 4, bottom: 4 })
        .divider({
          strokeWidth: '1px',
          color: $r('sys.color.ohos_id_color_list_separator'),
          startMargin: 12,
          endMargin: 12
        })
      }
      Column() {
        Button($r('app.string.private_window_stop_button'), { buttonStyle: ButtonStyleMode.NORMAL, role: ButtonRole.ERROR })
          .width('100%')
          .onClick(async () => {
            LogUtil.info(TAG, 'Stop button clicked.');
            let stopData: StopJsonData = {
              stopRecording: 'true'
            }
            await media.reportAVScreenCaptureUserChoice(this.captureSessionId, JSON.stringify(stopData));
            let privacyWindow = this.globalThisInstance.getObject('PrivacyBindSheet') as window.Window;
            if (privacyWindow !== undefined) {
              LogUtil.info(TAG, 'privacyWindow not null, need to destroy');
              privacyWindow.destroyWindow();
              this.globalThisInstance.setObject('PrivacyBindSheet', undefined);
            }
          })
      }
    }
    .id('privacy_control')
    .height(this.isAppearedFromBelow ? 'auto' : '100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 16, right: 16, bottom: this.isAppearedFromBelow ? 44 : 16})
  }

  build() {
    Column()
      .bindSheet(this.bindSheetShow, this.privacyController, {
        onWillAppear: () => {
          LogUtil.info(TAG, 'BindSheet onWillAppear.');
        },
        onAppear: () => {
          LogUtil.info(TAG, 'BindSheet onAppear.');
        },
        onWillDisappear: () => {
          LogUtil.info(TAG, 'BindSheet onWillDisappear.');
        },
        onDisappear: () => {
          LogUtil.info(TAG, 'BindSheet onDisappear.');
          let privacyWindow = this.globalThisInstance.getObject('PrivacyBindSheet') as window.Window;
          if (privacyWindow !== undefined) {
            LogUtil.info(TAG, 'privacyWindow not null, need to destroy');
            privacyWindow.destroyWindow();
            this.globalThisInstance.setObject('PrivacyBindSheet', undefined);
          }
        },
        height: SheetSize.FIT_CONTENT,
        title: { title: $r('app.string.private_window_title', this.appLabel)}
      })
  }
}