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
import { TipsDialog } from '@kit.ArkUI';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import Want from '@ohos.app.ability.Want';

/* instrument ignore file */
const TAG = 'PrivacyDialog';

@Entry
@Component
export struct DialogPage {
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private want = this.globalThisInstance!.getObject('privacyDialogWant') as Want;
  private session = this.globalThisInstance!.getObject('privacySession') as UIExtensionContentSession;
  private appLabel: string = '';
  private isChecked: boolean = false;
  private showSensitiveCheckBox: boolean = false;

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
      isChecked: this.isChecked,
      checkTips: this.showSensitiveCheckBox ? $r('app.string.screen_privacy_protection') : undefined,
      onCheckedChange: () => {
        this.isChecked = !this.isChecked;
        LogUtil.info(TAG, `this.isChecked: ${this.isChecked}`);
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
      this.onCancel();
    }
  })

  async onCancel() {
    LogUtil.info(TAG, 'Callback when the first button is clicked')
    this.globalThisInstance!.setObject('UserChoice', 'false');
    this.globalThisInstance!.setObject('userCheckBoxSelect', this.isChecked);
    LogUtil.info(TAG, 'this.isChecked checkBoxSelected1 ' + this.isChecked)
    this.dialogControllerImage.close();
    setTimeout(async () => {
      await this.session.terminateSelf();
    }, 300);
  }

  async onAccept() {
    LogUtil.info(TAG, 'Callback when the second button is clicked')
    this.globalThisInstance!.setObject('UserChoice', 'true');
    this.globalThisInstance!.setObject('userCheckBoxSelect', this.isChecked);
    LogUtil.info(TAG, 'this.isChecked checkBoxSelected2 ' + this.isChecked)
    this.dialogControllerImage.close();
    setTimeout(async () => {
      await this.session.terminateSelf();
    }, 300);
  }

  onPageShow(): void {
    this.getAppName();
    this.getIsShowSensitiveCheckBox();
    this.getIsCheckBoxSelected();
    LogUtil.info(TAG, 'onPageShow');
    this.dialogControllerImage.open();
  }

  onPageHide(): void {
    LogUtil.info(TAG, 'onPageHide');
  }

  getAppName() {
    try {
      if (this.want.parameters?.appLabel !== undefined) {
        this.appLabel = (this.want.parameters?.appLabel).toString();
        LogUtil.info(TAG, 'appLabel: ' + this.appLabel);
      }
    } catch (err) {
      LogUtil.error(TAG, 'getAppName error: ' + JSON.stringify(err));
    }
  }

  getIsShowSensitiveCheckBox() {
    try {
      LogUtil.info(TAG, 'this.want: ' + JSON.stringify(this.want));
      if (this.want.parameters?.showSensitiveCheckBox !== undefined) {
        this.showSensitiveCheckBox = (this.want.parameters?.showSensitiveCheckBox) === '1';
        LogUtil.info(TAG, 'showSensitiveCheckBox: ' + this.showSensitiveCheckBox);
      }
    } catch (err) {
      LogUtil.error(TAG, 'getIsShowSensitiveCheckBox error');
    }
  }

  getIsCheckBoxSelected() {
    try {
      if (this.want.parameters?.checkBoxSelected !== undefined) {
        this.isChecked = (this.want.parameters?.checkBoxSelected) === '1';
        LogUtil.info(TAG, 'checkBoxSelected : ' + this.isChecked );
      }
    } catch (err) {
      LogUtil.error(TAG, 'getIsCheckBoxSelected error');
    }
  }

  build() {}
}