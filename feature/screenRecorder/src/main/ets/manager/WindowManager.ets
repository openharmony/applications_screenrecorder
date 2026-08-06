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
  CCMUtil,
  CommonUtil,
  DisplayUtil,
  EVENT_NAME_HIDE_SCREENRECORD_THUMB,
  EventReportUtil,
  GlobalThisUtil,
  LogUtil,
  PreferenceUtils,
  StopRecordTriggerResult
} from '@ohos/common';
import lazy { buffer } from '@kit.ArkTS';
import lazy { promptAction } from '@kit.ArkUI';
import { deviceInfo, settings } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import lazy { StartOptions } from '@kit.AbilityKit';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import performanceMonitor from '@ohos.arkui.performanceMonitor';
import { BusinessError } from '@ohos.base';
import commonEventManager from '@ohos.commonEventManager';
import curves from '@ohos.curves';
import lazy utd from '@ohos.data.uniformTypeDescriptor';
import display from '@ohos.display';
import lazy I18n from '@ohos.i18n';
import lazy screenshotManager from '@ohos.screenshot';
import lazy windowManager from '@ohos.window';
import {
  DEFAULT_CORNER_RADIUS_S,
  Direction,
  INITIAL_POSITION_X,
  INITIAL_POSITION_X_FOR_TV,
  LANDSCAPE_MARGIN,
  PC_CORNER_RADIUS_S,
  SHADOW_OFFSET_X,
  SHADOW_OFFSET_Y,
  SHADOW_RADIUS,
  SHARE_BUTTON_HEIGHT,
  SHARE_BUTTON_INTERVAL,
  WINDOW_EXPANSION_PROPORTION
} from '../components/PicturePreviewer/types';
import { ExpansionScreenUtil } from '../util/ExpansionScreenUtil';
import { RecorderUtil } from '../util/RecorderUtil';
import { NotificationManager } from './NotificationManager';
import { RecorderToast } from './RecorderToast';
import {
  BLUR_ANIMATION_DELAY,
  BLUR_ANIMATION_TIMEOUT,
  BUTTON_DISTANCE_FROM_BOTTOM,
  BUTTON_DISTANCE_FROM_BOTTOM_TV,
  CCM,
  COLOR_TRANSPARENT,
  DISAPPEAR_INTERVAL,
  EXPANDING_NEW_FORMS_EXTERNAL_BOTTOM_MARGIN,
  FADE_OUT_DELAY,
  FADE_OUT_DURATION,
  FADE_OUT_OPACITY_END,
  FADE_OUT_OPACITY_START,
  FINAL_SCALE_VALUE,
  FINAL_SUB_WINDOW_BLUR_VALUE,
  FINAL_THUMB_BORDER_OPACITY_VALUE,
  INIT_POSITION_VALUE,
  INIT_SCALE_VALUE,
  INIT_SUB_WINDOW_BLUR_VALUE,
  INIT_THUMB_BORDER_OPACITY_VALUE,
  MIDDLE_SCALE_VALUE,
  MOVE_OUT_DURATION,
  MOVEOUT_THRESHOLD,
  OPACITY_ANIMATION_DELAY,
  OPACITY_ANIMATION_TIMEOUT,
  POSITION_AND_SCALE_ANIMATION_TIMEOUT,
  POSITION_ZOOM_RATIO,
  PREVIEW_PAGE,
  PREVIEW_SUB_WINDOW_NAME,
  PREVIEW_WINDOW_NAME,
  SCALE_ANIMATION_DELAY,
  SCALE_ANIMATION_TIMEOUT,
  SELECT_DISPLAY_ID,
  SHARE_BUTTON_OPACITY_DELAY,
  SHARE_BUTTON_OPACITY_TIMEOUT,
  SHARE_UI_ABILITY_NAME,
  SPRING_DAMPING,
  SPRING_MASS,
  SPRING_STIFFNESS,
  THUMB_HEIGHT_TV,
  THUMB_WIDTH_TV,
  TWO_SIDE,
  VALIDATE_SDK_VERSION,
  WINDOW_BORDER_WIDTH,
  ZOOM_RATIO
} from './types';

const TAG = 'PreWindowManager';

type Window = windowManager.Window;

/**
 * Window management tool class
 *
 * @since 2022-09-03
 */
export class WindowManager {
  private previewWindow?: Window;
  private shareWindow?: Window;
  private shareButtonHeight: number = 0;
  private windowRadius: number = DEFAULT_CORNER_RADIUS_S;
  private distanceToLeftEdge: number = 0;
  private initialPreviewPosX: number = 0;
  private initialPreviewPosY: number = 0;
  private previewPosX?: SubscribedAbstractProperty<number>;
  private subWindow?: Window;
  private dftDisplayWidth: number = 0;
  private dftDisplayHeight: number = 0;
  private extendedSize: number = 0;
  private blurValue: number = INIT_SUB_WINDOW_BLUR_VALUE;
  private viewTransparentWidth: number = 0;
  private viewTransparentHeight: number = 0;
  private yInitOffset: number = 0;
  private isAnimating: boolean = false;
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private initialPositionY: number = 0;
  private dftRotation: number | null = null;
  private currScreenArea: number = 0;
  private isTv: boolean = CommonUtil.checkIfDeviceIsTv();
  private thumbWidth: number = 0;
  private thumbHeight: number = 0;
  private isCaptureFullOfScreen: boolean = false;
  private touchableArea: windowManager.Rect[] = [];
  private static ins: WindowManager;

  public static getInstance(): WindowManager {
    if (!WindowManager.ins) {
      WindowManager.ins = new WindowManager();
    }
    return WindowManager.ins;
  }

  public getViewTransparentWidth(): number {
    return this.viewTransparentWidth;
  }

  public getViewTransparentHeight(): number {
    return this.viewTransparentHeight;
  }

  public setTouchableArea(value: windowManager.Rect[]): void {
    this.touchableArea = value;
  }

  public getPreviewPosX(): SubscribedAbstractProperty<number> | undefined {
    return this.previewPosX;
  }

  public getIsAnimating(): boolean {
    return this.isAnimating;
  }

  public setIsAnimating(value: boolean): void {
    this.isAnimating = value;
  }

