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
import { StartOptions, Want } from '@kit.AbilityKit';
import { JSON } from '@kit.ArkTS';
import screen from '@ohos.screen';
import screenshot from '@ohos.screenshot';
import image from '@ohos.multimedia.image';
import common from '@ohos.app.ability.common';
import { DisplayId } from '@ohos/common/src/main/ets/util/DisplayUtil';
import missionManager from '@ohos.app.ability.missionManager';
import bundleResourceManager from '@ohos.bundle.bundleResourceManager';
import commonEvent from '@ohos.commonEventManager';
import display from '@ohos.display';
import I18n from '@ohos.i18n';
import media from '@ohos.multimedia.media';
import window from '@ohos.window';

import { CommonEventUtil, CommonUtil, GlobalThisUtil, LogUtil } from '@ohos/common';
import {
  IMAGE_MARGIN,
  MARGIN_LAND,
  MARGIN_VERTICAL,
  TEXT_FONT_SIZE,
  TEXT_PADDING,
  TITLE_FONT_SIZE,
} from './types';
import { ExpansionScreenUtil } from '../../util/ExpansionScreenUtil';
import { CommonSelectPicker } from './CommonSelectPicker';

/* instrument ignore file */
const TAG: string = 'SelectWindowPage';
const MAX_WINDOW_NUM: number = 999;
const ZERO_SIZE: number = 0;
const VIRTUAL_SCREEN: number = 1000;
const BC_DISPLAY_ID: number = -999999999;
const B_DISPLAY_ID: number = 0;
const C_DISPLAY_ID: number = 999;
const BC_DISPLAY_ID_STRING: string = '0,999';
const BC_DISPLAY_ID_ARRAY: number[] = [B_DISPLAY_ID, C_DISPLAY_ID];
const HOPPER_SCREEN_COLUMNS_FOUR: number = 4;
const HOPPER_SCREEN_COLUMNS_SIX: number = 6;
const DEBOUNCE_LIMIT_TIME: number = 300;
const UN_LOCK_SLEEP_TIME: number = 250;
const DISPLAY_LISTENER_SLEEP_TIME: number = 380;
const ROTATION_LISTENER_SLEEP_TIME: number = 800;
const SELECT_BACKUP_SLEEP_TIME: number = 200;
const SELECT_SHARE_SLEEP_TIME: number = 300;
const CONNECT_TIME: number = 1000;
const SCREEN_SPACE_WIDTH: number = 96;
const FULL_SCREEN_SPACE_WIDTH: number = 128;
const SCREEN_SPACE_LIMIT: number = 6;
const WINDOW_SPACE_WIDTH: number = 34;
const WINDOW_SPACE_LIMIT: number = 4;
const PC_WIDTH_HEIGHT_RATIO: number = 0.75;
const BUTTON_CLICK_TIME: number = 230;
const LANGUAGE_TIME: number = 2000;

@Observed
class ScreenImageData {
  public screenShot: image.PixelMap | null = null;
  public displayId: number | null = null;
}

@Component
export struct PickerSelectWindowPage {
  @State windowWidth: number | undefined = undefined;
  @State windowHeight: number | undefined = undefined;
  @State moduleWidth: number | undefined = undefined;
  @State moduleHeight: number | undefined = undefined;
  @State moduleWindowWidth: number | undefined = undefined;
  @State moduleWindowHeight: number | undefined = undefined;
  @State windowPictureWidth: number | undefined = undefined;
  @State windowPictureHeight: number | undefined = undefined;
  @State screenImageList: ScreenImageData[] = [];
  @State screenImagePixel: image.PixelMap[] = [];
  @State fullScreenPixelMap: image.PixelMap | undefined = undefined;
  @State fullBgScreenPixelMap: image.PixelMap | undefined = undefined;
  @State imageList: CommonSelectPicker.WindowImageData[] = [];
  @State checkedDisplayId: number | null = null;
  @State checkedMissionId: number | null = null;
  @State appLabel: string = '';
  @State rectWidth: number | undefined = 0;
  @State windowDecorHeight: number = 56;
  @State blurEffect: boolean = false;
  @State screenColumns: number = 6;
  @State isOneDisplayHalfFolderState: boolean = false; // 磁吸键盘态
  @State isUpdatePending: boolean = false; // 是否在开启显示设备变化的监听
  @State isHalfFoldedState: boolean = false; // 悬停态
  @State isPortraitScreen: boolean = false; // 竖向展开态
  @State isLandscapeScreen: boolean = false; // 横向展开态
  @State imageWindowData: CommonSelectPicker.WindowImageDataSource = new CommonSelectPicker.WindowImageDataSource([]);
  @State canStartScreenCapture: boolean = false;
  @StorageProp('currentLanguageCode') @Watch('handleLanguageCode') currentLanguageCode: string | undefined = undefined;
  @StorageProp('isColorModeDark') @Watch('handleUpdateBackground') isDarkMode: boolean = false;
  private displayRatio: number | undefined = undefined;
  private appBundleName: string = 'com.ohos.screenrecorder';
  private currentDisplayId: number | undefined = undefined;
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private selectWant = this.globalThisInstance?.getObject('selectWant') as Want;
  private selectContext = this.globalThisInstance?.getObject('selectContext') as common.UIAbilityContext;
  private windowClass: window.Window | undefined = undefined;
  private screenRefresh: boolean = false;
  private screenUnlockEvent: CommonEventUtil =
    new CommonEventUtil([commonEvent.Support.COMMON_EVENT_SCREEN_UNLOCKED], this.updateWindowDataWhenUnlock.bind(this));
  private showSensitiveCheckBox: boolean = false;
  private checkBoxSelected: boolean = false;
  private isInnerAudioBoxSelected: boolean = false;
  private showShareSystemAudioBox: boolean = false;
  private deviceRotation: number = 0;
  private displayChangeCallback: Callback<number> | undefined = undefined;
  private foldStatusChangeCallback: Callback<number> | undefined = undefined;
  private displayAddListenerCallback: Callback<number> | undefined = undefined;
  private displayRemoveListenerCallback: Callback<number> | undefined = undefined;
  private screenConnectCallback: Callback<number> | undefined = undefined;
  private screenDisConnectCallback: Callback<number> | undefined = undefined;
  private windowSizeChangeCallback: Callback<window.Size> | undefined = undefined;
  private windowTitleButtonRectChangeCallback: Callback<window.TitleButtonRect> | undefined = undefined;
  private excludedWindowIDs: number[] = [];
  private pickerMode: number | undefined = undefined;
  private allDisplays: display.Display[] = []; // 获取当前所有的Display对象
  private scroller: Scroller = new Scroller();
  private debounceCacheId: number | null = null; // 防抖timeoutID
  private listenerId: number = -1;
  private screenImageMap: Map<number, number> = new Map();
  private missionImageMap: Map<number, number> = new Map();
  private isFoldable: boolean = false;
  private displayPhysicalResolution: display.DisplayPhysicalResolution[] = [];
  private languageTimerId: number | null = null;

