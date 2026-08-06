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
import BackupExtensionAbility, { BundleVersion } from '@ohos.application.BackupExtensionAbility';

/* instrument ignore file */
const TAG = `BackupExtensionAbility`;

/**
 * ResultExInfo对象定义
 */
export interface IResultExInfo {
  resultInfo: [IResultErrorInfo, IResultCountInfo];
}

/**
 * ResultErrorInfo对象定义
 */
export interface IResultErrorInfo {
  type: string;
  errorCode: string;
  errorInfo: string;
}

/**
 * ResultCountInfo对象定义
 */
export interface IResultCountInfo {
  type: string;
  infos: IResultCountListInfo[];
}

/**
 * ResultCountList对象定义
 */
export interface IResultCountListInfo {
  backupInfo: string;
  successCount: number;
  duplicateCount: number;
  failedCount: number;
  details: string[] | null;
}


export default class BackupExtension extends BackupExtensionAbility {
  onBackup() {
    LogUtil.info(TAG, `onBackup ok`);
  }

  async onRestoreEx(bundleVersion: BundleVersion, restoreInfo: string): Promise<string> {
    LogUtil.info(TAG, `onRestore ok, code: ${bundleVersion.code}, name: ${bundleVersion.name}`);
    let resultInfo: IResultExInfo = {
      resultInfo: [
        {
          type: 'ErrorInfo',
          errorCode: '0',
          errorInfo: '',
        },
        {
          type: 'CountInfo',
          infos: [{
            backupInfo: '',
            successCount: 0,
            duplicateCount: 0,
            failedCount: 0,
            details: null,
          }],
        },
      ]
    }
    return JSON.stringify(resultInfo);
  }
}