  public setThumbWidth(value: number) {
    this.thumbWidth = value;
  }

  public getThumbWidth(): number {
    return this.thumbWidth;
  }

  public setThumbHeight(value: number) {
    this.thumbHeight = value;
  }

  public getThumbHeight(): number {
    return this.thumbHeight;
  }

  public setWindowRadius(value: number) {
    this.windowRadius = value;
  }

  public getWindowRadius(): number {
    return this.windowRadius;
  }

  public setExtendedSize(value: number) {
    this.extendedSize = value;
  }

  public getExtendedSize(): number {
    return this.extendedSize;
  }

  public setDftDisplayWidth(value: number) {
    this.dftDisplayWidth = value;
  }

  public getDftDisplayWidth(): number {
    return this.dftDisplayWidth;
  }

  public setDftDisplayHeight(value: number) {
    this.dftDisplayHeight = value;
  }

  public getDftDisplayHeight(): number {
    return this.dftDisplayHeight;
  }

  public setInitialPreviewPosX(value: number) {
    this.initialPreviewPosX = value;
  }

  public getInitialPreviewPosX(): number {
    return this.initialPreviewPosX;
  }

  public setInitialPreviewPosY(value: number) {
    this.initialPreviewPosY = value;
  }

  public getInitialPreviewPosY(): number {
    return this.initialPreviewPosY;
  }

  public setInitialPositionY(value: number) {
    this.initialPositionY = value;
  }

  public getInitialPositionY(): number {
    return this.initialPositionY;
  }

  public setDistanceToLeftEdge(value: number) {
    this.distanceToLeftEdge = value;
  }

  public getDistanceToLeftEdge(): number {
    return this.distanceToLeftEdge;
  }

  public setShareButtonHeight(value: number) {
    this.shareButtonHeight = value;
  }

  public getShareButtonHeight(): number {
    return this.shareButtonHeight;
  }

  public setIsCaptureFullOfScreen(value: boolean) {
    this.isCaptureFullOfScreen = value;
  }

  /**
   * Whether the current language is right-to-left
   */
  isRTL(): boolean {
    try {
      const systemLocale: string = I18n.System.getSystemLocale();
      return I18n.isRTL(systemLocale);
    } catch (error) {
      LogUtil.error(`getSystemLocale failed, code: ${error.code}, message: ${error.message}.`);
      return false;
    }
  }

  /**
   * Initialize and show the capsule window.
   */
  /* instrument ignore next */


  public setDisplayRotation(rotation: number) {
    this.dftRotation = rotation;
  }

  public getDisplayRotation(): number | null {
    return this.dftRotation;
  }

  public async onChange(changeRotation: number, width: number, height: number) {
    const screenArea = width * height;
    const isRecording = this.globalThisInstance!.getObject('isRecording') as boolean;
    const isPreViewWindowExisting = this.globalThisInstance!.getObject('isPreViewWindowExisting') as boolean;
    /* instrument ignore else */
    if (isRecording && changeRotation !== this.dftRotation) {
      if (isPreViewWindowExisting && screenArea === this.currScreenArea) {
        this.dftRotation = changeRotation;
        this.destroyPreWindow();
        AppStorage.Delete('previewWindow');
        RecorderUtil.postKillProcessMessage();
      } else {
        this.dftRotation = changeRotation;
      }
    } else if (isRecording === false && changeRotation !== this.dftRotation) {
      if (isPreViewWindowExisting && screenArea === this.currScreenArea) {
        this.destroyPreWindow();
        AppStorage.Delete('previewWindow');
        RecorderUtil.postKillProcessMessage();
      }
    }
  }

  async initPreviewImage() {
    const dftDisplay: display.Display | undefined = ExpansionScreenUtil.getSelectDisplay();
    if (dftDisplay === undefined) {
      return;
    }
    const privateWindow = display.hasPrivateWindow(dftDisplay.id);
    const privacyStratagy: string =
      await CCMUtil.getCCMParam(CCM.SCREEN_RECORDER_PRIVACY_STRATAGY.name,
        CCM.SCREEN_RECORDER_PRIVACY_STRATAGY.key, CCM.SCREEN_RECORDER_PRIVACY_STRATAGY.defaultValue) as string;
    if (privateWindow && privacyStratagy === CCM.SCREEN_RECORDER_PRIVACY_STRATAGY.defaultValue) {
      const width = dftDisplay.width;
      const height = dftDisplay.height;
      const blackThumbnail = this.getBlackThumbnail(width, height);
      AppStorage.setOrCreate<PixelMap>('thumbnail', blackThumbnail);
      LogUtil.info(TAG, 'Currently in the privacy interface, a black thumbnail is generated.');
    } else {
      await this.getPreviewImage(dftDisplay.id);
    }
  }

  async initPreviewWindow(windowId: number) {
    try {
      AppStorage.setOrCreate<number>('thumbWidth', this.thumbWidth);
      AppStorage.setOrCreate<number>('thumbHeight', this.thumbHeight);
      AppStorage.setOrCreate<boolean>('isPreviewDisabled', true);
      await this.createAndSetPreviewWindow(windowId);
      await this.initSubWindow();
    } catch (error) {
      LogUtil.error(TAG, 'Initialize the preview window failed because: ', (error as BusinessError).message);
    }
  }

  private async getPreviewImage(displayId: number) {
    try {
      let thumbnail: PixelMap;
      /* instrument ignore else */
      if (deviceInfo.sdkApiVersion >= VALIDATE_SDK_VERSION) {
        let screenshotOption: screenshotManager.ScreenshotOptions = {
          isNotificationNeeded: false,
          displayId: displayId,
          isCaptureFullOfScreen: this.isCaptureFullOfScreen
        }
        thumbnail = await screenshotManager.save(screenshotOption);
        LogUtil.info(TAG, `No need to notify the app,isNotificationNeeded: ${screenshotOption.isNotificationNeeded}`);
      } else {
        thumbnail = await screenshotManager.save();
      }
      AppStorage.setOrCreate<PixelMap>('thumbnail', thumbnail);
      LogUtil.info(TAG, 'Generate normal thumbnails.');
    } catch (error) {
      LogUtil.error(TAG, `getPreviewImage error: ${error}, isCaptureFullOfScreen ${this.isCaptureFullOfScreen}}`);
    }
  }