  async aboutToAppear(): Promise<void> {
    try {
      LogUtil.info(TAG, 'aboutToAppear');
      this.excludedWindowIDs = this.parseNumberString(this.selectWant.parameters?.excludedWindowIDs);
      this.pickerMode = this.selectWant.parameters?.pickerMode as number;
      this.isFoldable = display.isFoldable();
      this.getAppName();
      this.getIsShowSensitiveCheckBox();
      this.getIsCheckBoxSelected();
      this.getIsShowShareSystemAudioBox();
      this.displayPhysicalResolution = await display.getAllDisplayPhysicalResolution();
      await this.handleFoldedState();
      await this.handleWindowStageInfo();
      await this.getFullScreenShot();
      await this.getCurrentAllScreenShot();
      await this.getCurrentAllMissionsShot();
      this.getMissionIdOrDisplayId();
      this.globalThisInstance?.setObject('windowLoadFirst', false);
      this.handleScreenEvent();
      this.registerMissionListener();
      LogUtil.info(TAG, `checkedDisplayId: ${this.checkedDisplayId}, checkedMissionId: ${this.checkedMissionId}`);
    } catch (err) {
      LogUtil.error(TAG, `Failed to aboutToAppear. Cause: ${err.message}`);
    }
  }

  aboutToDisappear(): void {
    try {
      LogUtil.info(TAG, 'aboutToDisappear');
      this.handleReleaseImagePixel();
      this.screenImageMap.clear();
      this.missionImageMap.clear();
      this.imageList = [];
      this.checkedMissionId = null;
      this.checkedDisplayId = null;
      if (this.debounceCacheId !== null) {
        clearTimeout(this.debounceCacheId);
        this.debounceCacheId = null;
      }
      if (this.languageTimerId !== null) {
        clearTimeout(this.languageTimerId);
        this.languageTimerId = null;
      }
      this.handleCancelListeningCallback();
      this.unRegisterMissionListener();
    } catch (err) {
      LogUtil.error(TAG, `Failed to aboutToDisappear. Cause: ${err.message}`);
    }
  }

  onPageShow(): void {
    try {
      LogUtil.info(TAG, 'onPageShow');
      if (this.windowTitleButtonRectChangeCallback) {
        this.windowClass?.off('windowTitleButtonRectChange', this.windowTitleButtonRectChangeCallback);
      }
      this.windowTitleButtonRectChangeCallback = (rect: window.TitleButtonRect) => {
        LogUtil.info(TAG, `change rect: ${rect.width}`);
        if (rect.width !== this.rectWidth) {
          this.rectWidth = rect.width;
        }
      }
      this.windowClass?.on('windowTitleButtonRectChange', this.windowTitleButtonRectChangeCallback);
    } catch (err) {
      LogUtil.error(TAG, `Failed to onPageShow. Cause: ${err.message}`);
    }
  }

  onPageHide(): void {
    LogUtil.info(TAG, 'onPageHide');
  }

  private handleCancelListeningCallback(): void {
    try {
      LogUtil.info(TAG, 'handleCancelListeningCallback');
      if (this.windowTitleButtonRectChangeCallback) {
        this.windowClass?.off('windowTitleButtonRectChange', this.windowTitleButtonRectChangeCallback);
      }
      if (this.windowSizeChangeCallback) {
        this.windowClass?.off('windowSizeChange', this.windowSizeChangeCallback);
      }
      if (this.foldStatusChangeCallback) {
        display.off('foldStatusChange', this.foldStatusChangeCallback);
      }
      if (this.displayChangeCallback) {
        display.off('change', this.displayChangeCallback);
      }
      if (this.displayAddListenerCallback) {
        display.off('add', this.displayAddListenerCallback);
      }
      if (this.displayRemoveListenerCallback) {
        display.off('remove', this.displayRemoveListenerCallback);
      }
      if (this.screenConnectCallback) {
        screen.off('connect', this.screenConnectCallback);
      }
      if (this.screenDisConnectCallback) {
        screen.off('disconnect', this.screenDisConnectCallback);
      }
      this.windowTitleButtonRectChangeCallback = undefined;
      this.windowSizeChangeCallback = undefined;
      this.foldStatusChangeCallback = undefined;
      this.displayChangeCallback = undefined;
      this.displayAddListenerCallback = undefined;
      this.displayRemoveListenerCallback = undefined;
      this.screenConnectCallback = undefined;
      this.screenDisConnectCallback = undefined;
    } catch (error) {
      LogUtil.error(TAG, `Failed to handleCancelListeningCallback, error: ${error.message}`);
    }
  }

  private async handleWindowStageInfo(): Promise<void> {
    try {
      this.windowClass = this.globalThisInstance?.getObject('windowClass') as window.Window;
      if (this.windowClass === undefined) {
        LogUtil.info(TAG, 'windowClass is undefined');
        let windowStage: window.WindowStage =
          this.globalThisInstance?.getObject('selectWindowStage') as window.WindowStage;
        if (windowStage !== undefined) {
          LogUtil.info(TAG, 'get windowStage again in aboutToAppear');
          this.windowClass = await windowStage.getMainWindow();
        }
      }
      if (this.windowClass === undefined) {
        LogUtil.error(TAG, 'windowClass is undefined, need return.');
        return;
      }
      let windowProperties: window.WindowProperties = this.windowClass.getWindowProperties();
      if (!windowProperties) {
        LogUtil.error(TAG, 'Failed to get windowProperties.');
        return;
      }
      this.windowWidth = this.handlePx2vp(windowProperties.windowRect.width);
      this.windowHeight = this.handlePx2vp(windowProperties.windowRect.height);
      this.updatePictureSize(this.windowWidth, this.windowHeight);
      this.windowSizeChangeCallback = (newSize: window.Size) => {
        this.windowWidth = this.handlePx2vp(newSize.width);
        this.windowHeight = this.handlePx2vp(newSize.height);
        this.updatePictureSize(this.windowWidth, this.windowHeight);
      }
      this.windowClass.on('windowSizeChange', this.windowSizeChangeCallback);
      this.deviceRotation = display.getDefaultDisplaySync().rotation;
      this.screenUnlockEvent.subscribe();
      this.setFoldListener();
      this.setRotationListener();
    } catch (err) {
      LogUtil.error(TAG, `Failed in aboutToAppear. reason: ${err.message}`);
      this.handleTerminateSelf();
    }
  }

  private handlePx2vp(size: number): number {
    try {
      return this.getUIContext().px2vp(size);
    } catch (err) {
      LogUtil.error(TAG, `Failed to handlePx2vp. Cause: ${err.message}`);
    }
    return size;
  }

  private handleReleaseImagePixel(): void {
    try {
      LogUtil.info(TAG, 'handleReleaseImagePixel');
      this.screenImageList.forEach((item: ScreenImageData) => {
        try {
          if (item.screenShot !== null) {
            item.screenShot.release();
            item.screenShot = null;
          }
        } catch (err) {
          LogUtil.error(TAG, `Failed to release missionImageMap missionShot: ${err?.message}`);
        }
      })
      this.screenImagePixel.forEach((item: image.PixelMap) => {
        try {
          if (item !== null) {
            item.release();
          }
        } catch (err) {
          LogUtil.error(TAG, `Failed to release missionImageMap missionShot: ${err?.message}`);
        }
      })
      this.fullScreenPixelMap?.release();
      this.imageWindowData.clear();
      this.screenImageList = [];
      this.screenImagePixel = [];
      this.fullScreenPixelMap = undefined;
    } catch (err) {
      LogUtil.error(TAG, `Failed to handleReleaseImagePixel. Cause: ${err.message}`);
    }
  }

