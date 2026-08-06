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

/* instrument ignore file */
import {
  CommonUtil,
  DisplayUtil,
  EVENT_NAME_HIDE_SCREENRECORD_THUMB,
  EventReportUtil,
  GlobalThisUtil,
  LogUtil,
  PreferenceUtils
} from '@ohos/common';
import { common } from '@kit.AbilityKit';
import lazy { JSON } from '@kit.ArkTS';
import lazy { curves, display, promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import lazy { pointer } from '@kit.InputKit';
import { resourceManager } from '@kit.LocalizationKit';
import performanceMonitor from '@ohos.arkui.performanceMonitor';
import lazy windowManager from '@ohos.window';
import {
  CAPSULE_SHADOW_RADIUS,
  CAPSULE_WINDOW_HEIGHT,
  RESERVED_SPACE_MULTIPLES,
  ZERO_TIME_TEXT
} from '../components/Capsule/types';
import { Direction, INITIAL_POSITION_X, PC_CORNER_RADIUS_S } from '../components/PicturePreviewer/types';
import { ExpansionScreenUtil } from '../util/ExpansionScreenUtil';
import { RecorderUtil } from '../util/RecorderUtil';
import { MicManager } from './MicManager';
import { PcRecordManager } from './PcRecordManager';
import { RecorderToast } from './RecorderToast';
import {
  BUTTON_DISTANCE_FROM_BOTTOM,
  CAPSULE_PAGE,
  CAPSULE_WINDOW_MARGIN_TOP,
  CAPSULE_WINDOW_MARGIN_VERTICAL,
  CAPSULE_WINDOW_NAME,
  CAPSULE_WINDOW_SET_FOCUS_ABLE_DELAY,
  COLOR_TRANSPARENT,
  FADE_OUT_DELAY,
  FADE_OUT_DURATION,
  FADE_OUT_OPACITY_END,
  FADE_OUT_OPACITY_START,
  FONT_SIZE_UNIT,
  FreeScreenArea,
  GESTURE_AREA_HEIGHT,
  HALF,
  MASK_PAGE,
  MASK_WINDOW_NAME,
  MOVE_OUT_DURATION,
  MOVEOUT_THRESHOLD,
  PC_DISTANCE_FROM_BOTTOM,
  PC_DOCK_BAR_HEIGHT,
  SCREEN_CUT_AREA_HEIGHT,
  SELECT_DISPLAY_ID,
  SPRING_DAMPING,
  SPRING_MASS,
  SPRING_STIFFNESS,
  THUMB_WIDTH,
  WINDOW_BORDER_WIDTH
} from './types';
import { WindowManager } from './WindowManager';

/* instrument ignore file */
const TAG = 'PcWindowManager';
const HPR_DISPLAY_ID_B = 0;
const HPR_DISPLAY_ID_C = 999;
type Window = windowManager.Window;

export class PcWindowManager extends WindowManager {
  private maskWindows: Map<number | undefined, Window | undefined> = new Map();
  private pcGlobalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private capsuleWindow?: Window;
  private initialWindowWidth: number = 0;
  private capsuleMiddleLine: number | undefined = undefined;
  private capsuleFreeArea?: FreeScreenArea;
  private static instance: PcWindowManager;
  private displayChangeCallback: Callback<number> | undefined = undefined;
  private displays: display.Display[] = [];

  public static getInstance(): PcWindowManager {
    if (!PcWindowManager.instance) {
      PcWindowManager.instance = new PcWindowManager();
    }
    return PcWindowManager.instance;
  }

  async showCapsule(startTime: number, dataPreferences: PreferenceUtils) {
    await MicManager.getInstance().checkPcMicState();
    await this.showCapsuleWindow();
    LogUtil.warn(TAG, 'show capsuleWindow success');
  }

  private async showCapsuleWindow(): Promise<void> {
    try {
      let displayId = this.pcGlobalThisInstance.getObject(SELECT_DISPLAY_ID);
      const dftDisplay =
        displayId != undefined ? display.getDisplayByIdSync(displayId as number) : display.getDefaultDisplaySync();
      this.setDisplayRotation(dftDisplay.rotation)
      LogUtil.info(TAG, `dftDiaplay: ${JSON.stringify(dftDisplay)}`);
      // 选择录屏面后，拉起录音胶囊时获取记录屏幕宽高比，仅PC使用
      const windowConfig: windowManager.Configuration = {
        name: CAPSULE_WINDOW_NAME,
        windowType: windowManager.WindowType.TYPE_SCREENSHOT,
        displayId: dftDisplay.id,
        ctx: this.pcGlobalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext
      };
      this.capsuleWindow = await windowManager.createWindow(windowConfig);
      AppStorage.setOrCreate<Window>('capsuleWindow', this.capsuleWindow);
      await this.capsuleWindow.setUIContent(CAPSULE_PAGE);
      this.capsuleWindow.setWindowBackgroundColor(COLOR_TRANSPARENT);
      await this.setInitialParams(this.capsuleWindow.getUIContext());
      this.capsuleWindow.setWindowFocusable(false);
      await this.capsuleWindow.showWindow();
      setTimeout(() => this.capsuleWindow?.setWindowFocusable(true), CAPSULE_WINDOW_SET_FOCUS_ABLE_DELAY);
      this.displayChangeCallback = async () => {
        try {
          let displayId = this.pcGlobalThisInstance.getObject(SELECT_DISPLAY_ID);
          const dftChangeDisplay = displayId != undefined
            ? display.getDisplayByIdSync(displayId as number) : display.getDefaultDisplaySync();
          LogUtil.info(TAG,
            `dftChangeDisplay rotation: ${dftChangeDisplay.rotation}, dftRotation: ${this.getDisplayRotation()}`);
          this.setCapsuleWindowSize(this.initialWindowWidth, vp2px(CAPSULE_WINDOW_HEIGHT));
          this.onChange(dftChangeDisplay.rotation, dftChangeDisplay.width, dftChangeDisplay.height);
        } catch (error) {
          LogUtil.error(TAG, 'Initialize and show the capsule window failed because: ', JSON.stringify(error));
        }
      };
      this.capsuleWindow.getUIContext().getUIObserver().on('densityUpdate', () => {
        LogUtil.info(TAG, 'densityUpdate');
        this.setInitialParams(this.capsuleWindow?.getUIContext() as UIContext);
        this.setCapsuleWindowSize(this.initialWindowWidth, vp2px(CAPSULE_WINDOW_HEIGHT));
      })
      display.on('change', this.displayChangeCallback);
    } catch (error) {
      LogUtil.error(TAG, 'Initialize and show the capsule window failed because: ', JSON.stringify(error));
    }
  }

  public getCapsuleWindow(): Window {
    try {
      this.capsuleWindow = this.capsuleWindow || AppStorage.Get<Window>('capsuleWindow');
    } catch (error) {
      this.capsuleWindow = undefined;
      LogUtil.error(TAG, 'Failed to find capsule window with reason:', (error as BusinessError).message);
    }
    return this.capsuleWindow as Window;
  }

  /**
   * Move capsule window
   *
   * @param coordinateX
   * @param coordinateY
   */
  private async moveCapsuleWindow(coordinateX: number, coordinateY: number): Promise<void> {
    try {
      AppStorage.setOrCreate<boolean>('isMoveCapsuleWindowComplete', false);
      const capsuleWindow = this.getCapsuleWindow();
      this.capsuleFreeArea = this.capsuleFreeArea || AppStorage.Get<FreeScreenArea>('capsuleFreeArea');
      let newX = coordinateX;
      let newY = coordinateY;
      newX = Math.min(newX, this.capsuleFreeArea!.maxCoordinateX);
      newX = Math.max(newX, this.capsuleFreeArea!.minCoordinateX);
      newY = Math.min(newY, this.capsuleFreeArea!.maxCoordinateY);
      newY = Math.max(newY, this.capsuleFreeArea!.minCoordinateY);
      await capsuleWindow?.moveWindowTo(newX, newY);
      AppStorage.setOrCreate<number>('defaultCapsuleWindowX', newX);
      AppStorage.setOrCreate<number>('defaultCapsuleWindowY', newY);
      AppStorage.setOrCreate<boolean>('isMoveCapsuleWindowComplete', true);
    } catch (error) {
      LogUtil.error(TAG, 'Failed to move the capsule window with reason:', (error as BusinessError).message);
    }
  }

  /**
   * Stop moving capsule window
   *
   * @param coordinateX
   * @param coordinateY
   */
  async stopMovingCapsuleWindow(coordinateX: number, coordinateY: number): Promise<void> {
    try {
      this.capsuleMiddleLine = this.capsuleMiddleLine! || AppStorage.Get<number | undefined>('capsuleMiddleLine');
      this.capsuleFreeArea = this.capsuleFreeArea || AppStorage.Get<FreeScreenArea>('capsuleFreeArea');
      let displayId = this.capsuleWindow?.getWindowProperties()?.displayId;
      const dftDisplay =
        displayId !== undefined ? display.getDisplayByIdSync(displayId as number) : display.getDefaultDisplaySync();
      const dpi = dftDisplay.densityDPI;
      this.capsuleFreeArea = {
        minCoordinateX: DisplayUtil.vp2pxInTs(CAPSULE_WINDOW_MARGIN_VERTICAL, dpi),
        maxCoordinateX: dftDisplay.width - DisplayUtil.vp2pxInTs(CAPSULE_WINDOW_MARGIN_VERTICAL, dpi) -
        this.initialWindowWidth,
        minCoordinateY: 0,
        maxCoordinateY: dftDisplay.height - DisplayUtil.vp2pxInTs(GESTURE_AREA_HEIGHT, dpi) -
        vp2px(CAPSULE_WINDOW_HEIGHT)
      };
      const defaultDisplay = display.getDefaultDisplaySync();

      if (DisplayUtil.isHalfFoldedState() && coordinateY > defaultDisplay.height) {
        coordinateY = coordinateY - defaultDisplay.height;
        let data: display.FoldCreaseRegion = display.getCurrentFoldCreaseRegion();
        coordinateY = coordinateY - (data !== undefined ? data?.creaseRects[0].height : 0);
      }
      const newX = coordinateX < this.capsuleMiddleLine! ? this.capsuleFreeArea!.minCoordinateX :
        this.capsuleFreeArea!.maxCoordinateX;
      this.moveCapsuleWindow(newX, coordinateY);
      LogUtil.info(TAG, 'Stop moving capsule window');
    } catch (error) {
      LogUtil.error(TAG, 'Failed to stop moving the capsule window with reason:', (error as BusinessError).message);
    }
  }

  async destroyCapsuleWindow(): Promise<void> {
    try {
      const capsuleWindow = this.getCapsuleWindow();
      await capsuleWindow?.destroyWindow();
      this.capsuleWindow = undefined;
      AppStorage.Delete('capsuleWindow');
      LogUtil.warn(TAG, 'destroy the capsule window finish');
    } catch (error) {
      LogUtil.error(TAG, 'Failed to destroy the capsule window with reason:', (error as BusinessError)?.message);
    }
  }

  /**
   * Set the capsule window width.
   *
   * @param windowWidth (Unit: px)
   * @param windowHeight (Unit: px)
   */
  async setCapsuleWindowSize(windowWidth: number, windowHeight: number): Promise<void> {
    try {
      const capsuleWindow = this.getCapsuleWindow();
      LogUtil.warn(TAG, `'windowWidth:${windowWidth}, windowHeight:${windowHeight}`);
      await capsuleWindow.resize(windowWidth, windowHeight);
      LogUtil.info(TAG, 'Success to setCapsuleWindowSize');
      let displayId = this.pcGlobalThisInstance.getObject(SELECT_DISPLAY_ID);
      const dftDisplay =
        displayId != undefined ? display.getDisplayByIdSync(displayId as number) : display.getDefaultDisplaySync();
      const dpi = dftDisplay.densityDPI;
      this.capsuleFreeArea = {
        minCoordinateX: DisplayUtil.vp2pxInTs(CAPSULE_WINDOW_MARGIN_VERTICAL, dpi),
        maxCoordinateX: dftDisplay.width - DisplayUtil.vp2pxInTs(CAPSULE_WINDOW_MARGIN_VERTICAL, dpi) - windowWidth,
        minCoordinateY: CommonUtil.checkIfDeviceIsPhone() ? DisplayUtil.vp2pxInTs(SCREEN_CUT_AREA_HEIGHT, dpi) : 0,
        maxCoordinateY: dftDisplay.height - DisplayUtil.vp2pxInTs(GESTURE_AREA_HEIGHT, dpi) - windowHeight,
      };
      AppStorage.setOrCreate<FreeScreenArea>('capsuleFreeArea', this.capsuleFreeArea);
      const pcWindowPosX = this.isRTL() ? this.capsuleFreeArea.maxCoordinateX : this.capsuleFreeArea.minCoordinateX;
      const windowPosX = CommonUtil.checkIfDeviceIsPhone() ? this.capsuleFreeArea.maxCoordinateX : pcWindowPosX;
      const windowPosY = DisplayUtil.vp2pxInTs(CAPSULE_WINDOW_MARGIN_TOP, dpi);
      AppStorage.setOrCreate<number>('defaultCapsuleWindowX', windowPosX);
      AppStorage.setOrCreate<number>('defaultCapsuleWindowY', windowPosY);
      this.capsuleMiddleLine = dftDisplay.width * HALF - windowWidth * HALF;
      AppStorage.setOrCreate<number>('capsuleMiddleLine', this.capsuleMiddleLine);
      await capsuleWindow.moveWindowTo(windowPosX, DisplayUtil.vp2pxInTs(CAPSULE_WINDOW_MARGIN_TOP, dpi));
      LogUtil.info(TAG, 'Success to move capsule window');
    } catch (error) {
      LogUtil.error(TAG, 'setCapsuleWindowWidth failed because: ', (error as BusinessError).message);
    }
  }

  public async setInitialParams(uiContext: UIContext): Promise<void> {
    try {
      const context = this.pcGlobalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;

      // 获取初始文本大小
      let initialTextSize = context.resourceManager.getNumber($r('sys.float.ohos_id_text_size_body3').id);
      const fontSizeScale = AppStorage.Get<Number>('fontSizeScaleCode') as number;
      LogUtil.info(TAG,
        'setInitialParams, initialTextSize : ' + initialTextSize + '; fontSizeScale : ' + fontSizeScale);
      initialTextSize = initialTextSize * fontSizeScale;

      // 获取麦克风字符串资源
      const resource = $r('app.string.microphone');
      const strResource: resourceManager.Resource = {
        bundleName: resource.bundleName,
        moduleName: resource.moduleName,
        id: resource.id,
      };
      const initialMicStr = await context.resourceManager.getStringValue(strResource);

      // 测量文本宽度
      const initialMicWidth = uiContext.getMeasureUtils().measureText({
        textContent: initialMicStr,
        fontSize: `${initialTextSize}${FONT_SIZE_UNIT}`,
        fontWeight: FontWeight.Medium,
      });
      const initialRecordWidth = uiContext.getMeasureUtils().measureText({
        textContent: ZERO_TIME_TEXT,
        fontSize: `${initialTextSize}${FONT_SIZE_UNIT}`,
        fontWeight: FontWeight.Regular,
      });

      // 获取初始预填充值
      const initialMicPrePadding = context.resourceManager.getNumber($r('app.float.mic_pre_build_padding').id);
      const initialTimePrePadding = context.resourceManager.getNumber($r('app.float.timer_pre_build_padding').id);

      // 计算初始胶囊区域宽度
      const initialAreaWidth = initialMicWidth + initialRecordWidth + initialMicPrePadding + initialTimePrePadding;
      this.initialWindowWidth = initialAreaWidth + vp2px(CAPSULE_SHADOW_RADIUS * RESERVED_SPACE_MULTIPLES);

      // 设置胶囊窗口大小
      await this.setCapsuleWindowSize(this.initialWindowWidth, vp2px(CAPSULE_WINDOW_HEIGHT));

    } catch (error) {
      LogUtil.error(TAG,
        `setInitialParams failed, error code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message}.`);
    }
  }

  async cancelCapsule(isCapsuleStarted: boolean) {
    if (!isCapsuleStarted) {
      LogUtil.info(TAG, 'Capsule not showed, no need to destroy');
      return;
    }
    await this.hideCapsuleWindow();
    LogUtil.info(TAG, 'hide capsuleWindow success');
  }

  /**
   * Hide Capsule Window
   */
  async hideCapsuleWindow(): Promise<void> {
    try {
      const capsuleWindow = this.getCapsuleWindow();
      await capsuleWindow.hideWithAnimation();
      LogUtil.warn(TAG, 'hide the capsule window finish');
    } catch (error) {
      LogUtil.error(TAG, 'Failed to hide the capsule window with reason:', (error as BusinessError)?.message);
    }
  }

  async destroyCapsule() {
    await this.destroyCapsuleWindow();
  }

  /**
   * 移除显示器监听器
   */
  public displayMaskRemoveListener = async (displayId: number) => {
    LogUtil.warn(TAG, `display ${displayId} displayMaskRemoveListener.`);
    this.destroyMaskWindow();
  }
  /**
   * 添加显示器监听器
   */
  public displayMaskAddListener = async (displayId: number) => {
    LogUtil.warn(TAG, `display ${displayId} displayMaskAddListener.`);
    this.destroyMaskWindow();
  }

  /**
   * 初始化录屏鼠标款选区域的窗口
   *
   * @param displayId 屏幕ID
   */
  async initMaskWindow(displayId: number | undefined = undefined): Promise<void> {
    try {
      this.pcGlobalThisInstance!.setObject('isMaskWindowExisting', true);
      const dftDisplay =
        displayId != undefined ? display.getDisplayByIdSync(displayId) : display.getDefaultDisplaySync();
      const windowConfig: windowManager.Configuration = {
        name: MASK_WINDOW_NAME + `_${displayId}`,
        windowType: windowManager.WindowType.TYPE_SCREENSHOT,
        displayId: displayId,
        ctx: this.pcGlobalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext,
      };
      let win = await windowManager.createWindow(windowConfig);
      this.maskWindows.set(displayId, win);
      win.setSnapshotSkip(true);
      // 若不存在铰链区，getCreaseRect().height就是0
      await win.resize(dftDisplay.width, ExpansionScreenUtil.getCreaseRect().height + dftDisplay.height);
      LogUtil.info(TAG, `displayId: ${displayId} maskWindow create success`);
      let storage = new LocalStorage();
      storage.setOrCreate('displayId', displayId);
      if (displayId !== undefined) {
        storage.setOrCreate('windowId', win.getWindowProperties().id);
        if (ExpansionScreenUtil.isCreaseExist(displayId)) {
          storage.setOrCreate('isCreaseExist', ExpansionScreenUtil.isCreaseExist(displayId));
          storage.setOrCreate('creaseRect', ExpansionScreenUtil.getCreaseRect());
        }
      }
      await win.loadContent(MASK_PAGE, storage);
      win.setWindowBackgroundColor(COLOR_TRANSPARENT);
      await win.setWindowFocusable(false);
      await win?.showWindow();
    } catch (error) {
      LogUtil.error(TAG, 'create window failed because: ', (error as BusinessError).message);
    }
  }

  /**
   * 获取录屏鼠标款选区域的窗口
   *
   * @param displayId 屏幕ID
   * @returns 窗口
   */
  public async getMaskWindow(displayId: number | undefined = undefined): Promise<Window | null> {
    try {
      let win = this.maskWindows.get(displayId) || windowManager.findWindow(MASK_WINDOW_NAME + `_${displayId}`);
      this.maskWindows.set(displayId, win);
      LogUtil.info(TAG, 'get mask window success');
      return win;
    } catch (error) {
      LogUtil.error(TAG, 'get mask window failed because: ', (error as BusinessError).message);
    }
    return null;
  }

  /**
   * Destroy mask Window
   */
  async destroyMaskWindow(): Promise<void> {
    try {
      this.pcGlobalThisInstance!.setObject('isMaskWindowExisting', false);
      for (let id of this.maskWindows.keys()) {
        const win = await this.getMaskWindow(id);
        await win?.hide();
        await win?.destroyWindow();
      }
      this.maskWindows.clear()
    } catch (error) {
      LogUtil.error(TAG, `destroy mask window failed, error: ${error}`);
    }
    LogUtil.info(TAG, 'destroy the mask window finish');
  }

  /**
   * 设置鼠标样式
   *
   * @param tag 日志TAG
   * @param windowId 窗口ID
   * @param pointerStyle 指针样式
   * @param isCheck 是否检查
   */
  public setPointerStyle(tag: string, windowId: number, pointerStyle?: PointerStyle, isCheck: boolean = false) {
    LogUtil.info(tag, `setPointerStyle with ${windowId}`);
    pointer.setPointerStyle(windowId, pointerStyle).then(() => {
      LogUtil.info(tag, 'Set pointer style success');
      if (isCheck) {
        setTimeout(() => {
          pointer.getPointerStyle(windowId).then(value => {
            LogUtil.info(tag, `checkPointerStyle with ${windowId} is ${value} target ${pointerStyle}`);
          })
        }, 100);
      }
    }).catch((error: BusinessError) => {
      LogUtil.error(tag, `Set pointer style failed, error: ${error}`);
    });
  }

  /**
   * 设置窗口指针样式
   *
   * @param displayId 屏幕ID
   * @param pointerStyle 样式
   */
  public async setWindowPontStyle(displayId: number, pointerStyle: PointerStyle) {
    const window = await this.getMaskWindow(displayId);
    let windowId = window!.getWindowProperties().id;
    if (windowId < 0) {
      LogUtil.warn(TAG, 'setWindowPontStyle Invalid windowId');
      return;
    }
    this.setPointerStyle(TAG, windowId, pointerStyle);
  }

  async showPreviewWindowWhenStop(width?: number, height?: number) {
    await this.showPreviewWindow();
  }

  async initPreviewWindowWhenStop(width?: number, height?: number): Promise<void> {
    const windowId = this.pcGlobalThisInstance!.getObject('windowId') as number;
    const preWindowId = this.pcGlobalThisInstance!.getObject('preWindowId') as number;
    LogUtil.info(TAG, `current windowId: ${windowId}, preWindowId: ${preWindowId}`);
    const dftDisplay: display.Display | undefined = ExpansionScreenUtil.getSelectDisplay();
    if (dftDisplay === undefined) {
      return;
    }
    this.displays = await ExpansionScreenUtil.getAllDisplays();
    this.initDftDisplay(dftDisplay, width, height);
    await this.initPCPreviewWindowPosAndSize(dftDisplay);
    await this.initPreviewWindow(windowId);
    this.setTouchableArea(this.getPcTouchableArea())
  }

  private getPcTouchableArea(): windowManager.Rect[] {
    return [{
      left: this.getViewTransparentWidth(),
      top: this.getViewTransparentHeight(),
      width: this.getThumbWidth(),
      height: this.getThumbHeight()
    }]
  }

  /**
   * 初始化 缩略图的动画开始时，图片的大小。Hopper上，b+c截图时，高是上下屏只和。
   *
   * @param dftDisplay display
   * @param width 指定的宽
   * @param height 指定的高
   */
  public initDftDisplay(dftDisplay: display.Display, width?: number, height?: number,) {
    LogUtil.info(TAG, `dftDisplay.width = ${dftDisplay.width}, dftDisplay.height = ${dftDisplay.height}`);
    this.setDftDisplayWidth(width ? width : dftDisplay.width);
    this.setDftDisplayHeight(height ? height :
      PcRecordManager.getInstance().isBCRecord() ? ExpansionScreenUtil.getPcBCHeight(this.displays) :
        dftDisplay.height);
    LogUtil.info(TAG,
      `dftDisplayWidth = ${this.getDftDisplayWidth()}, dftDisplayHeight = ${this.getDftDisplayHeight()}`);
  }

  private async initPCPreviewWindowPosAndSize(dftDisplay: display.Display): Promise<void> {
    const dpi = dftDisplay.densityDPI;
    const isBCRecord = PcRecordManager.getInstance().isBCRecord();
    const dockBarHeight = DisplayUtil.vp2pxInTs(PC_DOCK_BAR_HEIGHT, dpi);
    const distanceFromBottom = DisplayUtil.vp2pxInTs(PC_DISTANCE_FROM_BOTTOM, dpi);
    const buttonDistanceFromBottom = DisplayUtil.vp2pxInTs(BUTTON_DISTANCE_FROM_BOTTOM, dpi);
    const initialPositionX = DisplayUtil.vp2pxInTs(INITIAL_POSITION_X, dpi);
    const thumbWidth = DisplayUtil.vp2pxInTs(THUMB_WIDTH, dpi);
    const extendedSize = DisplayUtil.vp2pxInTs(WINDOW_BORDER_WIDTH, dpi) * 2;
    const scale = this.getDftDisplayWidth() / this.getDftDisplayHeight();

    this.setWindowRadius(PC_CORNER_RADIUS_S);
    this.setExtendedSize(extendedSize);
    this.setThumbWidth(thumbWidth + extendedSize);
    this.setThumbHeight(DisplayUtil.vp2pxInTs(THUMB_WIDTH / scale, dpi) + extendedSize);
    this.setInitialPreviewPosX(this.isRTL() ? initialPositionX :
      dftDisplay.width - this.getThumbWidth() - initialPositionX);
    // Hopper截B+C的时候，创建的window在display id是0（B面上），但是截图要显示B+C面，就需将window的高变大，将c面也包含进来
    // 这里就是计算B+C+中轴区域的总高度。
    this.setInitialPreviewPosY((isBCRecord ? ExpansionScreenUtil.getPcBCHeight(this.displays) : dftDisplay.height) -
    this.getThumbHeight() - distanceFromBottom);
    // 根据条件调整 initialPreviewPosY
    if (ExpansionScreenUtil.isUpScreenOfNormalHalfFolded(this.displays, dftDisplay.id) && !isBCRecord) {
      this.setInitialPreviewPosY(this.getInitialPreviewPosY() + dockBarHeight);
    }

    this.setInitialPositionY(dftDisplay.height - this.getThumbHeight() - buttonDistanceFromBottom);
    this.setDistanceToLeftEdge(initialPositionX + this.getThumbWidth());
    this.setShareButtonHeight(0);
  }

  public onPcFoldStatusChange = async () => {
    try {
      LogUtil.error(TAG, 'onFoldStatusChange callback error');
      await this.destroyPreviewWindow(true);
    } catch (error) {
      LogUtil.info(TAG, 'onFoldStatusChange callback error' + error);
    }
  }

  async initPreviewImage() {
    this.setIsCaptureFullOfScreen(PcRecordManager.getInstance().isBCRecord());
    await super.initPreviewImage();
  }

  /**
   * 覆写父类
   */
  public regisFoldStatueChange() {
    try {
      display.on('foldStatusChange', this.onPcFoldStatusChange);
    } catch (error) {
      LogUtil.error(`regisFoldStatueChange. message: ${error?.message}, code: ${error?.code}`);
    }
  }

  /**
   * 覆写父类
   */
  public unregisterFoldStatueChange() {
    try {
      display.off('foldStatusChange', this.onPcFoldStatusChange);
    } catch (error) {
      LogUtil.error(`unregisterFoldStatueChange. message: ${error?.message}, code: ${error?.code}`);
    }
  }

  /**
   * Destroy Preview Window with Animation
   */
  async destroyPreviewWindow(isPostKill: boolean = true): Promise<void> {
    LogUtil.info(TAG, 'destroyPreviewWindow start');
    try {
      this.unregisterFoldStatueChange();
      const previewWindow = this.getPreviewWindow();
      const previewWindowContext = previewWindow.getUIContext();
      const subWindow = this.getSubWindow();
      await previewWindow.setWindowTouchable(false);
      previewWindow.translate({ x: 0 });
      performanceMonitor.begin('SCREENRECORD_DISMISS_ANIMATION', performanceMonitor.ActionType.LAST_UP);
      previewWindowContext.animateTo({
        duration: MOVE_OUT_DURATION,
        curve: Curve.Friction,
        playMode: PlayMode.Normal,
        onFinish: (): void => {
          LogUtil.debug(TAG, 'Animation move-out is over.');
        },
      }, (): void => {
        previewWindow.translate({ x: this.isRTL() ? -this.getDistanceToLeftEdge() : this.getDistanceToLeftEdge() });
      });

      previewWindow.opacity(FADE_OUT_OPACITY_START);
      previewWindowContext.animateTo({
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

  /**
   * Move preview window
   *
   * @param coordinateX
   * @param coordinateY
   */
  async movePreviewWindow(coordinateX: number): Promise<void> {
    try {
      if (!this.getIsAnimating()) {
        const dftDisplay: display.Display | undefined = ExpansionScreenUtil.getSelectDisplay();
        if (dftDisplay === undefined) {
          return;
        }
        const previewWindow = this.getPreviewWindow();
        const distanceToEdge = dftDisplay.width - this.getInitialPreviewPosX() - this.getThumbWidth();
        previewWindow?.translate({ x: this.isRTL() ? coordinateX - distanceToEdge : coordinateX });
        LogUtil.info(TAG, 'Move preview window');
      }
    } catch (error) {
      LogUtil.error(TAG, 'Failed to move the preview window with reason:', (error as BusinessError).message);
    }
  }

  /**
   * 停止移动预览窗
   *
   * @param movingSpeed 移动速度
   */
  async stopMovingPreviewWindow(movingSpeed: number): Promise<void> {
    const previewWindow = this.getPreviewWindow();
    const subWindow = this.getSubWindow();
    const displacement = this.getPreviewPosX()!.get() - this.getInitialPreviewPosX();
    LogUtil.debug(TAG, `moving speed ${movingSpeed}, moving displacement: ${displacement}`);
    if (Math.abs(displacement) > MOVEOUT_THRESHOLD) {
      this.setIsAnimating(true);
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
          this.setIsAnimating(false);
          AppStorage.setOrCreate<boolean>('isAnimating', false);
          RecorderUtil.postKillProcessMessage();
        },
      }, (): void => {
        previewWindow.translate({ x: displacement > 0 ? -this.getDistanceToLeftEdge() : this.getDistanceToLeftEdge() });
        previewWindow.opacity(FADE_OUT_OPACITY_END);
      });
      return;
    }

    LogUtil.debug(TAG, `Animation move-back in stopMovingWindow is started.`);
    animateTo({
      curve: curves.interpolatingSpring(movingSpeed, SPRING_MASS, SPRING_STIFFNESS, SPRING_DAMPING),
      playMode: PlayMode.Normal,
      onFinish: (): void => {
        this.setIsAnimating(false);
        LogUtil.debug(TAG, `Animation move-back in stopMovingWindow is over.`);
      },
    }, (): void => {
      previewWindow.translate({ x: 0 });
      this.getPreviewPosX()!.set(this.getInitialPreviewPosX());
    });
  }

  /**
   * 检查隐私窗,新增PC特有判断
   */
  async checkHasPrivateWindow(): Promise<void> {
    const isBCRecord = PcRecordManager.getInstance().isBCRecord();
    if (isBCRecord) {
      LogUtil.warn(TAG, 'checkHasPrivateWindow B+C');
      this.checkHasPrivateWindowBC();
      return;
    }
    super.checkHasPrivateWindow();
  }

  async checkHasPrivateWindowBC(): Promise<void> {
    try {
      let displayB = display.getDisplayByIdSync(HPR_DISPLAY_ID_B);
      let displayC = display.getDisplayByIdSync(HPR_DISPLAY_ID_C);
      if (display.hasPrivateWindow(displayB.id) || display.hasPrivateWindow(displayC.id)) {
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
}