  private getBlackThumbnail(width: number = 0, height: number = 0) {
    try {
      const arrayBuffer = new ArrayBuffer(3 * width * height);
      const blackArr = buffer.from(arrayBuffer).fill(0);
      const blackThumbnail = image.createPixelMapSync(blackArr.buffer, {
        editable: false,
        srcPixelFormat: 5,
        pixelFormat: 3,
        size: { height: height, width: width }
      });
      LogUtil.info(TAG, 'run getBlackThumbnail success.');
      return blackThumbnail;
    } catch (err) {
      throw new Error('run getBlackThumbnail error.' + err);
    }
  }

  private initPhonePreviewWindowPosAndSize(dftDisplay: display.Display): void {
    const dpi = dftDisplay.densityDPI;
    this.extendedSize = DisplayUtil.vp2pxInTs(WINDOW_BORDER_WIDTH, dpi) * TWO_SIDE;
    this.thumbWidth = this.dftDisplayWidth * ZOOM_RATIO + this.extendedSize;
    this.thumbHeight = this.dftDisplayHeight * ZOOM_RATIO + this.extendedSize;
    this.adjustThumbWidthAndHeight(this.thumbWidth, dftDisplay);
    const initialPreviewPosXRtl = dftDisplay.width - this.thumbWidth - DisplayUtil.vp2pxInTs(INITIAL_POSITION_X, dpi);
    this.initialPreviewPosX = this.isRTL() ? initialPreviewPosXRtl : DisplayUtil.vp2pxInTs(INITIAL_POSITION_X, dpi);
    this.initialPreviewPosY =
      dftDisplay.height - this.thumbHeight - DisplayUtil.vp2pxInTs(this.getThumbMarginBottom(), dpi);
    this.initialPositionY =
      dftDisplay.height - this.thumbHeight - DisplayUtil.vp2pxInTs(BUTTON_DISTANCE_FROM_BOTTOM, dpi);
    this.distanceToLeftEdge = this.initialPreviewPosX + this.thumbWidth;
    this.shareButtonHeight = DisplayUtil.vp2pxInTs(SHARE_BUTTON_INTERVAL + SHARE_BUTTON_HEIGHT, dpi);
  }

  /**
   * 根据计算的预览窗宽度和当前屏幕分辨率信息调整预览窗宽高
   *
   * @param width 预览窗宽度
   * @param dftDisplay 当前屏幕分辨率信息
   */
  private adjustThumbWidthAndHeight(width: number, dftDisplay: display.Display): void {
    /* instrument ignore if */
    if (width > dftDisplay.width * 2 / 3) {
      this.thumbWidth = dftDisplay.width * 2 / 3;
      this.thumbHeight = this.thumbHeight * this.thumbWidth / width;
    }
  }

  /* instrument ignore next */
  private initTvPreviewWindowPosAndSize(dftDisplay: display.Display): void {
    this.windowRadius = PC_CORNER_RADIUS_S;
    const dpi = dftDisplay.densityDPI;
    this.extendedSize = DisplayUtil.vp2pxInTs(WINDOW_BORDER_WIDTH, dpi) * TWO_SIDE;
    this.thumbWidth = DisplayUtil.vp2pxInTs(THUMB_WIDTH_TV, dpi) + this.extendedSize;
    this.thumbHeight = DisplayUtil.vp2pxInTs(THUMB_HEIGHT_TV, dpi) + this.extendedSize;
    const initialPreviewPosXRtl =
      dftDisplay.width - this.thumbWidth - DisplayUtil.vp2pxInTs(INITIAL_POSITION_X_FOR_TV, dpi);
    this.initialPreviewPosX =
      this.isRTL() ? initialPreviewPosXRtl : DisplayUtil.vp2pxInTs(INITIAL_POSITION_X_FOR_TV, dpi);
    this.initialPreviewPosY =
      dftDisplay.height - this.thumbHeight - DisplayUtil.vp2pxInTs(this.getThumbMarginBottom(), dpi);
    this.initialPositionY =
      dftDisplay.height - this.thumbHeight - DisplayUtil.vp2pxInTs(BUTTON_DISTANCE_FROM_BOTTOM_TV, dpi);
    this.distanceToLeftEdge = this.initialPreviewPosX + this.thumbWidth;
    this.shareButtonHeight = DisplayUtil.vp2pxInTs(SHARE_BUTTON_INTERVAL + SHARE_BUTTON_HEIGHT, dpi);
  }

  private getThumbMarginBottom() {
    return CommonUtil.IsNewExpandingFormsExternalDisplay() ? EXPANDING_NEW_FORMS_EXTERNAL_BOTTOM_MARGIN :
      this.isTv ? BUTTON_DISTANCE_FROM_BOTTOM_TV : BUTTON_DISTANCE_FROM_BOTTOM;
  }

  private checkAvoidPotDistanceRtl() {
    return CommonUtil.checkIfDeviceNeedAvoidPot() && DisplayUtil.isLandscapeModeRtl();
  }

  private checkAvoidPotDistance() {
    return CommonUtil.checkIfDeviceNeedAvoidPot() && DisplayUtil.isLandscapeMode();
  }


