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

import { BusinessError } from '@ohos.base';
import commonEventManager from '@ohos.commonEventManager';

import { LogUtil } from './LogUtil';

const TAG = 'commonEventUtil';

export class CommonEventUtil {
  private eventSubscriber?: commonEventManager.CommonEventSubscriber;
  private events: string[] = [];
  private callBack?: (commonEvent?: commonEventManager.CommonEventData) => Promise<void>;

  constructor(events: string[], callBack: () => Promise<void>) {
    this.events = events;
    this.callBack = callBack;
  }

  public async subscribe(targetBundle?: string, subscriberPermissions?: string): Promise<void> {
    try {
      const handleSubscribeCallback = async (err: BusinessError, commonEvent: commonEventManager.CommonEventData) => {
        /* instrument ignore if */
        if (err) {
          LogUtil.error(TAG, `subscribe failed: { code: ${err?.code}, message: ${err?.message}}`);
        } else {
          LogUtil.warn(TAG, 'get event from eventSubscriber: ' + commonEvent.event);
          await this.callBack?.(commonEvent);
        }
      }
      this.eventSubscriber = commonEventManager.createSubscriberSync(targetBundle ?
        {
          events: this.events,
          publisherBundleName: targetBundle,
          publisherPermission: subscriberPermissions
        } :
        { events: this.events });
      commonEventManager.subscribe(this.eventSubscriber, handleSubscribeCallback);
    } catch (error) {
      this.eventSubscriber = undefined;
      LogUtil.error(TAG, `createSubscriber failed: { code: ${error?.code}, message: ${error?.message}}`);
    }
  }

  public unsubscribe(): void {
    try {
      this.eventSubscriber && commonEventManager.unsubscribe(this.eventSubscriber);
    } catch (error) {
      LogUtil.error(TAG, `unsubscribe failed: { code: ${error?.code}, message: ${error?.message}}`);
    }
  }
}