  private async handleTerminateSelf(): Promise<void> {
    try {
      if (this.selectContext) {
        LogUtil.info(TAG, 'handleTerminateSelf start');
        await this.selectContext.terminateSelf();
      }
    } catch (err) {
      LogUtil.error(TAG, `Failed in handleTerminateSelf. reason: ${err.message}`);
    }
  }

  private handleScreenEvent(): void {
    try {
      let timerId: number | null = null;
      this.screenConnectCallback = (data: number) => {
        LogUtil.info(TAG, `Listen to the new display and refresh the page data: ${data}`);
        if (data >= VIRTUAL_SCREEN) {
          LogUtil.info(TAG, 'The current screen is a virtual screen, not need to be displayed.');
          return;
        }
        if (timerId) {
          clearTimeout(timerId);
        }
        timerId = setTimeout(() => {
          LogUtil.info(TAG, 'screen connect, start refresh');
          this.screenRefresh = true;
          this.updateWindowData();
        }, CONNECT_TIME);
      };
      this.screenDisConnectCallback = (data: number) => {
        LogUtil.info(TAG, `Listen to the new display and refresh the page data: ${data}`);
        if (data >= VIRTUAL_SCREEN) {
          LogUtil.info(TAG, 'The current screen is a virtual screen, not need to be displayed.');
          return;
        }
        this.screenRefresh = true;
        this.updateWindowData();
      };
      screen.on('connect', this.screenConnectCallback);
      screen.on('disconnect', this.screenDisConnectCallback);
    } catch (err) {
      LogUtil.error(TAG, `Failed in handleScreenEvent, error: ${err.message}`);
    }
  }

  async handleAvailableHeight(bool: boolean): Promise<void> {
    try {
      if (!(CommonUtil.checkIfDeviceIsPC() && this.isFoldable)) {
        this.isOneDisplayHalfFolderState = false;
        return;
      }
      LogUtil.info(TAG, 'handleAvailableHeight start');
      this.screenRefresh = true;
      await this.sleep(DISPLAY_LISTENER_SLEEP_TIME);
      this.isOneDisplayHalfFolderState = bool;
      if (this.isOneDisplayHalfFolderState && this.checkedMissionId === null) {
        this.checkedDisplayId = B_DISPLAY_ID;
        this.checkedMissionId = null;
      } else {
        this.getMissionIdOrDisplayId();
      }
      await this.updateWindowData();
    } catch (error) {
      LogUtil.error(TAG, `handleAvailableHeight error, reason: ${error.message}`);
      this.isOneDisplayHalfFolderState = false;
    }
  }

  handleUpdateMission(): void {
    LogUtil.info(TAG, 'handleUpdateMission start');
    this.debounce(() => {
      this.updateWindowData();
    }, DEBOUNCE_LIMIT_TIME);
  }

  handleLanguageCode(): void {
    LogUtil.info(TAG, 'handleLanguageCode start');
    if (this.languageTimerId !== null) {
      clearTimeout(this.languageTimerId);
    }
    this.languageTimerId = setTimeout(() => {
      this.updateWindowData();
    }, LANGUAGE_TIME);
  }

  handleUpdateBackground(): void {
    LogUtil.info(TAG, 'handleUpdateBackground start');
    this.debounce(() => {
      this.updateWindowData();
    }, DEBOUNCE_LIMIT_TIME);
  }

  async updateWindowData(): Promise<void> {
    try {
      let windowLoadFirst: boolean = this.globalThisInstance?.getObject('windowLoadFirst') as boolean;
      if (!this.screenRefresh && windowLoadFirst) {
        LogUtil.info(TAG, 'The current state has screenRefresh, need to updateWindowData again.');
        return;
      }
      LogUtil.info(TAG, 'updateWindowData start');
      this.handleReleaseImagePixel();
      this.screenImageMap.clear();
      this.missionImageMap.clear();
      this.imageList = [];
      this.blurEffect = false;
      await this.handleFoldedState();
      await this.getFullScreenShot();
      await this.getCurrentAllScreenShot();
      await this.getCurrentAllMissionsShot();
      this.getMissionIdOrDisplayId();
      this.screenRefresh = false;
      LogUtil.info(TAG, 'updateWindowData end');
      LogUtil.info(TAG,
        `updateWindowData checkedDisplayId: ${this.checkedDisplayId}, checkedMissionId: ${this.checkedMissionId}`);
    } catch (error) {
      LogUtil.error(TAG, `updateWindowData error, reason: ${error.message}`);
    }
  }

  async updateWindowDataWhenUnlock(): Promise<void> {
    try {
      this.screenRefresh = true;
      await this.sleep(UN_LOCK_SLEEP_TIME);
      this.updateWindowData();
    } catch (error) {
      LogUtil.error(TAG, `updateWindowDataWhenUnlock error, reason: ${error.message}`);
    }
  }

  setFoldListener(): void {
    try {
      if (!display.isFoldable()) {
        LogUtil.info(TAG, 'device not foldable, return');
        return;
      }
      this.foldStatusChangeCallback = async () => {
        LogUtil.info(TAG, 'foldStatusChangeCallback start');
        this.debounce(() => {
          this.updateWindowData();
        }, DEBOUNCE_LIMIT_TIME);
      };
      display.on('foldStatusChange', this.foldStatusChangeCallback);

      this.displayAddListenerCallback = (data: number) => {
        LogUtil.info(TAG, `displayAddListenerCallback start, data: ${data}`);
        if (data !== C_DISPLAY_ID || !this.isHalfFoldedState) {
          return;
        }
        this.debounce(() => {
          this.handleAvailableHeight(false);
        }, DEBOUNCE_LIMIT_TIME);
      };
      this.displayRemoveListenerCallback = (data: number) => {
        LogUtil.info(TAG, `displayRemoveListenerCallback start, data: ${data}`);
        if (data !== C_DISPLAY_ID || !this.isHalfFoldedState) {
          return;
        }
        this.debounce(() => {
          this.handleAvailableHeight(true);
        }, DEBOUNCE_LIMIT_TIME);
      };
      display.on('add', this.displayAddListenerCallback);
      display.on('remove', this.displayRemoveListenerCallback);
    } catch (error) {
      LogUtil.error(TAG, `setFoldListener error: ${error.message}`);
    }
  }

  setRotationListener(): void {
    try {
      this.displayChangeCallback = async () => {
        let newRotation = display.getDefaultDisplaySync().rotation;
        if (newRotation !== this.deviceRotation) {
          LogUtil.info(TAG, `displayChangeCallback newRotation: ${newRotation}`);
          this.screenRefresh = true;
          this.deviceRotation = newRotation;
          await this.sleep(ROTATION_LISTENER_SLEEP_TIME);
          this.updateRotationPictureSize();
          this.updateWindowData();
        }
      };
      display.on('change', this.displayChangeCallback);
    } catch (error) {
      LogUtil.error(TAG, `setRotationListener error: ${error.message}`);
    }
  }

  updateRotationPictureSize(): void {
    try {
      LogUtil.info(TAG, 'updateRotationPictureSize start');
      let windowProperties: window.WindowProperties | undefined = this.windowClass?.getWindowProperties();
      if (!windowProperties) {
        LogUtil.error(TAG, 'updateRotationPictureSize failed to get windowProperties.');
        return;
      }
      this.windowWidth = this.handlePx2vp(windowProperties.windowRect.width);
      this.windowHeight = this.handlePx2vp(windowProperties.windowRect.height);
      this.updatePictureSize(this.windowWidth, this.windowHeight);
    } catch (err) {
      LogUtil.error(TAG, `Failed to updateRotationPictureSize. reason: ${err.message}`);
    }
  }

