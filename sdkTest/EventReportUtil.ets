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

import bundleManager from '@ohos.bundle.bundleManager';
import hiSysEvent from '@ohos.hiSysEvent';
import { BusinessError } from '@ohos.base';
import { LogUtil } from './LogUtil';

const TAG: string = 'EventReportUtil';
const BUNDLE_NAME: string = 'com.ohos.calculator';
const DOMAIN: string = 'CALCULATOR';
// UE行为打点
const DOMAIN_UE: string = 'CALCULATOR_UE';

interface ReportParams {
  PNAMEID: string;
  PVERSIONID: string;
  TIME?: number;
  VALUE?: string;
}

/**
 * Event Report Util
 *
 * @since 2025-04-23
 */
export class EventReportUtil {
  private static applicationVersion: string;

  static reportEvent(eventType: hiSysEvent.EventType, eventName: string, time?: number, value?: string): void {
    if (!EventReportUtil.applicationVersion) {
      EventReportUtil.getApplicationVersion();
    }
    let params: ReportParams = {
      PNAMEID: BUNDLE_NAME,
      PVERSIONID: EventReportUtil.applicationVersion,
      TIME: time,
      VALUE: value
    };
    LogUtil.info(TAG, `eventName: ${eventName} ${params.PVERSIONID}`);
    hiSysEvent.write({
      domain: DOMAIN_UE,
      name: eventName,
      eventType: eventType,
      params: params
    }).then(
      (val) => {
        LogUtil.info(TAG, `${eventName} ${value} success.`);
      }
    ).catch(
      (err: BusinessError) => {
        LogUtil.error(TAG, `${eventName}  error. code: ${err.code} ,message: ${err.message}`);
      }
    )
    return;
  }

  static getApplicationVersion() {
    let bundleFlags: bundleManager.BundleFlag = bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT;
    try {
      let data = bundleManager.getBundleInfoForSelfSync(bundleFlags);
      LogUtil.info(TAG, `getBundleInfoForSelf successfully`);
      EventReportUtil.applicationVersion = data?.versionName;
    } catch (err) {
      const code: number = (err as BusinessError).code;
      const message: string = (err as BusinessError).message;
      LogUtil.error(TAG, `getBundleInfoForSelf failed: ${code} ${message}`);
    }
  }
}