  private async createAndSetPreviewWindow(windowId: number): Promise<void> {
    const dftDisplay: display.Display | undefined = ExpansionScreenUtil.getSelectDisplay();
    if (dftDisplay === undefined) {
      return;
    }
    // 创建预览窗
    const windowConfig: windowManager.Configuration = {
      name: PREVIEW_WINDOW_NAME + windowId,
      windowType: windowManager.WindowType.TYPE_SCREENSHOT,
      ctx: this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext,
      displayId: dftDisplay.id
    };
    this.previewWindow = await windowManager.createWindow(windowConfig);
    this.globalThisInstance!.setObject('isPreViewWindowExisting', true);
    const curWindowId = this.globalThisInstance!.getObject('windowId') as number;
    this.globalThisInstance!.setObject('preWindowId', curWindowId);
    this.globalThisInstance!.setObject('windowId', curWindowId + 1);
    AppStorage.setOrCreate<Window>('previewWindow', this.previewWindow);
    // 设置窗口不可截图
    this.previewWindow.setSnapshotSkip(true);

    // 设置预览窗初始化位置
    await this.setInitialPosition();
    // 设置窗口大小
    await this.previewWindow.resize(this.thumbWidth + this.viewTransparentWidth * 2,
      this.thumbHeight + this.viewTransparentHeight * 2 + this.shareButtonHeight);
    this.previewPosX = AppStorage.SetAndLink<number>('previewPosX', this.initialPreviewPosX);

    // 添加预览框内容
    await this.previewWindow.setUIContent(PREVIEW_PAGE);
    const dpi = dftDisplay.densityDPI;
    this.previewWindow.setCornerRadius(DisplayUtil.vp2pxInTs(this.windowRadius, dpi));
    this.previewWindow.setWindowBackgroundColor(COLOR_TRANSPARENT);
    if (CommonUtil.isScreenReaderEnabled()) {
      await this.previewWindow.setWindowFocusable(true);
    } else {
      await this.previewWindow.setWindowFocusable(false);
    }
  }

  async setInitialPosition() {
    try {
      const dftDisplay: display.Display | undefined = ExpansionScreenUtil.getSelectDisplay();
      if (dftDisplay === undefined) {
        return;
      }
      this.currScreenArea = dftDisplay.width * dftDisplay.height;
      this.dftRotation = dftDisplay.rotation;
      const dpi = dftDisplay.densityDPI;
      this.yInitOffset = DisplayUtil.vp2pxInTs(SHADOW_OFFSET_Y * INIT_SCALE_VALUE, dpi);
      this.viewTransparentWidth = SHADOW_RADIUS + SHADOW_OFFSET_X + this.thumbWidth * WINDOW_EXPANSION_PROPORTION;
      this.viewTransparentHeight = SHADOW_RADIUS + SHADOW_OFFSET_Y + this.thumbHeight * WINDOW_EXPANSION_PROPORTION;

      const avoidPotDistanceRtl = this.checkAvoidPotDistanceRtl() ? DisplayUtil.vp2pxInTs(LANDSCAPE_MARGIN, dpi) : 0;
      const avoidPotDistance = this.checkAvoidPotDistance() ? DisplayUtil.vp2pxInTs(LANDSCAPE_MARGIN, dpi) : 0;

      const previewPosX = this.isRTL() ? this.initialPreviewPosX - this.viewTransparentWidth - avoidPotDistanceRtl :
        this.initialPreviewPosX - this.viewTransparentWidth + avoidPotDistance;


      const previewWindow = this.getPreviewWindow();
      await previewWindow.moveWindowTo(previewPosX,
        this.initialPreviewPosY - this.viewTransparentHeight - this.shareButtonHeight);
    } catch (error) {
      LogUtil.info(TAG, 'set preview window initial position error:' + error);
    }
  }

  public onFoldStatusChange = async () => {
    try {
      LogUtil.error(TAG, 'onFoldStatusChange callback error');
      if (DisplayUtil.isThreeFoldScreen()) {
        await this.destroyPreviewWindow(true);
      } else {
        await CommonUtil.sleep(50);
        const dftDisplay: display.Display | undefined = ExpansionScreenUtil.getSelectDisplay();
        if (dftDisplay === undefined) {
          return;
        }
        this.initPhonePreviewWindowPosAndSize(dftDisplay);
        await this.setInitialPosition();
      }
    } catch (error) {
      LogUtil.info(TAG, 'onFoldStatusChange callback error' + error);
    }
  }

  private composeFoldStatusChange() {
    const lastDisplayMode = DisplayUtil.getFoldDisplayMode();
    LogUtil.info(TAG, `register foldStatusChange`);
    return async () => {
      try {
        if (DisplayUtil.isThreeFoldScreen()) {
          const currentDisplayMode = DisplayUtil.getFoldDisplayMode();
          if (lastDisplayMode === currentDisplayMode) {
            return;
          }
          LogUtil.warn(TAG, `foldStatus change to destroyPreviewWindow`);
          await this.destroyPreviewWindow(true);
        } else {
          await CommonUtil.sleep(50);
          const dftDisplay: display.Display | undefined = ExpansionScreenUtil.getSelectDisplay();
          if (dftDisplay === undefined) {
            return;
          }
          this.initPhonePreviewWindowPosAndSize(dftDisplay);
          await this.setInitialPosition();
        }
      } catch (error) {
        LogUtil.error(TAG, 'onFoldStatusChange callback error' + error);
      }
    }
  }

  private async initSubWindow(): Promise<void> {
    try {
      const dftDisplay: display.Display | undefined = ExpansionScreenUtil.getSelectDisplay();
      if (dftDisplay === undefined) {
        return;
      }
      const subWindowConfig: windowManager.Configuration = {
        name: PREVIEW_SUB_WINDOW_NAME,
        windowType: windowManager.WindowType.TYPE_FLOAT,
        ctx: this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext,
        parentId: this.previewWindow!.getWindowProperties().id,
        displayId: dftDisplay.id
      };
      this.subWindow = await windowManager.createWindow(subWindowConfig);
      this.subWindow.setSnapshotSkip(true);
      await this.subWindow.moveWindowTo(INIT_POSITION_VALUE, INIT_POSITION_VALUE);
      const subWindowDisplay = dftDisplay;
      const subWindowWidth = subWindowDisplay.width;
      const subWindowHeight = subWindowDisplay.height;
      await this.subWindow.resize(subWindowWidth + this.extendedSize, subWindowHeight + this.extendedSize);
      await this.subWindow.setWindowFocusable(false);
      await this.subWindow.setWindowTouchable(false);
    } catch (error) {
      LogUtil.error(TAG, 'create sub window failed because: ', (error as BusinessError).message);
    }
  }