  updatePictureSize(width: number, height: number): void {
    this.judgeHorizontalsOrVerticals();
    if (height === ZERO_SIZE || width === ZERO_SIZE) {
      this.displayRatio = 1;
      LogUtil.info(TAG, `zero height ratio: ${this.displayRatio}`);
    } else {
      // 计算窗口宽高比
      this.displayRatio = width / height;
      LogUtil.info(TAG, `winWidth: ${this.windowWidth}, winHeight: ${this.windowHeight}, ratio: ${this.displayRatio}`);
    }
    // 计算每个屏幕模块的宽、高
    if (this.isLandscapeScreen || !CommonUtil.checkIfDeviceIsPC() || !this.isFoldable) {
      this.moduleWidth = (width - SCREEN_SPACE_WIDTH) / WINDOW_SPACE_LIMIT;
      this.moduleHeight = this.moduleWidth / this.displayRatio;
    } else {
      this.moduleWidth = (width - FULL_SCREEN_SPACE_WIDTH) / SCREEN_SPACE_LIMIT;
      let physicalWidth: number | undefined = this.displayPhysicalResolution[0]?.physicalWidth;
      let physicalHeight: number | undefined = this.displayPhysicalResolution[0]?.physicalHeight;
      let fullDisplayRatio = PC_WIDTH_HEIGHT_RATIO;
      LogUtil.info(TAG, `physicalWidth: ${physicalWidth}, physicalHeight: ${physicalHeight}`);
      if (!Number.isNaN(Number(physicalWidth)) && !Number.isNaN(Number(physicalHeight)) && physicalHeight !== 0) {
        fullDisplayRatio = physicalWidth / physicalHeight;
      }
      this.moduleHeight = this.moduleWidth / fullDisplayRatio;
    }

    // 计算窗口图片的宽、高
    this.moduleWindowWidth = (width - SCREEN_SPACE_WIDTH) / WINDOW_SPACE_LIMIT;
    this.moduleWindowHeight = this.moduleWindowWidth / this.displayRatio;
    LogUtil.info(TAG, `screenWidth: ${this.moduleWidth}, screenHeight: ${this.moduleHeight}, moduleWindowWidth: ` +
      `${this.moduleWindowWidth}, moduleWindowHeight: ${this.moduleWindowHeight}`);

    this.windowPictureWidth = this.moduleWindowWidth - WINDOW_SPACE_WIDTH * 2;
    this.windowPictureHeight = this.windowPictureWidth / this.displayRatio;
    LogUtil.info(TAG, `windowPic width: ${this.windowPictureWidth}, height: ${this.windowPictureHeight}`);
  }

  async getCurrentAllScreenShot(): Promise<void> {
    try {
      if (this.allDisplays.length === 0) {
        LogUtil.error(TAG, 'allDisplays is null.');
        return;
      }
      if (this.allDisplays.length === 1 && this.checkedMissionId === null) {
        this.checkedDisplayId = 0;
        this.checkedMissionId = null;
        LogUtil.info(TAG, 'Only one screen, and select by default.');
      }
      for (let i = 0; i < this.allDisplays.length; i++) {
        let currentDisplayId: number = this.allDisplays[i].id;
        if (currentDisplayId === undefined) {
          continue;
        }
        LogUtil.info(TAG, `currentDisplay in: ${currentDisplayId}`);
        this.currentDisplayId = currentDisplayId
        if (this.currentDisplayId >= VIRTUAL_SCREEN) {
          LogUtil.info(TAG, 'The current screen is a virtual screen, not need to be displayed.');
          continue;
        }
        await this.getScreenShot(this.currentDisplayId);
      }
      this.getAllScreenImageList();
      this.globalThisInstance?.setObject('screenUpdate', false);
      LogUtil.info(TAG, `screenImageList length: ${this.screenImageList.length}`);
    } catch (err) {
      LogUtil.error(TAG, `Failed to get current all ScreenShot. error: ${err.message}`);
    }
  }

  async getScreenShot(displayId: number): Promise<void> {
    let screenshotOptions: screenshot.ScreenshotOptions = {
      'rotation': 0,
      'displayId': displayId,
    };
    try {
      let screenPixelMap: image.PixelMap = await screenshot.save(screenshotOptions);
      if (!this.screenImageMap.has(displayId)) {
        let screenImageObj: ScreenImageData = {
          screenShot: screenPixelMap,
          displayId: displayId,
        };
        this.screenImageMap.set(displayId, displayId);
        this.screenImageList.push(screenImageObj);
        this.screenImagePixel.push(screenPixelMap);
      }
    } catch (err) {
      LogUtil.error(TAG, `Failed to save screenshot. error: ${err.message}`);
    }
  }

  async getCurrentAllMissionsShot(): Promise<void> {
    try {
      let missionArray: missionManager.MissionInfo[] = await missionManager.getMissionInfos('', MAX_WINDOW_NUM);
      if (missionArray && missionArray.length > 0) {
        for (let i = 0; i < missionArray.length; i++) {
          let element = missionArray[i].missionId;
          await this.getMissionInfo(element);
        }
        LogUtil.info(TAG, `missionImageList length: ${this.imageWindowData.totalCount()}`);
      }
    } catch (err) {
      LogUtil.error(TAG, `getCurrentAllMissionsShot error: ${err.code}, ${err.message}`);
    }
  }

  async getMissionInfo(testMissionId: number): Promise<void> {
    try {
      let isExcluded: boolean = this.excludedWindowIDs?.includes(testMissionId) ?? false;
      if (isExcluded) {
        LogUtil.info(TAG, `mission: ${testMissionId}, isExcluded: ${isExcluded}`);
        return;
      }
      let missionInfo: missionManager.MissionInfo = await missionManager.getMissionInfo('', testMissionId);
      let missionArray: number[] = [];
      missionArray.push(testMissionId);
      let missionShot: missionManager.MissionSnapshot =
        await missionManager.getMissionSnapShot('', missionInfo.missionId);
      let missionShotImage: image.PixelMap = missionShot.snapshot as image.PixelMap;
      let bundleName: string = missionShot.ability.bundleName;
      this.getMissionsLabel(missionInfo.missionId, bundleName, missionShotImage);
    } catch (err) {
      LogUtil.error(TAG, `getMissionInfo failed : ${err.message}`);
    }
  }

  getMissionsLabel(missionId: number, bundleName: string, missionShotImage: image.PixelMap): void {
    try {
      let bundleFlags: bundleResourceManager.ResourceFlag = bundleResourceManager.ResourceFlag.GET_RESOURCE_INFO_ALL;
      if (bundleName === this.appBundleName) {
        LogUtil.info(TAG, 'bundleName is screenRecorder need return');
        return;
      }
      if (bundleName === '' || bundleName === undefined) {
        return;
      }
      let resourceInfo: bundleResourceManager.BundleResourceInfo =
        bundleResourceManager.getBundleResourceInfo(bundleName.toString(), bundleFlags);
      let missionLabel: string = resourceInfo.label;
      if (!this.missionImageMap.has(missionId)) {
        let missionImageData: CommonSelectPicker.WindowImageData = {
          missionShot: missionShotImage,
          missionId: missionId,
          missionLabel: missionLabel,
        }
        this.missionImageMap.set(missionId, missionId);
        this.imageWindowData.pushData(missionImageData);
      }
    } catch (err) {
      LogUtil.error(TAG, `getMissionsLabel failed : ${err.message}`);
    }
  }

