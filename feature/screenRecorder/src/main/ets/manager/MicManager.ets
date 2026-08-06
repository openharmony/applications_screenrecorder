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
import { EventReportUtil, GlobalThisUtil, LogUtil, PreferenceUtils } from '@ohos/common';
import { SetSwitchType, } from '@ohos/common/src/main/ets/util/EventReportUtil';
import { common } from '@kit.AbilityKit';
import lazy { promptAction } from '@kit.ArkUI';
import { audio } from '@kit.AudioKit';
import { BusinessError } from '@ohos.base';
import { RecorderFileManager } from './RecorderFileManager';
import { RecorderToast } from './RecorderToast';
import { RecordManager } from './RecordManager';


const TAG = 'MicManager';

/**
 * 麦克风管理类
 */
export class MicManager {
  private static instance: MicManager = new MicManager();
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private dataPreferences: PreferenceUtils = new PreferenceUtils();
  private audioManager: audio.AudioManager = audio.getAudioManager();
  private isMicUnavailable: boolean = false;
  private pcMicEnableState: boolean = false;

  /**
   * Check if microphone is available
   *
   * @return If microphone is available.
   */
  getIsMicUnavailable(): boolean {
    return this.isMicUnavailable;
  }

  /**
   * 设置麦克风不可用
   *
   * @param enabled 启用状态
   */
  setIsMicUnavailable(enabled: boolean) {
    this.isMicUnavailable = enabled;
  }

  /**
   * 获取PC麦克风状态
   *
   * @returns 结果
   */
  getPcMicEnableState(): boolean {
    return this.pcMicEnableState;
  }

  /**
   * 设置PC麦克风状态
   *
   * @param enabled 麦克风状态
   */
  setPcMicEnableState(enabled: boolean) {
    this.pcMicEnableState = enabled;
  }

  /**
   * 获取麦克风管理实例
   *
   * @returns 实例
   */
  static getInstance(): MicManager {
    return MicManager.instance;
  }

  /**
   * 获取最后一次麦克风启用状态
   *
   * @param { AsyncCallback<ValueType> } callback - returns the mic state value.
   */
  async getMicEnabledState(callback: (result: boolean) => void) {
    try {
      const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
      const res = this.dataPreferences.getPreferencesValueByKeySync(context, 'isMicEnabled', false);
      callback(res as boolean);
    } catch (error) {
      LogUtil.error(TAG, 'getCurrentShowTouchState failed, error:', (error as BusinessError).message);
    }
  }

  /**
   * Set microphone enable or disable.
   *
   * @param { boolean } enable - Set microphone enable or disable during recording.
   * @returns
   */
  async setMicEnabled(enabled: boolean, recorderFileManager: RecorderFileManager): Promise<boolean> {
    LogUtil.warn(TAG, 'setMicEnabled enabled = ' + enabled);
    EventReportUtil.setSwitchMicType(enabled ? SetSwitchType.TRIGGERED_TYPE_SWITCH_ON :
    SetSwitchType.TRIGGERED_TYPE_SWITCH_OFF);
    try {
      LogUtil.info(TAG,
        `this.recorderFileManager.getAvScreenCaptureRecorder() :${recorderFileManager.getAvScreenCaptureRecorder()}`);
      await recorderFileManager.getAvScreenCaptureRecorder()?.setMicEnabled(enabled);
      this.dataPreferences.setPreferenceKeyValueSync('isMicEnabled', enabled);
      return true;
    } catch (error) {
      LogUtil.error(TAG, 'Failed to setMicEnabled. Code: ' + JSON.stringify(error));
      RecorderToast.getInstance().showToast('microphone_being_used_toast', promptAction.ToastShowMode.SYSTEM_TOP_MOST);
      return false;
    }
  }

  /**
   * 校验PC麦克风状态
   *
   * @returns 结果
   */
  async checkPcMicState(): Promise<void> {
    try {
      const groupid = audio.DEFAULT_VOLUME_GROUP_ID;
      const audioVolumeGroupManager = await this.audioManager.getVolumeManager().getVolumeGroupManager(groupid);
      let isEnable: boolean = await audioVolumeGroupManager.isMicrophoneMute();
      this.setPcMicEnableState(isEnable);
      LogUtil.info(TAG, `isMicrophoneMute is: ${isEnable}`);
    } catch (error) {
      await RecordManager.getInstance().handleError(error, 'checkPcMicState', true);
    }
  }

  async setMicUnableForPC(): Promise<boolean> {
    try {
      await RecorderFileManager.getInstance().getAvScreenCaptureRecorder()?.setMicEnabled(false);
      return true;
    } catch (error) {
      LogUtil.error(TAG, 'Failed to setMicUnableForPC. Code: ' + JSON.stringify(error));
      RecorderToast.getInstance().showToast('hw_video_without_voice_2', promptAction.ToastShowMode.SYSTEM_TOP_MOST);
      return false;
    }
  }
}