  /**
   * Initialize and show the preview window.
   */
  async showPreviewWindow(): Promise<void> {
    try {
      this.addDisplaySizeChangeListener();
      const window = this.getPreviewWindow();
      const subWindow = this.getSubWindow();
      await subWindow.showWindow();
      await window.showWindow();

      CommonUtil.setApsScene('SCREEN_RECORDER_END_PREVIEW_SHOW', 1);
      this.positionAndScaleAnimation();
      this.blurAnimation();
      this.opacityAnimation();
      this.shareButtonOpacity();
      this.scaleAnimation();
      setTimeout(() => {
        try {
          this.onFoldStatusChange = this.composeFoldStatusChange();
          this.regisFoldStatueChange();
        } catch (e) {
          LogUtil.error(TAG, `register foldStatusChange failed, error code: ${e?.code}, message: ${e?.message}`);
        }
      }, SCALE_ANIMATION_TIMEOUT + SCALE_ANIMATION_DELAY)
      LogUtil.info(TAG, 'window start show');

      const previewTimeoutId = setTimeout(() => this.destroyPreviewWindow(), DISAPPEAR_INTERVAL);
      this.globalThisInstance!.setObject('previewTimeoutId', previewTimeoutId);
      LogUtil.warn(TAG, 'Success to show preview window!');
    } catch (error) {
      LogUtil.error(TAG, 'Show the preview window failed because: ', (error as BusinessError).message);
      EventReportUtil.setStopResult(StopRecordTriggerResult.RESULT_ERROR_BY_THUMBNAIL_EXCEPTION)
      EventReportUtil.setStopFaultReason(error.message);
      EventReportUtil.reportStopRecordEvent();
    }
  }

  /**
   * pc类重写了此方法
   */
  public regisFoldStatueChange() {
    try {
      display.on('foldStatusChange', this.onFoldStatusChange);
    } catch (error) {
      LogUtil.error(`regisFoldStatueChange. message: ${error?.message}, code: ${error?.code}`);
    }
  }

  /**
   * pc类重写了此方法
   */
  public unregisterFoldStatueChange() {
    try {
      display.off('foldStatusChange', this.onFoldStatusChange);
    } catch (error) {
      LogUtil.error(`unregisterFoldStatueChange. message: ${error?.message}, code: ${error?.code}`);
    }
  }

  private addDisplaySizeChangeListener() {
    // 为特殊折叠屏单手模式场景适配
    try {
      if (DisplayUtil.isVerdeProducts() || DisplayUtil.isHopeProducts()) {
        const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
        settings.registerKeyObserver(context, 'single_hand_mode', settings.domainName.USER_PROPERTY, () => {
          LogUtil.info(TAG, 'singleHandMode is change');
          if (this.previewWindow?.isWindowShowing()) {
            LogUtil.info(TAG, `addDisplaySizeChange: previewWindow is showing, resize`);
            const dftDisplay: display.Display | undefined = ExpansionScreenUtil.getSelectDisplay();
            if (dftDisplay === undefined) {
              return;
            }
            this.initPhonePreviewWindowPosAndSize(dftDisplay);
            this.setInitialPosition();
          }
        })
      }
    } catch (error) {
      LogUtil.error(TAG, 'addDisplaySizeChangeListener error: ' + (error as BusinessError).message);
    }
  }

  getSubWindow(): Window {
    this.subWindow = this.subWindow || windowManager.findWindow(PREVIEW_SUB_WINDOW_NAME);
    return this.subWindow;
  }

  private positionAndScaleAnimation() {
    const window = this.getPreviewWindow();
    window.scale({
      x: Number((this.dftDisplayWidth / (this.thumbWidth - this.extendedSize)).toFixed(2)),
      y: Number((this.dftDisplayHeight / (this.thumbHeight - this.extendedSize)).toFixed(2))
    });
    const xPosition = (this.thumbWidth - this.dftDisplayWidth) * POSITION_ZOOM_RATIO + this.initialPreviewPosX;
    const yOffset = (this.dftDisplayHeight - this.thumbHeight) * POSITION_ZOOM_RATIO - this.yInitOffset;
    const yPosition = this.initialPositionY - yOffset;
    window.translate({ x: -xPosition, y: -yPosition });
    performanceMonitor.begin('SCREENRECORD_ANIMATION', performanceMonitor.ActionType.LAST_UP);
    animateTo({
      duration: POSITION_AND_SCALE_ANIMATION_TIMEOUT,
      curve: Curve.Friction,
      playMode: PlayMode.Normal,
      onFinish: async () => {
        LogUtil.info(TAG, 'positionAndScaleAnimation is over');
      },
    }, () => {
      window.scale({ x: MIDDLE_SCALE_VALUE, y: MIDDLE_SCALE_VALUE });
      window.translate({ x: INIT_POSITION_VALUE, y: INIT_POSITION_VALUE });
    });
  }

  private scaleAnimation() {
    const window = this.getPreviewWindow();
    window.scale({ x: MIDDLE_SCALE_VALUE, y: MIDDLE_SCALE_VALUE });
    animateTo({
      duration: SCALE_ANIMATION_TIMEOUT,
      delay: SCALE_ANIMATION_DELAY,
      curve: Curve.Smooth,
      playMode: PlayMode.Normal,
      onFinish: () => {
        LogUtil.warn(TAG, 'scaleAnimation is over');
        performanceMonitor.end('SCREENRECORD_ANIMATION')
        AppStorage.Set<boolean>('isPreviewDisabled', false);
        try {
          window.setTouchableAreas(this.touchableArea);
        } catch (exception) {
          LogUtil.error(`Failed to set touchable areas. Cause code : ${exception.code}, message: ${exception.message}`);
        }
        CommonUtil.setApsScene('SCREEN_RECORDER_END_PREVIEW_SHOW', 0);
      },
    }, () => {
      window.scale({ x: FINAL_SCALE_VALUE, y: FINAL_SCALE_VALUE });
    });
  }

  private getTouchableArea(): windowManager.Rect[] {
    return [{
      left: this.viewTransparentWidth,
      top: this.viewTransparentHeight,
      width: this.thumbWidth,
      height: this.thumbHeight
    },
      {
        left: this.viewTransparentWidth,
        top: this.thumbHeight + this.viewTransparentHeight +
        DisplayUtil.vp2pxInTs(SHARE_BUTTON_INTERVAL, DisplayUtil.getDefaultDisplayDpi()),
        width: this.thumbWidth,
        height: DisplayUtil.vp2pxInTs(SHARE_BUTTON_HEIGHT, DisplayUtil.getDefaultDisplayDpi())
      }]
  }