  getAppName(): void {
    try {
      if (this.selectWant.parameters?.appLabel !== undefined) {
        this.appLabel = (this.selectWant.parameters?.appLabel).toString();
        LogUtil.info(TAG, `appLabel: ${this.appLabel}`);
      }
    } catch (err) {
      LogUtil.error(TAG, `getAppName error: ${err.message}`);
    }
  }

  getIsShowSensitiveCheckBox(): void {
    try {
      LogUtil.info(TAG, `selectWant showSensitiveCheckBox: ${this.selectWant.parameters?.showSensitiveCheckBox}`);
      if (this.selectWant.parameters?.showSensitiveCheckBox !== undefined) {
        this.showSensitiveCheckBox = (this.selectWant.parameters?.showSensitiveCheckBox) as boolean;
        LogUtil.info(TAG, `showSensitiveCheckBox: ${this.showSensitiveCheckBox}`);
      }
    } catch (err) {
      LogUtil.error(TAG, `getIsShowSensitiveCheckBox error: ${err.message}`);
    }
  }

  getIsCheckBoxSelected(): void {
    try {
      if (this.selectWant.parameters?.checkBoxSelected !== undefined) {
        this.checkBoxSelected = (this.selectWant.parameters?.checkBoxSelected) as boolean;
        LogUtil.info(TAG, `checkBoxSelected: ${this.checkBoxSelected}`);
      }
    } catch (err) {
      LogUtil.error(TAG, `getIsCheckBoxSelected error: ${err.message}`);
    }
  }

  getIsShowShareSystemAudioBox(): void {
    try {
      if (this.selectWant.parameters?.showShareSystemAudioBox !== undefined) {
        this.showShareSystemAudioBox = (this.selectWant.parameters?.showShareSystemAudioBox) as boolean;
        this.isInnerAudioBoxSelected = this.showShareSystemAudioBox;
        LogUtil.info(TAG, `showShareSystemAudioBox: ${this.showShareSystemAudioBox}`);
        LogUtil.info(TAG, `isInnerAudioBoxSelected: ${this.isInnerAudioBoxSelected}`);
      }
    } catch (err) {
      LogUtil.error(TAG, `getIsShowShareSystemAudioBox error: ${err.message}`);
    }
  }

  getMissionIdOrDisplayId(): void {
    try {
      let wantDisplayId: number | string | undefined = this.selectWant.parameters?.displayId as number | string;
      let wantMissionId: number | undefined = this.selectWant.parameters?.missionId as number;
      LogUtil.info(TAG, `getMissionIdOrDisplayId wantDisplay: ${wantDisplayId}, wantMission: ${wantMissionId}, ` +
        `checkedDisplay: ${this.checkedDisplayId}, checkedMission: ${this.checkedMissionId}`);
      if (wantDisplayId === BC_DISPLAY_ID_STRING) {
        wantDisplayId = BC_DISPLAY_ID;
      }
      if (this.checkedDisplayId !== null && this.checkedMissionId === null) {
        LogUtil.info(TAG, 'checkedDisplay is not null, keeping selection');
        this.canStartScreenCapture = true;
        return;
      }
      if (this.checkedDisplayId === null && this.checkedMissionId !== null &&
        this.missionImageMap.has(this.checkedMissionId)) {
        LogUtil.info(TAG, 'checkedMission is not null, keeping selection');
        this.canStartScreenCapture = true;
        return;
      }
      if (this.missionImageMap.size > 0 && (this.pickerMode === CommonSelectPicker.PickerMode.WINDOW_ONLY ||
        ((this.pickerMode === undefined || this.pickerMode === CommonSelectPicker.PickerMode.SCREEN_AND_WINDOW) &&
          wantMissionId !== undefined && wantMissionId >= 0))) {
        this.checkedDisplayId = null;
        this.checkedMissionId = this.missionImageMap.has(wantMissionId) ? wantMissionId :
          this.imageWindowData.getData(0).missionId;
        this.canStartScreenCapture = true;
        LogUtil.info(TAG, `select window: ${this.checkedMissionId}`);
      } else if (this.missionImageMap.size === 0 && this.pickerMode === CommonSelectPicker.PickerMode.WINDOW_ONLY) {
        this.checkedDisplayId = null;
        this.checkedMissionId = null;
        this.canStartScreenCapture = false;
        LogUtil.info(TAG, 'show window and window list is empty');
      } else {
        let currentDisplayId: number = Number(wantDisplayId);
        let checkedDisplayId: number = this.screenImageList.some(
          (item: ScreenImageData) => item.displayId == currentDisplayId) ? currentDisplayId : B_DISPLAY_ID;
        if (this.checkedDisplayId !== null) {
          LogUtil.info(TAG, 'checkedDisplay is not null, keeping selection');
        } else {
          this.checkedDisplayId = checkedDisplayId;
          this.checkedMissionId = null;
        }
        this.canStartScreenCapture = true;
        LogUtil.info(TAG, `select screen: ${this.checkedDisplayId}`);
      }
    } catch (err) {
      LogUtil.error(TAG, `getMissionIdOrDisplayId error: ${err.message}`);
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
      LogUtil.error(TAG, `debounce error: ${err.message}`);
    }
  }

  private parseNumberString(input: Object | undefined): number[] {
    if (input === undefined) {
      return [];
    }
    if (typeof input === 'string') {
      const str: string = input.trim();
      if (!str) {
        return [];
      }
      return str.split(',').map(item => Number(item.trim())).filter(num => !isNaN(num));
    }
    return [];
  }

  private isRTL(): boolean {
    try {
      const systemLocale: string = I18n.System.getSystemLocale();
      return I18n.isRTL(systemLocale);
    } catch (err) {
      LogUtil.error(TAG, `getSystemLocale failed, message: ${err.message}.`);
      return false;
    }
  }

  private async handleFoldedState(): Promise<void> {
    try {
      this.judgeHorizontalsOrVerticals();
      let status: display.FoldStatus = display.getFoldStatus();
      this.allDisplays = await display.getAllDisplays();
      this.isOneDisplayHalfFolderState = this.judgeIsOneDisplayHalfFolderState(this.allDisplays);
      if (status === FoldStatus.FOLD_STATUS_EXPANDED) {
        // 表示设备当前折叠状态为完全展开
        this.isHalfFoldedState = false;
        this.isOneDisplayHalfFolderState = false;
      } else if (status === FoldStatus.FOLD_STATUS_HALF_FOLDED) {
        // 表示设备当前折叠状态为半折叠。半折叠指完全展开和折叠之间的状态
        this.isHalfFoldedState = true;
        this.isPortraitScreen = false;
        this.isLandscapeScreen = false;
      } else if (status === FoldStatus.FOLD_STATUS_FOLDED) {
        // 表示设备当前折叠状态为折叠
        this.isHalfFoldedState = false;
        this.isOneDisplayHalfFolderState = false;
        this.isPortraitScreen = false;
        this.isLandscapeScreen = false;
      } else {
        LogUtil.debug(TAG, 'handleFoldedState nothing');
      }

      this.screenColumns = this.isLandscapeScreen || !CommonUtil.checkIfDeviceIsPC() || !this.isFoldable ?
        HOPPER_SCREEN_COLUMNS_FOUR : HOPPER_SCREEN_COLUMNS_SIX;
      LogUtil.info(TAG, `handleFoldedState isOneDisplayHalfFolderState: ${this.isOneDisplayHalfFolderState} ` +
        `isHalfFoldedState: ${this.isHalfFoldedState} isPortraitScreen: ${this.isPortraitScreen} ` +
        `isLandscapeScreen: ${this.isLandscapeScreen} status: ${status}`);
    } catch (err) {
      LogUtil.error(TAG, `handleFoldedState failed, message: ${err.message}.`);
    }
  }