  private blurAnimation() {
    this.subWindow!.setBlur(this.blurValue);
    LogUtil.info(TAG, 'blurAnimation is start!');
    animateTo({
      duration: BLUR_ANIMATION_TIMEOUT,
      delay: BLUR_ANIMATION_DELAY,
      curve: Curve.Friction,
      playMode: PlayMode.Normal,
      onFinish: async () => {
        LogUtil.info(TAG, 'blurAnimation is over');
        await this.subWindow!.hide();
      },
    }, () => {
      this.subWindow!.setBlur(FINAL_SUB_WINDOW_BLUR_VALUE);
    });
  }

  private opacityAnimation() {
    AppStorage.setOrCreate<number>('borderColorOpacityValue', INIT_THUMB_BORDER_OPACITY_VALUE);
    animateTo({
      duration: OPACITY_ANIMATION_TIMEOUT,
      delay: OPACITY_ANIMATION_DELAY,
      curve: Curve.Sharp,
      playMode: PlayMode.Normal,
      onFinish: async () => {
        LogUtil.info(TAG, 'opacityAnimation is over');
      },
    }, () => {
      AppStorage.Set<number>('borderColorOpacityValue', FINAL_THUMB_BORDER_OPACITY_VALUE);
    });
  }

  private shareButtonOpacity() {
    AppStorage.setOrCreate<number>('shareColorOpacityValue', INIT_THUMB_BORDER_OPACITY_VALUE);
    animateTo({
      duration: SHARE_BUTTON_OPACITY_TIMEOUT,
      delay: SHARE_BUTTON_OPACITY_DELAY,
      curve: Curve.Sharp,
      playMode: PlayMode.Normal,
      onFinish: async () => {
        LogUtil.info(TAG, 'share button opacityAnimation is over');
      },
    }, () => {
      AppStorage.Set<number>('shareColorOpacityValue', FINAL_THUMB_BORDER_OPACITY_VALUE);
    });
  }

  public async startShare(videoUri: string | undefined) {
    try {
      LogUtil.warn(TAG, 'start share');
      CommonUtil.clearPreviewTimeout();
      commonEventManager.publish('sceneboard.event.HIDE_DROPDOWN_WINDOW', (error) => {
        if (error) {
          LogUtil.error(TAG,
            `HIDE_DROPDOWN_WINDOW publish failed: { code: ${error?.code}, message: ${error?.message}}`);
        } else {
          LogUtil.info(TAG, `HIDE_DROPDOWN_WINDOW success`);
        }
      });

      if (this.shareWindow) {
        LogUtil.info(TAG, 'shareWindow already exist, start destroy previous window');
        await this.shareWindow.destroyWindow();
        this.shareWindow = undefined;
      }

      if (videoUri == undefined) {
        LogUtil.error(TAG, `cannot share videoUri`);
        await this.destroyPreviewWindow();
        return;
      }
      LogUtil.info(TAG, `share videoUri : ${videoUri}`);

      // Destroy preview window before launching ShareUIAbility
      await this.destroyPreviewWindow(false);
      AppStorage.Delete('previewWindow');
      this.previewWindow = undefined;
      this.globalThisInstance!.setObject('isPreViewWindowExisting', false);

      // Launch ShareUIAbility as floating window with videoUri in parameters
      const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
      let want: Want = {
        bundleName: 'com.ohos.screenrecorder',
        abilityName: SHARE_UI_ABILITY_NAME,
        parameters: {
          videoUri: videoUri
        }
      };
      let startOptions: StartOptions = {
        windowMode: AbilityConstant.WindowMode.WINDOW_MODE_FLOATING
      };
      await context.startAbility(want, startOptions);
      GlobalThisUtil.getInstance()!.setObject('isShareWindowExisting', true);
      LogUtil.warn(TAG, 'start share success - launched ShareUIAbility');
    } catch (err) {
      LogUtil.error(TAG, 'start share error: ' + (err as BusinessError).message);
    }
  }

  public dismissShareWindow = async () => {
    try {
      let shareContext = this.globalThisInstance!.getObject('shareUIAbilityContext') as common.UIAbilityContext;
      if (!shareContext) {
        LogUtil.info(TAG, 'dismiss shareWindow failed, no shareUIAbilityContext');
        return;
      }
      GlobalThisUtil.getInstance()!.setObject('isShareWindowExisting', false);
      shareContext.terminateSelf();
      LogUtil.info(TAG, 'dismiss share window via terminateSelf');
    } catch (err) {
      LogUtil.error(TAG, 'dismiss share window error: ' + (err as BusinessError).message);
    }
  }

  /* instrument ignore next */
  async destroyShareWindow(): Promise<void> {
    try {
      let shareContext = this.globalThisInstance!.getObject('shareUIAbilityContext') as common.UIAbilityContext;
      if (!shareContext) {
        LogUtil.info(TAG, 'shareUIAbility not exist, no need to destroy');
        return;
      }
      shareContext.terminateSelf();
      LogUtil.info(TAG, 'destroy shareUIAbility success');
    } catch (err) {
      LogUtil.error(TAG, 'destroyShareWindow fail, err: ' + (err as BusinessError).message);
    }
  }

  /**
   * Move preview window
   *
   * @param coordinateX
   * @param coordinateY
   */
  /* instrument ignore next */
  async movePreviewWindow(coordinateX: number): Promise<void> {
    try {
      if (!this.isAnimating) {
        const previewWindow = this.getPreviewWindow();
        previewWindow?.translate({ x: coordinateX - this.initialPreviewPosX });
        LogUtil.info(TAG, 'Move preview window');
      }
    } catch (error) {
      LogUtil.error(TAG, 'Failed to move the preview window with reason:', (error as BusinessError).message);
    }
  }

  async previewWindowDestroy(previewWindow: windowManager.Window, subWindow: windowManager.Window): Promise<void> {
    try {
      await previewWindow.hide();
      await previewWindow.destroyWindow();
      if (subWindow) {
        await subWindow.hide();
        await subWindow.destroyWindow();
      }
      this.previewWindow = undefined;
      this.globalThisInstance!.setObject('isPreViewWindowExisting', false);
      AppStorage.Delete('previewWindow');
    } catch (error) {
      LogUtil.error(TAG, 'Failed to destroy the preview window with reason:', (error as BusinessError).message);
    }
  }

  /**
   * Stop moving preview window
   *
   * @param movingSpeed movingSpeed Moving speed, which is transferred only in the moving scenario.
   */
  async stopMovingPreviewWindow(movingSpeed: number): Promise<void> {
    const previewWindow = this.getPreviewWindow();
    const subWindow = this.getSubWindow();
    const displacement = this.previewPosX!.get() - this.initialPreviewPosX;
    LogUtil.debug(TAG, `moving speed ${movingSpeed}, moving displacement: ${displacement}`);
    if (Math.abs(displacement) > MOVEOUT_THRESHOLD) {
      this.isAnimating = true;
      AppStorage.setOrCreate<boolean>('isAnimating', true);
      // If the moving distance is over the threshold, hide the window.
      previewWindow.opacity(FADE_OUT_OPACITY_START);
      LogUtil.info(TAG, `Animation move-out in stopMovingWindow is started.`);
      performanceMonitor.begin('SCREENRECORD_DISMISS_ANIMATION_BY_USER', performanceMonitor.ActionType.LAST_UP)
      animateTo({
        curve: curves.interpolatingSpring(movingSpeed, SPRING_MASS, SPRING_STIFFNESS, SPRING_DAMPING),
        playMode: PlayMode.Normal,
        onFinish: async (): Promise<void> => {
          performanceMonitor.end('SCREENRECORD_DISMISS_ANIMATION_BY_USER');
          await this.previewWindowDestroy(previewWindow, subWindow);
          LogUtil.info(TAG, 'Animation move-out in stopMovingWindow is over.');
          this.isAnimating = false;
          AppStorage.setOrCreate<boolean>('isAnimating', false);
          RecorderUtil.postKillProcessMessage();
        },
      }, (): void => {
        previewWindow.translate({ x: displacement > 0 ? this.distanceToLeftEdge : -this.distanceToLeftEdge });
        previewWindow.opacity(FADE_OUT_OPACITY_END);
      });
      return;
    }

    LogUtil.debug(TAG, `Animation move-back in stopMovingWindow is started.`);
    animateTo({
      curve: curves.interpolatingSpring(movingSpeed, SPRING_MASS, SPRING_STIFFNESS, SPRING_DAMPING),
      playMode: PlayMode.Normal,
      onFinish: (): void => {
        this.isAnimating = false;
        LogUtil.debug(TAG, `Animation move-back in stopMovingWindow is over.`);
      },
    }, (): void => {
      previewWindow.translate({ x: 0 });
      this.previewPosX!.set(this.initialPreviewPosX);
    });
  }

  /**
   * Destroy Existing Preview Window without Animation
   */
  async destroyPreWindow(): Promise<void> {
    CommonUtil.clearPreviewTimeout();
    const windowId = this.globalThisInstance!.getObject('windowId') as number;
    if (windowId !== 0) {
      let previewWindow: windowManager.Window | null = null;
      let subWindow: windowManager.Window | null = null;
      try {
        await this.unregisterListener();
        const preWindowId = this.globalThisInstance!.getObject('preWindowId') as number;
        previewWindow = windowManager.findWindow(PREVIEW_WINDOW_NAME + preWindowId);
        subWindow = windowManager.findWindow(PREVIEW_SUB_WINDOW_NAME);
        LogUtil.info(TAG, `previewWindow preWindowId is: ${preWindowId}`);
        await previewWindow.destroyWindow();
        await subWindow.destroyWindow();
        this.globalThisInstance!.setObject('isPreViewWindowExisting', false);
      } catch (error) {
        LogUtil.error(TAG, 'Failed to find the preview window because: ', error?.message);
      }
    }
  }

  /**
   * Hide the preview window
   */
  async hidePreviewWindow(): Promise<void> {
    LogUtil.warn(TAG, 'Hide preview window');
    const previewWindow = this.getPreviewWindow();
    try {
      await previewWindow.hide();
    } catch (e) {
      LogUtil.error(TAG, 'Failed to hidePreviewWindow:', (e as BusinessError).message);
    }
  }

  /**
   * Destroy Preview Window with Animation
   */
  async destroyPreviewWindow(isPostKill: boolean = true): Promise<void> {
    LogUtil.info(TAG, 'destroyPreviewWindow start');
    try {
      await this.unregisterListener();
      const previewWindow = this.getPreviewWindow();
      const subWindow = this.getSubWindow();
      await previewWindow.setWindowTouchable(false);
      previewWindow.translate({ x: 0 });
      performanceMonitor.begin('SCREENRECORD_DISMISS_ANIMATION', performanceMonitor.ActionType.LAST_UP);
      animateTo({
        duration: MOVE_OUT_DURATION,
        curve: Curve.Friction,
        playMode: PlayMode.Normal,
        onFinish: (): void => {
          LogUtil.debug(TAG, 'Animation move-out is over.');
        },
      }, (): void => {
        previewWindow.translate({ x: this.isRTL() ? this.distanceToLeftEdge : -this.distanceToLeftEdge });
      });

      previewWindow.opacity(FADE_OUT_OPACITY_START);
      animateTo({
        duration: FADE_OUT_DURATION,
        delay: FADE_OUT_DELAY,
        curve: Curve.Sharp,
        playMode: PlayMode.Normal,
        onFinish: async (): Promise<void> => {
          performanceMonitor.end('SCREENRECORD_DISMISS_ANIMATION');
          LogUtil.debug(TAG, 'Animation fade-out is over.');
          await this.previewWindowDestroy(previewWindow, subWindow);
          LogUtil.warn(TAG, 'destroy the preview window finish');
          EventReportUtil.reportEvent(EVENT_NAME_HIDE_SCREENRECORD_THUMB,
            { 'TYPE': Direction.AUTO });
          if (isPostKill) {
            RecorderUtil.postKillProcessMessage();
          }
        },
      }, (): void => {
        previewWindow.opacity(FADE_OUT_OPACITY_END);
      });
    } catch (error) {
      LogUtil.error(TAG, 'Failed to destroy the preview window with reason:', (error as BusinessError).message);
    }
  }