  private async getFullScreenShot(): Promise<void> {
    LogUtil.info(TAG, `getFullScreenShot isOneDisplayHalfFolderState: ${this.isOneDisplayHalfFolderState} ` +
      `isPortraitScreen: ${this.isPortraitScreen}, isLandscapeScreen: ${this.isLandscapeScreen}`);
    if (this.isOneDisplayHalfFolderState || this.isLandscapeScreen || this.isPortraitScreen) {
      return;
    }
    let screenshotOptions: screenshot.ScreenshotOptions = {
      'rotation': 0,
      'isCaptureFullOfScreen': true,
    };
    try {
      let newFullScreenPixelMap: image.PixelMap = await screenshot.save(screenshotOptions);
      if (this.fullScreenPixelMap) {
        this.fullScreenPixelMap.release();
      }
      this.fullScreenPixelMap = newFullScreenPixelMap;
    } catch (err) {
      LogUtil.error(TAG, `Failed to getFullScreenShot, err: ${err.message}`);
    }
  }

  private getAllScreenImageList(): void {
    try {
      if (!this.fullScreenPixelMap) {
        LogUtil.error(TAG, 'fullScreenPixelMap is undefined.');
        return;
      }
      let screenImageObj: ScreenImageData = {
        screenShot: this.fullScreenPixelMap,
        displayId: BC_DISPLAY_ID,
      }
      const indexForBDisplayId: number = this.screenImageList.findIndex(item => item.displayId === B_DISPLAY_ID);
      const indexForCDisplayId: number = this.screenImageList.findIndex(item => item.displayId === C_DISPLAY_ID);
      LogUtil.info(TAG, `indexForBDisplayId: ${indexForBDisplayId}, indexForCDisplayId: ${indexForCDisplayId}`);
      let insertIndex: number = 0;
      if (indexForBDisplayId !== -1 && indexForCDisplayId !== -1) {
        insertIndex = indexForCDisplayId + 1;
      } else if (indexForBDisplayId !== -1) {
        insertIndex = indexForBDisplayId + 1;
      } else {
        insertIndex = 0;
      }
      if (insertIndex === 0) {
        return;
      }
      let isExistence: boolean = this.screenImageList.some((item: ScreenImageData) => item.displayId == BC_DISPLAY_ID);
      LogUtil.info(TAG, `getAllScreenImageList insertIndex: ${insertIndex}, isExistence: ${isExistence}`);
      if (!isExistence) {
        this.screenImageList.splice(insertIndex, 0, screenImageObj);
        this.screenImagePixel.splice(insertIndex, 0, this.fullScreenPixelMap);
      }
    } catch (err) {
      LogUtil.error(TAG, `Failed to getAllScreenImageList, err: ${err.message}`);
    }
  }

  private judgeIsOneDisplayHalfFolderState(displays: display.Display[]): boolean {
    if (!displays || displays.length == 0) {
      LogUtil.error(TAG, `isOneDisplayHalfFolderState, displays is invalid.`);
      return false;
    }
    if (!ExpansionScreenUtil.isHalfFoldedState()) {
      return false;
    }
    for (let display of displays) {
      if (display?.id === DisplayId.LOWER_OF_FOLD_DEVICE) {
        return false;
      }
    }
    return true;
  }