  getPreviewWindow(): Window {
    try {
      const preWindowId = this.globalThisInstance!.getObject('preWindowId') as number;
      this.previewWindow = this.previewWindow || windowManager.findWindow(PREVIEW_WINDOW_NAME + preWindowId);
    } catch (error) {
      this.previewWindow = undefined;
      LogUtil.error(TAG, 'Failed to find preview window with reason:', (error as BusinessError).message);
    }
    return this.previewWindow as Window;
  }


  async showPreviewWindowWhenStop(width?: number, height?: number) {
    await this.showPreviewWindow();
  }

  async initPreviewWindowWhenStop(width?: number, height?: number): Promise<void> {
    const windowId = this.globalThisInstance!.getObject('windowId') as number;
    const preWindowId = this.globalThisInstance!.getObject('preWindowId') as number;
    LogUtil.info(TAG, `current windowId: ${windowId}, preWindowId: ${preWindowId}`);
    const dftDisplay: display.Display | undefined = ExpansionScreenUtil.getSelectDisplay();
    if (dftDisplay === undefined) {
      return;
    }
    this.initDftDisplay(dftDisplay, width, height);
    LogUtil.info(TAG, `dftDisplayWidth = ${this.dftDisplayWidth}, dftDisplayHeight = ${this.dftDisplayHeight}`);
    this.isTv ? this.initTvPreviewWindowPosAndSize(dftDisplay) : this.initPhonePreviewWindowPosAndSize(dftDisplay);
    await this.initPreviewWindow(windowId);
    this.setTouchableArea(this.getTouchableArea());
  }

  public initDftDisplay(dftDisplay: display.Display, width?: number, height?: number,) {
    LogUtil.info(TAG, `dftDisplay.width = ${dftDisplay.width}, dftDisplay.height = ${dftDisplay.height}`);
    this.dftDisplayWidth = width ? width : dftDisplay.width;
    this.dftDisplayHeight = height ? height : dftDisplay.height;
    LogUtil.info(TAG, `dftDisplayWidth = ${this.dftDisplayWidth}, dftDisplayHeight = ${this.dftDisplayHeight}`);
  }

  /**
   * 检查隐私窗口
   */
  async checkHasPrivateWindow(): Promise<void> {
    try {
      let displayId = this.globalThisInstance.getObject(SELECT_DISPLAY_ID);
      let displayClass = displayId != undefined
        ? display.getDisplayByIdSync(displayId as number) : display.getDefaultDisplaySync();
      LogUtil.info(TAG, 'checkHasPrivateWindow displayId:' + displayId)
      let ret = display.hasPrivateWindow(displayClass.id);
      if (ret === undefined) {
        LogUtil.error(TAG, 'Failed to check has privateWindow or not.');
      }
      if (ret) {
        LogUtil.warn(TAG, 'The screen recording start interface is a privacy window');
        let resName: string = await this.getPrivacyRecordResName();
        RecorderToast.getInstance().showToast(resName, promptAction.ToastShowMode.SYSTEM_TOP_MOST);
      } else {
        LogUtil.warn(TAG, 'The screen recording start interface is not a privacy window');
      }
    } catch (err) {
      LogUtil.error(TAG, 'checkHasPrivateWindow fail, err: ' + (err as BusinessError).message);
    }
  }

  /**
   * 根据CCM配置获取隐私界面录屏的toast提示
   *
   * @returns toast提示resName
   */
  protected async getPrivacyRecordResName() {
    const privacyStratagy: string = await CCMUtil.getCCMParam(CCM.SCREEN_RECORDER_PRIVACY_STRATAGY.name,
      CCM.SCREEN_RECORDER_PRIVACY_STRATAGY.key, CCM.SCREEN_RECORDER_PRIVACY_STRATAGY.defaultValue) as string;
    let resName: string =
      (privacyStratagy === CCM.SCREEN_RECORDER_PRIVACY_STRATAGY.defaultValue) ? 'privacy_interface_toast' :
        'privacy_window_record_toast';
    return resName;
  }

  /**
   * 设置隐私回调
   */
  setPrivacyModeCallback(): void {
    try {
      LogUtil.info(TAG, `set privacyModeChange callback`);
      display.on('privateModeChange', async (isPrivacy: boolean) => {
        LogUtil.warn(TAG, `Currently the privacy interface: ${isPrivacy}`);
        if (isPrivacy) {
          LogUtil.info(TAG, 'Privacy interface display toast');
          let resName: string = await this.getPrivacyRecordResName();
          RecorderToast.getInstance().showToast(resName, promptAction.ToastShowMode.SYSTEM_TOP_MOST);
        }
      });
    } catch (err) {
      LogUtil.error(TAG, 'setPrivacyModeCallback setListener, err: ' + (err as BusinessError).message);
    }
  }

  async showCapsule(startTime: number, dataPreferences: PreferenceUtils) {
    const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    try {
      const dftDisplay = display.getDefaultDisplaySync();
      this.setDisplayRotation(dftDisplay.rotation);
      await NotificationManager.getInstance().createNotification(startTime);
      LogUtil.warn(TAG, 'show notification success');
      dataPreferences.loadPreferences(context, 'showTouchState');
      display.on('change', () => {
        const dftChangeDisplay = display.getDefaultDisplaySync();
        LogUtil.info(TAG, `dftChangeDisplay rotation: ${dftChangeDisplay.rotation}`);
        this.onChange(dftChangeDisplay.rotation, dftChangeDisplay.width, dftChangeDisplay.height);
      })
    } catch (err) {
      LogUtil.error(TAG, 'showCapsule fail, err: ' + (err as BusinessError).message);
    }
  }

  async cancelCapsule(isCapsuleStarted: boolean) {
    if (!isCapsuleStarted) {
      LogUtil.info(TAG, 'Capsule not showed, no need to destroy');
      return;
    }
    await NotificationManager.getInstance().cancelNotification();
    LogUtil.info(TAG, 'cancel notification success');
  }

  async unregisterListener() {
    if (DisplayUtil.isVerdeProducts() || DisplayUtil.isHopeProducts()) {
      const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
      settings.unregisterKeyObserver(context, 'single_hand_mode', settings.domainName.USER_PROPERTY);
    }
    this.unregisterFoldStatueChange();
  }

  async destroyCapsule() {
  }
}