  private judgeHorizontalsOrVerticals(): void {
    try {
      let displayInfo = display.getDefaultDisplaySync();
      let orientation: number = displayInfo.orientation;
      if (display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_HALF_FOLDED) {
        this.isHalfFoldedState = true;
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
    } catch (error) {
      LogUtil.error(TAG, `judgeHorizontalsOrVerticals failed, err: ${error.message}`);
    }
  }

  private sleep(time: number): Promise<void> {
    return new Promise((resolve: () => void) => setTimeout(resolve, time));
  }

  private registerMissionListener() {
    try {
      LogUtil.info(TAG, 'registerMissionListener');
      const listenerCallBack: missionManager.MissionListener = {
        onMissionCreated: (mission: number) => {
          LogUtil.info(TAG, `onMissionCreated start ${mission}`);
          this.handleUpdateMission();
        },
        onMissionDestroyed: (mission: number) => {
          LogUtil.info(TAG, `onMissionDestroyed start ${mission}`);
          this.handleUpdateMission();
        },
        onMissionSnapshotChanged: (mission: number) => {
        },
        onMissionMovedToFront: (mission: number) => {
        },
        onMissionIconUpdated: (mission: number, icon: image.PixelMap) => {
        },
        onMissionClosed: (mission: number) => {
        },
        onMissionLabelUpdated: (mission: number) => {
          LogUtil.info(TAG, `onMissionLabelUpdated start ${mission}`);
          this.handleUpdateMission();
        },
      };
      this.listenerId = missionManager.on('mission', listenerCallBack);
    } catch (err) {
      LogUtil.error(TAG, `missionManager failed: ${err.message}`);
    }
  }

  private unRegisterMissionListener() {
    try {
      LogUtil.info(TAG, `unRegisterMissionListener ${this.listenerId}`);
      if (this.listenerId === -1) {
        return;
      }
      missionManager.off('mission', this.listenerId, (err: BusinessError) => {
        if (err) {
          LogUtil.error(TAG, `missionManager error: ${err.message}`);
          return;
        }
      });
    } catch (err) {
      LogUtil.error(TAG, `missionManager failed: ${err.message}`);
    }
  }

  private handleScreenOnClick(item: ScreenImageData): void {
    LogUtil.info(TAG, `click and check screen: ${this.checkedDisplayId}`);
    this.checkedDisplayId = item.displayId;
    this.checkedMissionId = null;
  }

  private handleMissionOnClick(item: CommonSelectPicker.WindowImageData): void {
    this.checkedDisplayId = null;
    this.checkedMissionId = item.missionId;
    LogUtil.info(TAG, `click and check mission: ${this.checkedMissionId}`);
  }

  private async handleSelectBackBtn(): Promise<void> {
    try {
      LogUtil.info(TAG, 'click back button');
      let sessionId = -1;
      if (this.selectWant.parameters?.sessionId !== undefined) {
        sessionId = Number(this.selectWant.parameters?.sessionId);
      }
      if (Number.isNaN(sessionId)) {
        sessionId = -1;
      }
      const jsonData: CommonSelectPicker.JsonData = {
        choice: 'false',
        displayId: -1,
        missionId: -1,
        checkBoxSelected: this.checkBoxSelected ? 'true' : 'false',
        isInnerAudioBoxSelected: this.isInnerAudioBoxSelected ? 'true' : 'false',
      }
      LogUtil.info(TAG, `back button json: ${JSON.stringify(jsonData)}`);
      await media.reportAVScreenCaptureUserChoice(sessionId, JSON.stringify(jsonData));
      this.globalThisInstance?.setObject('isReportedToServer', true);
      this.globalThisInstance?.setObject('userCheckBoxSelect', this.checkBoxSelected);
      this.globalThisInstance?.setObject('userCheckAudioSelect', this.isInnerAudioBoxSelected);
      await this.sleep(SELECT_BACKUP_SLEEP_TIME);
      await this.handleTerminateSelf();
    } catch (err) {
      LogUtil.error(TAG, `Failed in handleSelectBackBtn, err: ${err.message}`);
    }
  }

  private async handleSelectShareBtn(): Promise<void> {
    try {
      LogUtil.info(TAG, 'click start share button');
      let sessionId = -1;
      if (this.selectWant.parameters?.sessionId !== undefined) {
        sessionId = Number(this.selectWant.parameters?.sessionId);
      }
      let displayId: number | number[] | null = -1;
      if (this.checkedDisplayId !== null) {
        displayId = this.checkedDisplayId;
        if (displayId === BC_DISPLAY_ID) {
          displayId = BC_DISPLAY_ID_ARRAY;
        }
      }
      let jsonData: CommonSelectPicker.JsonData = {
        choice: 'true',
        displayId: displayId,
        missionId: this.checkedMissionId !== null ? this.checkedMissionId : -1,
        checkBoxSelected: this.checkBoxSelected ? 'true' : 'false',
        isInnerAudioBoxSelected: this.isInnerAudioBoxSelected ? 'true' : 'false',
      };
      LogUtil.info(TAG, `share button json: ${JSON.stringify(jsonData)}`);
      if (jsonData.missionId !== -1) {
        LogUtil.info(TAG, `Drag the selected window to the foreground.`);
        let startOptions: StartOptions = {
          displayId: -1,
        }
        LogUtil.info(TAG, 'set displayId is -1');
        await missionManager.moveMissionToFront(jsonData.missionId, startOptions);
        await this.sleep(SELECT_SHARE_SLEEP_TIME);
      }
      LogUtil.info(TAG, 'report the choice data');
      await media.reportAVScreenCaptureUserChoice(sessionId, JSON.stringify(jsonData));
      this.globalThisInstance?.setObject('isReportedToServer', true);
      this.globalThisInstance?.setObject('userCheckBoxSelect', this.checkBoxSelected);
      this.globalThisInstance?.setObject('userIsInnerAudioBoxSelected', this.isInnerAudioBoxSelected);
      await this.handleTerminateSelf();
    } catch (err) {
      LogUtil.error(TAG, `Failed in handleSelectShareBtn, err: ${err.message}`);
    }
  }

  build() {
    Column() {
      // title
      Column() {
        Text($r('app.string.select_window_name'))
          .width(`calc(100% - ${this.rectWidth}vp - 16vp)`)
          .fontSize(TEXT_FONT_SIZE)
          .lineHeight(21)
          .fontWeight(FontWeight.Medium)
          .margin({
            left: this.isRTL() ? 0 : MARGIN_LAND,
            right: this.isRTL() ? MARGIN_LAND : 0,
          })
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height(this.windowDecorHeight)
      .zIndex(2)
      .position(this.blurEffect ? { x: 0, y: 0 } : null)
      .backgroundBlurStyle(this.blurEffect ? BlurStyle.Regular : BlurStyle.NONE, {
        colorMode: ThemeColorMode.SYSTEM,
        adaptiveColor: AdaptiveColor.DEFAULT,
        scale: 0.8
      })

      Column() {
        Scroll(this.scroller) {
          GridRow() {
            // screen
            GridCol({ span: 12 }) {
              Column() {
                Text($r('app.string.select_window_screen'))
                  .fontSize(TITLE_FONT_SIZE)
                  .fontWeight(FontWeight.Bold)
                  .padding({ top: TEXT_PADDING, bottom: TEXT_PADDING })
                  .margin({ bottom: MARGIN_VERTICAL })
                  .width('100%')
                  .lineHeight(27)

                GridRow({ columns: this.screenColumns, gutter: 16 }) {
                  ForEach(this.screenImageList, (item: ScreenImageData, index?: number | undefined) => {
                    GridCol() {
                      Column() {
                        if (this.isLandscapeScreen || !CommonUtil.checkIfDeviceIsPC() || !this.isFoldable) {
                          Image(this.screenImagePixel[Number(index)])
                            .width('100%')
                            .height(this.moduleWindowHeight)
                            .objectFit((ImageFit.Contain))
                            .syncLoad(true)
                            .borderRadius('12vp')
                            .borderWidth(this.checkedDisplayId !== null && this.checkedDisplayId === item.displayId ?
                              '4vp' : '2vp')
                            .borderColor(this.checkedDisplayId !== null && this.checkedDisplayId === item.displayId ?
                              $r('sys.color.ohos_id_color_component_activated') :
                              $r('sys.color.ohos_id_color_component_normal'))
                        } else {
                          Stack({ alignContent: item.displayId === 0 ? Alignment.Top : Alignment.Bottom }) {
                            if (this.isOneDisplayHalfFolderState && this.screenImagePixel.length === 1) {
                              Column() {
                              }
                              .width('100%')
                              .height(this.moduleHeight)
                              .backgroundImage($r('app.media.oneDisplayHalfFolderStateBg'))
                              .backgroundImageSize(ImageSize.Contain)
                              .backgroundImagePosition(Alignment.Center)
                              .borderRadius('12vp')
                              .borderWidth('2vp')
                              .borderStyle(BorderStyle.Solid)
                              .borderColor($r('sys.color.ohos_id_color_component_normal'))
                            } else {
                              Column() {
                              }
                              .width('100%')
                              .height(this.moduleHeight)
                              .backgroundImage(this.fullScreenPixelMap)
                              .backgroundImageSize(ImageSize.Contain)
                              .backgroundImagePosition(Alignment.Center)
                              .backdropBlur(70)
                              .linearGradientBlur(70, {
                                fractionStops: [[0, 0], [0, 0.33], [1, 0.66], [1, 0.99], [1, 1]],
                                direction: item.displayId === 0 ? GradientDirection.Bottom : GradientDirection.Top
                              })
                              .borderRadius('12vp')
                            }

                            Image(this.screenImagePixel[Number(index)])
                              .width('100%')
                              .height(item.displayId === BC_DISPLAY_ID || this.isPortraitScreen ? this.moduleHeight :
                                'auto')
                              .objectFit((ImageFit.Contain))
                              .syncLoad(true)
                              .borderRadius('12vp')
                              .borderWidth(this.checkedDisplayId !== null && this.checkedDisplayId === item.displayId ?
                                '4vp' : '0vp')
                              .borderColor(this.checkedDisplayId !== null && this.checkedDisplayId === item.displayId ?
                                $r('sys.color.ohos_id_color_component_activated') :
                                $r('sys.color.ohos_id_color_component_normal'))
                          }
                          .width('100%')
                          .height(this.moduleHeight)
                          .borderRadius('12vp')
                        }
                        Row() {
                          Text($r('app.string.select_window_screen'))
                            .fontSize(TEXT_FONT_SIZE)
                            .fontWeight(FontWeight.Medium)
                            .textAlign(TextAlign.Center)
                          Text(`${Number(index) + 1}`)
                            .fontSize(TEXT_FONT_SIZE)
                            .fontWeight(FontWeight.Medium)
                            .textAlign(TextAlign.Center)
                        }
                        .justifyContent(FlexAlign.Center)
                        .width('100%')
                        .margin({ top: MARGIN_VERTICAL })
                      }
                      .width('100%')
                      .onClick(() => {
                        this.handleScreenOnClick(item);
                      })
                    }
                  })
                }
              }
            }
            .margin({ bottom: MARGIN_VERTICAL })
            .visibility(this.pickerMode === undefined ||
              this.pickerMode === CommonSelectPicker.PickerMode.SCREEN_ONLY ||
              this.pickerMode === CommonSelectPicker.PickerMode.SCREEN_AND_WINDOW ? Visibility.Visible :
              Visibility.None)

            // app window
            GridCol({ span: 12 }) {
              Column() {
                Text($r('app.string.select_window_mission'))
                  .fontSize(TITLE_FONT_SIZE)
                  .fontWeight(FontWeight.Bold)
                  .padding({ top: TEXT_PADDING, bottom: TEXT_PADDING })
                  .margin({ bottom: MARGIN_VERTICAL })
                  .width('100%')
                  .lineHeight(27)

                GridRow({ columns: 4, gutter: 16 }) {
                  LazyForEach(this.imageWindowData,
                    (item: CommonSelectPicker.WindowImageData, index?: number | undefined) => {
                      GridCol() {
                        Column() {
                          Row() {
                            Image(item.missionShot)
                              .height('100%')
                              .width('100%')
                              .borderRadius('12vp')
                              .objectFit((ImageFit.Contain))
                              .syncLoad(true)
                          }
                          .justifyContent(FlexAlign.Center)
                          .margin({ top: MARGIN_VERTICAL, left: IMAGE_MARGIN, right: IMAGE_MARGIN })
                          .height(this.windowPictureHeight)

                          Text(`${item.missionLabel}`)
                            .fontSize(TEXT_FONT_SIZE)
                            .fontWeight(FontWeight.Medium)
                            .width('100%')
                            .margin({ top: MARGIN_VERTICAL, bottom: MARGIN_VERTICAL })
                            .textAlign(TextAlign.Center)
                        }
                        .width('100%')
                        .padding(this.checkedMissionId !== null && this.checkedMissionId === item.missionId ?
                          0 : '2px')
                        .borderStyle(BorderStyle.Solid)
                        .borderWidth(this.checkedMissionId !== null && this.checkedMissionId === item.missionId ?
                          '4vp' : '2vp')
                        .borderColor(this.checkedMissionId !== null && this.checkedMissionId === item.missionId ?
                          $r('sys.color.ohos_id_color_component_activated') :
                          $r('sys.color.ohos_id_color_component_normal'))
                        .backgroundColor(this.checkedMissionId !== null && this.checkedMissionId === item.missionId ?
                          $r('sys.color.ohos_id_color_button_normal') : $r('sys.color.ohos_id_color_background'))
                        .borderRadius('12vp')
                        .onClick(() => {
                          this.handleMissionOnClick(item);
                        })
                      }
                    }, (item: CommonSelectPicker.WindowImageData, idx: number) => JSON.stringify(item) + idx)
                }
              }
            }
            .visibility(this.pickerMode === undefined ||
              this.pickerMode === CommonSelectPicker.PickerMode.WINDOW_ONLY ||
              this.pickerMode === CommonSelectPicker.PickerMode.SCREEN_AND_WINDOW ? Visibility.Visible :
              Visibility.None)
          }
          .margin({ left: MARGIN_LAND, right: MARGIN_LAND, bottom: MARGIN_LAND })
        }
        .scrollBar(BarState.Auto)
        .scrollable(ScrollDirection.Vertical)
        .width('100%')
        .padding({ top: this.blurEffect ? 56 : 0 })
        .edgeEffect(EdgeEffect.Spring)
        .onWillScroll(() => {
          let yOffset: number = this.scroller.currentOffset().yOffset;
          if (yOffset >= this.windowDecorHeight) {
            this.blurEffect = true;
            return
          }
          this.blurEffect = false;
        })
      }
      .layoutWeight(1)

      // button
      Column() {
        Divider().strokeWidth('1px').color($r('sys.color.ohos_id_color_subheading_separator'))

        Column() {
          Text($r('app.string.privacy_window_content', this.appLabel))
            .fontSize(TEXT_FONT_SIZE)
            .fontWeight(FontWeight.Regular)
            .width('100%')
        }
        .margin({
          left: 24,
          right: 24,
          top: 24,
          bottom: 8
        })

        Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
          Checkbox()
            .width(20)
            .height(20)
            .onChange((value: boolean) => {
              LogUtil.info(TAG, 'click checkBox');
              this.checkBoxSelected = value;
            })
            .select(this.checkBoxSelected)
            .shape(CheckBoxShape.CIRCLE)
            .visibility(this.showSensitiveCheckBox ? Visibility.Visible : Visibility.None)
          Text($r('app.string.screen_privacy_protection'))
            .height(19)
            .fontSize(14)
            .lineHeight(16)
            .fontWeight(FontWeight.Regular)
            .margin({ left: 4, right: 16 })
            .visibility(this.showSensitiveCheckBox ? Visibility.Visible : Visibility.None)

          Checkbox()
            .width(20)
            .height(20)
            .onChange((value: boolean) => {
              LogUtil.info(TAG, 'click shareSystemAudio checkBox');
              this.isInnerAudioBoxSelected = value;
            })
            .select(this.isInnerAudioBoxSelected)
            .shape(CheckBoxShape.CIRCLE)
            .visibility(this.showShareSystemAudioBox ? Visibility.Visible : Visibility.None)
          Text($r('app.string.share_system_audio'))
            .height(19)
            .fontSize(14)
            .lineHeight(16)
            .fontWeight(FontWeight.Regular)
            .margin({ left: 4 })
            .visibility(this.showShareSystemAudioBox ? Visibility.Visible : Visibility.None)
        }
        .margin({ left: 24, right: 22, bottom: 16 })
        .height(48)

        Column() {
          GridRow({ columns: 6, gutter: 16 }) {
            GridCol({ offset: 2 }) {
              Button($r('app.string.select_window_button_back'),
                { buttonStyle: ButtonStyleMode.NORMAL, type: ButtonType.Normal })
                .borderRadius($r('sys.float.corner_radius_level4'))
                .fontSize($r('sys.float.ohos_id_text_size_button1'))
                .width('100%')
                .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
                .onClick(() => {
                  this.debounce(() => {
                    this.handleSelectBackBtn();
                  }, BUTTON_CLICK_TIME);
                })
            }

            GridCol() {
              Button($r('app.string.select_window_button_share'),
                { buttonStyle: ButtonStyleMode.EMPHASIZED, type: ButtonType.Normal })
                .borderRadius($r('sys.float.corner_radius_level4'))
                .fontSize($r('sys.float.ohos_id_text_size_button1'))
                .width('100%')
                .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
                .enabled(this.canStartScreenCapture)
                .onClick(() => {
                  this.debounce(() => {
                    this.handleSelectShareBtn();
                  }, BUTTON_CLICK_TIME);
                })
            }
          }
          .width('100%')
        }
        .margin({ left: MARGIN_LAND, right: MARGIN_LAND, bottom: MARGIN_LAND })
      }
    }
    .width('100%')
  }
}