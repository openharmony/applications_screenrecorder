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
import common from '@ohos.app.ability.common';
import deviceInfo from '@ohos.deviceInfo';
import display from '@ohos.display';
import I18n from '@ohos.i18n';
import statfs from '@ohos.file.statvfs';
import screenLock from '@ohos.screenLock';
import { sim } from '@kit.TelephonyKit';
import systemParameterEnhance from '@ohos.systemParameterEnhance';
import settings from '@ohos.settings';
import systemDateTime from '@ohos.systemDateTime';
import UDC from '@ohos.data.unifiedDataChannel';
import { vibrator } from '@kit.SensorServiceKit';
import window from '@ohos.window';
import { DisplayUtil, GlobalContext, GlobalThisHelper } from '.';
import { LogUtil } from './LogUtil';
import {
  KEY_CONTENT_WIDTH,
  KEY_CONTENT_HEIGHT,
  KEY_WINDOW_WIDTH,
  BREAKPOINT_LG,
  BREAKPOINT_MD,
  BREAKPOINT_SM,
  BREAKPOINT_XS,
  RANGE_LG,
  RANGE_MD,
  RANGE_SM,
  KEY_WINDOW_HEIGHT,
  BREAKPOINT_LG_SM,
  BREAKPOINT_MD_SM,
  BREAKPOINT_MD_LG,
  BREAKPOINT_MD_MD,
  BREAKPOINT_SM_LG,
  LEM_DEVICE_FOLD_TYPE,
  BREAKPOINT_SM_SM,
  BREAKPOINT_SM_MD,
  GRL_DEVICE_FOLD_TYPE,
} from '../types';

const TAG: string = 'Common_Util';
const DEVICE_TYPE_PHONE: string = 'phone';
const DEVICE_TYPE_PC: string = '2in1';
const DEVICE_TYPE_TABLET: string = 'tablet';
const FOLD_STATUS_EXPANDED: number = 1;
const FOLD_STATUS_FOLDED: number = 2;
const FOLD_STATUS_HALF_FOLDED: number = 3;
const FOLD_DISPLAY_MODE_FULL: number = 1;
const FOLD_DISPLAY_MODE_MAIN: number = 2;
const FOLD_DISPLAY_MODE_SUB: number = 3;
const FOLD_DISPLAY_MODE_COORDINATION: number = 4;
const DEFAULT_RATIO: number = 1;
const TYPE_CUT: string = 'cut';
const TYPE_TRUE: string = 'true';
const VIBRATOR_EFFECT_SOFT: string = 'haptic.effect.soft';
const FOLD_PRODUCT_TYPE_KEY: string = 'const.window.foldscreen.type';
const NEW_FOLD_DEVICE_FOLD_TYPE: string = '4,2,0,0';
const DISPLAY_ID: number = 1000;
// 表达式栏位置根据非多窗指定
const POSITION_ORIGIN: number = 1;
// 表达式栏位置在按钮左侧
const POSITION_LEFT: number = 2;
// 表达式栏位置在按钮下方
const POSITION_BOTTOM: number = 3;
const vibratorEffect: vibrator.VibratePreset = {
  type: 'preset',
  effectId: VIBRATOR_EFFECT_SOFT,
  count: 1,
};
const vibrateAttribute: vibrator.VibrateAttribute = {
  id: 0,
  usage: 'unknown',
};
// 系统剩余空间安全值128MB
const SYSTEM_SAFE_FREE_SIZE: number = 128 * 1024 * 1024;

export interface ICurrentWindow {
  width: number;
  height: number;
  displayId: number | undefined;
  isLayoutFullScreen: boolean;
};

// md_md 断点下获取当前模式下相关参数
export interface LayoutParameter {
  paddingSingle: number;
  paddingLeftRight: number;
  topGapRatio: number;
  leftGapRatio: number;
  panelGap: number;
  colCnt: number;
  rowCnt: number;
  rowGapCnt: number;
  colGapCnt: number;
  sciColCnt: number;
  sciColGapCnt: number;
  staColCnt: number;
  staColGapCnt: number;
};

// md_md 断点下科学区域三列
export enum ScienceLayoutMode {
  DEFAULT = 0, // 初始值
  LEFT = 1, // 最左边一列
  MIDDLE = 2, // 中间一列
  RIGHT = 3, // 最右边一列
  MEMORY = 4, // 标准区m行
};

// PC端计算器模式记录
export enum PCCalculatorMode {
  DEFAULT = 0,
  STANDARD = 1,
  STANDARD_HISTORY = 2,
  SCIENCE = 3,
  SCIENCE_HISTORY = 4,
};

// 断点下获取当前模式下相关参数
export interface PCLayoutPar {
  paddingSingle: number;
  paddingLeftRight: number;
  panelHeight: number;
  panelGap: number;
};

/**
 * Common Util
 *
 * @since 2025-04-23
 */
export class CommonUtil {
  /**
   * Check whether the current device is a mobile phone.
   *
   * @return {boolean} Whether the current device is a mobile phone.
   */
  static checkIfDeviceIsPhone(): boolean {
    return deviceInfo.deviceType === DEVICE_TYPE_PHONE;
  }

  /**
   * Check whether the phone is foldable.
   *
   * @return {boolean} Whether the phone is foldable.
   */
  static checkIfDeviceIsFold(): boolean {
    try {
      return display.isFoldable();
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(TAG, `checkIfDeviceIsFold failed: ${err.code}: ${err.message}`);
      return false;
    }
  }

  /**
   * Check whether the foldable phone is expanded.
   *
   * @return {boolean} Whether the foldable phone is expanded.
   */
  static checkFoldIsExpanded(): boolean {
    try {
      return display.getFoldStatus() === FOLD_STATUS_EXPANDED;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(TAG, `checkFoldIsExpanded getFoldStatus failed: ${err.code}: ${err.message}`);
      return false;
    }
  }

  /**
   * Check whether the foldable phone is folded.
   *
   * @return {boolean} Whether the foldable phone is folded.
   */
  static checkFoldIsFolded(): boolean {
    try {
      return display.getFoldStatus() === FOLD_STATUS_FOLDED;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(TAG, `checkFoldIsFolded getFoldStatus failed: ${err.code}: ${err.message}`);
      return false;
    }
  }

  /**
   * 是否可折叠
   *
   * @returns true：可折叠;false:非折叠屏
   */
  static getIsFoldAble(): boolean {
    try {
      return display.isFoldable();
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(TAG, `getIsFoldAble failed: ${err.code}: ${err.message}`);
      return false;
    }
  }

  /**
   * 折叠状态
   *
   * @returns FOLD_STATUS_UNKNOWN = 0:未知状态;FOLD_STATUS_EXPANDED：折叠屏展开态；
   *          FOLD_STATUS_HALF_FOLDED：折叠状态半折叠；FOLD_STATUS_FOLDED：折叠态
   */
  static getFoldStatus(): number {
    try {
      return display.getFoldStatus();
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(TAG, `getFoldStatus failed: ${err.code}: ${err.message}`);
      return 0;
    }
  }

  /**
   * Check whether the foldable phone is half-folded.
   *
   * @return {boolean} Whether the foldable phone is half-folded.
   */
  static checkFoldIsHalfFolded(): boolean {
    try {
      return display.getFoldStatus() === FOLD_STATUS_HALF_FOLDED;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(TAG, `checkFoldIsHalfFolded getFoldStatus failed: ${err.code}: ${err.message}`);
      return false;
    }
  }

  /**
   * 获取折叠屏是否是全屏状态
   *
   * @return true 全屏 ,  false 非全屏.
   */
  static checkFoldIsFull(): boolean {
    return display.getFoldDisplayMode() === FOLD_DISPLAY_MODE_FULL;
  }

  /**
   * 获取折叠屏是否是主屏状态
   *
   * @return true 主屏 ,  false 非主屏.
   */
  static checkFoldIsMain(): boolean {
    return display.getFoldDisplayMode() === FOLD_DISPLAY_MODE_MAIN;
  }

  /**
   * 获取折叠屏是否是副屏状态
   *
   * @return true 副屏 ,  false 非副屏.
   */
  static checkFoldIsSub(): boolean {
    return display.getFoldDisplayMode() === FOLD_DISPLAY_MODE_SUB;
  }

  /**
   * 获取折叠屏是否是协同状态
   *
   * @return true 协同 ,  false 非协同.
   */
  static checkFoldIsCoordination(): boolean {
    return display.getFoldDisplayMode() === FOLD_DISPLAY_MODE_COORDINATION;
  }

  /**
   * Check whether the current device is a pc.
   *
   * @return {boolean} Whether the current device is a pc.
   */
  static checkIfDeviceIsPC(): boolean {
    return deviceInfo.deviceType === DEVICE_TYPE_PC;
  }

  /**
   * Check whether the current device is a tablet.
   *
   * @return {boolean} Whether the current device is a tablet.
   */
  static checkIfDeviceIsTablet(): boolean {
    return deviceInfo.deviceType === DEVICE_TYPE_TABLET;
  }

  /**
   * 是否按平板界面显示
   *
   * @param {string} 断点
   * @return {boolean} 是否按平板界面显示
   */
  static shouldShowTabletUI(bp: string): boolean {
    return CommonUtil.checkIfDeviceIsTablet() || bp === BREAKPOINT_MD_LG || bp === BREAKPOINT_LG_SM;
  }

  /**
   * 获取是否是展开
   *
   * @return true 展开 ,  false 折叠.
   */
  static isUnfold(): boolean {
    try {
      let foldStatus: number = display.getFoldStatus();
      return foldStatus === FOLD_STATUS_EXPANDED || foldStatus === FOLD_STATUS_HALF_FOLDED;
    } catch (error) {
      LogUtil.error(TAG, 'get fold status ', error.message);
      return false;
    }
  }

  public static isRTL(): boolean {
    return I18n.isRTL(I18n.System.getSystemLocale());
  }

  public static isLandSpace(): boolean {
    try {
      let curOrientation: display.Orientation = display.getPrimaryDisplaySync().orientation;
      return curOrientation === display.Orientation.LANDSCAPE ||
        curOrientation === display.Orientation.LANDSCAPE_INVERTED;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(TAG, `isLandSpace curOrientation failed: ${err.code}: ${err.message}`);
      return false;
    }
  }

  public static setContentWidth(num: number): void {
    GlobalThisHelper.set(KEY_CONTENT_WIDTH, num);
  }

  public static getContentWidth(): number {
    return GlobalThisHelper.get<number>(KEY_CONTENT_WIDTH, 0);
  }

  public static setContentHeight(num: number): void {
    GlobalThisHelper.set(KEY_CONTENT_HEIGHT, num);
  }

  public static getContentHeight(): number {
    return GlobalThisHelper.get<number>(KEY_CONTENT_HEIGHT, 0);
  }

  public static getDisPlayWidth(): number {
    try {
      return px2vp(display.getPrimaryDisplaySync().width);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(TAG, `getDisPlayWidth display failed: ${err.code}: ${err.message}`);
      return 0;
    }
  }

  public static getDisPlayHeight(): number {
    try {
      return px2vp(display.getPrimaryDisplaySync().height);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(TAG, `get DisPlayHeight failed: ${err.code}: ${err.message}`);
      return 0;
    }
  }

  public static getWindowWidth(): number {
    return GlobalThisHelper.get<number>(KEY_WINDOW_WIDTH, CommonUtil.getDisPlayWidth());
  }

  public static getWindowHeight(): number {
    return GlobalThisHelper.get<number>(KEY_WINDOW_HEIGHT, CommonUtil.getDisPlayHeight());
  }

  public static getTopSafeHeight(): number {
    return CommonUtil.getNumberFromAppStorage('topSafeHeight');
  }

  public static updateTopSafeHeight(safeHeight: number): void {
    AppStorage.setOrCreate('topSafeHeight', px2vp(safeHeight));
  }

  public static updateTopSafeHeightVp(safeHeight: number): void {
    AppStorage.setOrCreate('topSafeHeight', safeHeight);
  }

  public static getBottomSafeHeight(): number {
    return CommonUtil.getNumberFromAppStorage('bottomSafeHeight');
  }

  public static updateBottomSafeHeight(safeHeight: number): void {
    AppStorage.setOrCreate('bottomSafeHeight', px2vp(safeHeight));
  }

  public static updateBottomSafeHeightVp(safeHeight: number): void {
    AppStorage.setOrCreate('bottomSafeHeight', safeHeight);
  }

  /**
   * 获取分屏比例
   *
   * @param defaultDisplayWidth 屏幕宽度
   * @param defaultDisplayHeight 屏幕高度
   * @returns number 分屏比例
   */
  public static getScreenSplitRatio(defaultDisplayWidth: number, defaultDisplayHeight: number): number {
    let currentWindow: ICurrentWindow = CommonUtil.getWindowLimit();
    if (!currentWindow.isLayoutFullScreen) {
      try {
        if (defaultDisplayHeight === 0 || defaultDisplayWidth === 0) {
          LogUtil.error(TAG, 'defaultDisplaySize error.');
          return DEFAULT_RATIO;
        }
        let screenSplitRatio: number = currentWindow.height / defaultDisplayHeight;
        if (screenSplitRatio >= DEFAULT_RATIO) {
          screenSplitRatio = currentWindow.width / defaultDisplayWidth;
        }
        LogUtil.info(TAG, `screenSplitRatio: ${screenSplitRatio}`);
        return screenSplitRatio;
      } catch (error) {
        LogUtil.error(TAG, 'getScreenSplitRatio error.', error.message);
      }
    }
    return DEFAULT_RATIO;
  }

  public static checkIfMultiScreen(): boolean {
    if (CommonUtil.checkIfDeviceIsPC()) {
      return false;
    }
    return AppStorage.get('windowStatusType') === window.WindowStatusType.SPLIT_SCREEN ||
      AppStorage.get('windowStatusType') === window.WindowStatusType.FLOATING;
  }

  public static getWindowLimit(): ICurrentWindow {
    let currentWindow: ICurrentWindow = {
      width: 0,
      height: 0,
      displayId: 0,
      isLayoutFullScreen: true,
    }
    try {
      const stage: window.WindowStage = AppStorage.get<window.WindowStage>('windowStage') as window.WindowStage;
      let windowIns: window.Window = stage.getMainWindowSync();
      let windowProperties: window.WindowProperties = windowIns.getWindowProperties();
      currentWindow = {
        width: px2vp(windowProperties.windowRect.width),
        height: px2vp(windowProperties.windowRect.height),
        displayId: windowProperties.displayId === undefined ? 0 : windowProperties.displayId,
        isLayoutFullScreen: windowProperties.isLayoutFullScreen,
      }
    } catch (error) {
      LogUtil.error(TAG, `getWindowLimit failed: ${error?.code}`);
    }
    return currentWindow as ICurrentWindow;
  }

  public static verifyFloatingWindow(): boolean {
    let displayHeight: number = 0;
    let displayWidth: number = 0;
    if (CommonUtil.checkIfDeviceIsPC()) {
      return false;
    }
    try {
      displayHeight = px2vp(display.getPrimaryDisplaySync().height);
      displayWidth = px2vp(display.getPrimaryDisplaySync().width);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(TAG, `verifyFloatingWindow display failed: ${err.code}: ${err.message}`);
      return false;
    }
    let defaultDisplayHeight: number = displayHeight;
    let defaultDisplayWidth: number = displayWidth;
    let currentWindow: ICurrentWindow = CommonUtil.getWindowLimit();
    let displayIds: number | undefined = currentWindow.displayId;
    let isMoreDisplay: boolean = false;
    if (displayIds !== undefined && displayIds >= DISPLAY_ID) {
      isMoreDisplay = true;
    }
    if (defaultDisplayHeight !== currentWindow.height && defaultDisplayWidth !== currentWindow.width &&
      !isMoreDisplay) {
      return true;
    }
    return false;
  }

  public static updateWindowSize(windowSize: window.Size): void {
    const deviceType: string = deviceInfo.deviceType;
    let widthVp: number = px2vp(windowSize.width);
    let heightVp: number = px2vp(windowSize.height);
    CommonUtil.setWindowWidth(widthVp);
    CommonUtil.setWindowHeight(heightVp);
    let widthBp: string = CommonUtil.getCurrentBreakpoint(widthVp);
    let heightBp: string = CommonUtil.getCurrentBreakpoint(heightVp);
    let newBp: string = `${widthBp}_${heightBp}`;
    let longType: string = heightBp;
    let shortType: string = widthBp;
    if (!CommonUtil.checkIfMultiScreen()) {
      switch (deviceType) {
        case DEVICE_TYPE_PC: {
          break;
        }
        case DEVICE_TYPE_TABLET: {
          longType = BREAKPOINT_LG;
          shortType = BREAKPOINT_MD;
          break;
        }
        case DEVICE_TYPE_PHONE: {
          if (CommonUtil.isUnfold() && widthBp !== BREAKPOINT_SM && heightBp !== BREAKPOINT_SM) {
            longType = BREAKPOINT_MD;
            shortType = BREAKPOINT_MD;
          } else {
            longType = BREAKPOINT_MD;
            shortType = BREAKPOINT_SM;
          }
          break;
        }
        default: {
          break;
        }
      }
      newBp = heightVp < widthVp ? `${longType}_${shortType}` : `${shortType}_${longType}`;
    }
    newBp = CommonUtil.newBpException(newBp);
    CommonUtil.setCurBp(newBp);
  }

  public static newBpException(newBp: string): string {
    if (newBp === BREAKPOINT_LG_SM) {
      newBp = BREAKPOINT_MD_SM;
    }
    // 显示大小 调整到最小时折叠屏会出现md_md识别成md_lg情况
    if (CommonUtil.checkIfDeviceIsFold() && CommonUtil.checkFoldIsExpanded()) {
      if (newBp === BREAKPOINT_MD_LG) {
        newBp = BREAKPOINT_MD_MD;
      }
    }
    return newBp;
  }

  public static setCurBp(bp: string): void {
    AppStorage.setOrCreate('currentBreakPoint', bp);
  }

  public static setWindowWidth(width: number): void {
    GlobalThisHelper.set<number>(KEY_WINDOW_WIDTH, width);
  }

  public static setWindowHeight(height: number): void {
    GlobalThisHelper.set<number>(KEY_WINDOW_HEIGHT, height);
  }

  public static getCurBp(): string {
    let bp: string | undefined = AppStorage.get<string>('currentBreakPoint');
    return bp ? bp : '';
  }

  public static getCurrentBreakpoint(size: number): string {
    if (size >= RANGE_LG) {
      return BREAKPOINT_LG;
    } else if (size >= RANGE_MD) {
      return BREAKPOINT_MD;
    } else if (size >= RANGE_SM) {
      return BREAKPOINT_SM;
    } else {
      return BREAKPOINT_XS;
    }
  }

  public static getNumberFromAppStorage(key: string): number {
    let num: number | undefined = AppStorage.get<number>(key);
    if (num === undefined) {
      num = 0;
    }
    return num;
  }

  public static getTextInputOffset(): number {
    return CommonUtil.getNumberFromAppStorage('textInputIndex');
  }

  public static updateTextInputOffset(textInputOffset: number): void {
    AppStorage.setOrCreate('textInputIndex', textInputOffset);
  }

  public static getBooleanFromAppStorage(key: string): boolean {
    let num: boolean | undefined = AppStorage.get<boolean>(key);
    if (num === undefined) {
      num = false;
    }
    return num;
  }

  public static getScienceFlag(): boolean {
    return CommonUtil.getBooleanFromAppStorage('scienceFlag');
  }

  public static updateScienceFlag(scienceFlag: boolean): void {
    AppStorage.setOrCreate('scienceFlag', scienceFlag);
  }

  public static getCopyResult(): string {
    // 添加result全局变量
    return CommonUtil.getStringFromAppStorage('copyResult');
  }

  public static updateCopyResult(globalResult: string): void {
    AppStorage.setOrCreate('copyResult', globalResult);
  }

  public static getStringFromAppStorage(key: string): string {
    // 获取AppStorage里的string值
    let string: string | undefined = AppStorage.get<string>(key);
    if (string === undefined) {
      string = '';
    }
    return string;
  }

  /**
   * 将页面显示的光标位置转换为表达式的光标位置.
   *
   * @param displayExp 页面展示的表达式.
   * @param displayIndex 页面显示的光标位置
   * @returns 实际表达式的光标位置.
   */
  public static displayIndexToExpIndex(displayExp: string, displayIndex: number): number {
    let expIndex: number = displayIndex;
    for (let i = 0; i < displayIndex; i++) {
      if (displayExp.charAt(i) === ',') {
        expIndex--;
      }
    }
    return expIndex;
  }

  /**
   * 将实际表达式的光标位置转换为页面显示的光标位置.
   *
   * @param displayExp 实际的表达式.
   * @param displayIndex 实际表达式的光标位置
   * @returns 页面显示的光标位置.
   */
  public static expIndexToDisplayIndex(exp: string, expIndex: number): number {
    let displayExp: string = CommonUtil.getDisplayExp(exp);
    let cursorIndex: number = 0;
    let displayIndex: number = expIndex;
    for (let i = 0; i < displayExp.length; i++) {
      if (displayExp.charAt(i) === ',') {
        displayIndex++;
      } else {
        cursorIndex++;
      }
      if (cursorIndex >= expIndex) {
        break;
      }
    }
    if (displayExp.charAt(displayIndex) === ',') {
      displayIndex++;
    }
    return displayIndex;
  }

  /**
   * 如果在特殊字符串里粘贴数字，将光标位置重新计算
   *
   * @param 光标位置
   * @param 展示的字符串
   * @returns 重新计算后的光标位置
   */
  public static getSpecialIndex(index: number, value: string): number {
    let startIndex: number = index;
    for (let pIndex: number = startIndex; pIndex < value.length; pIndex++) {
      if (['a', 'c', 'o', 'n', 'l', 's', 'g', 't', 'i', '\u207B', '\u00B9', '('].includes(value[pIndex])) {
        index = pIndex + 1;
        if (value[pIndex] === '(') {
          break;
        }
      }
    }
    return index;
  }

  /**
   * 将表达式转换为用户界面展示的表达式.
   *
   * @param value 计算表达式.
   * @returns 用于页面展示的表达式.
   */
  public static getDisplayExp(value: string): string {
    const result: string = DisplayUtil.formatAddSeparator(value);
    return result;
  }

  /**
   * 粘贴插入位置及附近数字小数点判断及转换
   *
   * @param numberArr: 操作的字符数组
   * @param setIndex: 位置索引
   * @returns 插入后获取的字符串
   */
  public static splitNumber(numberArr: string[], setIndex: number): string {
    numberArr = CommonUtil.formatPasteNumber(numberArr, setIndex);

    // 将粘贴内容与前面的数字拼接并去除逗号和0
    let frontNum: string = '';
    if ((numberArr[setIndex].length > 1 && numberArr[setIndex][0] === '.') ||
      (numberArr[setIndex].length > 2 && numberArr[setIndex][0] === '-' && numberArr[setIndex][1] === '.')) {
      // 如果去小数操作后的字符串为'.xx'或者'-.xx'的形式
      if (setIndex === 0) {
        frontNum += numberArr[setIndex]
      } else {
        for (let i = 0; i <= setIndex; i++) {
          frontNum += numberArr[i].toString();
        }
      }
    } else if (numberArr[setIndex].includes('-')) {
      frontNum = CommonUtil.splitNumberWithMinus(numberArr, setIndex);
    } else {
      frontNum = CommonUtil.splitNumberWithoutMinus(numberArr, setIndex);
    }

    // 将粘贴内容后面的数字拼接并去除逗号
    let afterNum: string = '';
    for (let i = setIndex + 1; i < numberArr.length; i++) {
      afterNum += numberArr[i].toString();
    }
    afterNum = afterNum.replace(new RegExp(',', 'g'), '');
    return frontNum + afterNum;
  }

  /**
   * 将粘贴的数字去除小数点
   *
   * @param numberArr 操作的字符串数组
   * @param setIndex 位置索引
   * @returns 去除小数点后的字符串数组
   */
  private static formatPasteNumber(numberArr: string[], setIndex: number): string[] {
    if (numberArr[setIndex].indexOf('.') >= 0 && numberArr.indexOf('.') >= 0) {
      if (numberArr[setIndex].includes('-') && setIndex > numberArr.indexOf('.')) {
        // 如果粘贴内容包含负号，切在所在内容数字数组里的小数点后面，则不进行任何操作
      } else {
        numberArr[setIndex] = numberArr[setIndex].replace('.', '');
      }
    }
    return numberArr;
  }

  /**
   * 如果粘贴的内容包含符号-
   *
   * @param numberArr 操作的字符串数组
   * @param setIndex 字符索引位置
   * @returns 处理后的字符串
   */
  private static splitNumberWithMinus(numberArr: string[], setIndex: number): string {
    let frontNum: string = '';
    if (setIndex < numberArr.length - 1 && numberArr[setIndex + 1] === '.') {
      while (DisplayUtil.checkFrontZero(numberArr[setIndex])) {
        numberArr[setIndex] = numberArr[setIndex].replace('0', '');
      }
    } else {
      while (numberArr[setIndex][1] === '0') {
        numberArr[setIndex] = numberArr[setIndex].replace('0', '');
      }
    }
    for (let i = 0; i <= setIndex; i++) {
      frontNum += numberArr[i].toString();
    }
    return frontNum;
  }

  /**
   * 如果粘贴的内容为不带符号的纯数字
   *
   * @param numberArr 操作的字符串数组
   * @param setIndex 字符索引位置
   * @returns 处理后的字符串
   */
  private static splitNumberWithoutMinus(numberArr: string[], setIndex: number): string {
    let frontNum: string = '';
    if (setIndex === 0) {
      if (numberArr.length === 1 || (numberArr.length > 1 && numberArr[setIndex + 1] === '.')) {
        while (DisplayUtil.checkFrontZero(numberArr[setIndex])) {
          numberArr[setIndex] = numberArr[setIndex].replace('0', '');
        }
      } else {
        while (numberArr[setIndex][0] === '0') {
          numberArr[setIndex] = numberArr[setIndex].replace('0', '');
        }
      }
    }
    for (let i = 0; i <= setIndex; i++) {
      frontNum += numberArr[i].toString();
    }
    while (DisplayUtil.checkFrontZero(frontNum)) {
      frontNum = frontNum.replace('0', '');
    }
    return frontNum;
  }

  /**
   * 检查设备是否为小型设备
   *
   * @returns boolean
   */
  public static checkIfDeviceIsSM(): boolean {
    let bp: string = CommonUtil.getCurBp();
    return bp === BREAKPOINT_MD_SM || bp === BREAKPOINT_SM_LG;
  }

  /**
   * 是否是LEM折叠屏设备
   *
   * @returns true 是
   */
  public static isLEMDevice(): boolean {
    try {
      let foldType: string = systemParameterEnhance.getSync(FOLD_PRODUCT_TYPE_KEY, '');
      return foldType === LEM_DEVICE_FOLD_TYPE;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(TAG, `isLEMDevice failed, errorCode: ${err.code}, errorMessage: ${err.message}`);
      return false;
    }
  }

  /**
   * 是否是GRL折叠屏设备
   *
   * @returns true 是
   */
  public static isGRLDevice(): boolean {
    try {
      let foldType: string = systemParameterEnhance.getSync(FOLD_PRODUCT_TYPE_KEY, '');
      return foldType === GRL_DEVICE_FOLD_TYPE;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(TAG, `isGRLDevice failed, errorCode: ${err.code}, errorMessage: ${err.message}`);
      return false;
    }
  }

  /**
   * 长按删除震动
   */
  /* instrument ignore next */
  public static startLongPressDeleteVibration(): void {
    try {
      vibrator.isSupportEffect(VIBRATOR_EFFECT_SOFT, (err: BusinessError, state: boolean) => {
        if (err) {
          LogUtil.error(TAG, `not support vibrator effect err: ${err}`);
          return;
        }
        if (state) {
          vibrator.startVibration(vibratorEffect, vibrateAttribute, () => {
            LogUtil.info(TAG, 'Succeed in starting vibration');
          });
        }
        LogUtil.info(TAG, `Vibration state: ${state}`);
      });
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      LogUtil.error(TAG, `vibrator isSupportEffect error. Code: ${e.code}, message: ${e.message}`);
    }
  }

  /* instrument ignore next */
  public static getDataFromUdmfRetry(event: DragEvent, callback: (data: DragEvent) => void) {
    try {
      let data: UnifiedData = event.getData();
      if (!data) {
        return false;
      }
      let records: UDC.UnifiedRecord[] = data.getRecords();
      if (!records || records.length <= 0) {
        return false;
      }
      callback(event);
      return true;
    } catch (e) {
      LogUtil.error(`getData failed, code = ${e.code}, message = ${e.message}`);
      return false;
    }
  }

  /* instrument ignore next */
  public static getDataFromUdmf(event: DragEvent, callback: (data: DragEvent) => void) {
    if (CommonUtil.getDataFromUdmfRetry(event, callback)) {
      return;
    }
    setTimeout(() => {
      CommonUtil.getDataFromUdmfRetry(event, callback);
    }, 1500);
  }

  /**
   * type类型是否剪切
   *
   * @param value 操作的字符串
   * @param type 类型
   * @returns 是否剪切
   */
  public static isPastePressed(value: string, type: string): boolean {
    return type === TYPE_CUT && value.length > 0;
  }

  /**
   * globalExpression是否是空
   *
   * @param isPastePressed 是否粘贴
   * @returns 是否为空
   */
  public static checkPastePressed(isPastePressed: boolean): boolean {
    if (AppStorage.get<string>('globalExpression') === '') {
      CommonUtil.updateCopyResult('');
      AppStorage.set<string>('globalResult', '');
      return false;
    }
    return isPastePressed;
  }

  /**
   * 返回复制粘贴后最新的坐标
   *
   * @param value 待粘贴位置
   * @param index 索引
   * @param displayExpression 表达式
   * @returns 最新索引坐标
   */
  public static setFinalTextInputIndex(value: string, index: number, displayExpression: string): number {
    let trueIndex: number = CommonUtil.getTrueIndex(index, displayExpression);
    let globalExp: string = AppStorage.get<string>('globalExpression') ?? '';
    trueIndex = CommonUtil.displayIndexToExpIndex(displayExpression, trueIndex);
    let finalIndex: number = globalExp.length - trueIndex;
    // 定义粘贴位置附近的数字元素列表，记录粘贴内容在提取数字数组中的坐标位置，记录提取数字在原表达式中的头尾坐标
    let numberArr: string[] = [value];
    let valIndex: number = 0;
    let startIndex: number = 0;
    let endIndex: number = 0;
    for (let index: number = trueIndex - 1; index >= 0; index--) {
      if (DisplayUtil.isNumberOrPoint(globalExp[index])) {
        numberArr.unshift(globalExp[index]);
        valIndex++;
      } else {
        // 前面提取的元素不是数字之后，保存数字的前端坐标
        startIndex = index + 1;
        break;
      }
    }
    // 如果光标后是数字，则加入到list里
    for (let index: number = trueIndex; index < globalExp.length + 1; index++) {
      if (DisplayUtil.isNumberOrPoint(globalExp[index])) {
        numberArr.push(globalExp[index]);
      } else {
        // 后面提取的元素不是数字之后，保存数字的后端坐标
        endIndex = index;
        break;
      }
    }
    // 粘贴插入位置及附近数字小数点判断及转换
    let splitNumber: string = CommonUtil.splitNumber(numberArr, valIndex);
    // 将表达式拼接起来，数字前的表达式+粘贴内容与前面的数字+粘贴内容后面的数字+数字后面的表达式
    let newEXPString: string = globalExp.slice(0, startIndex) + splitNumber + globalExp.slice(endIndex);
    newEXPString = newEXPString.replace('--', '-').replace('+-', '-');
    // 设置光标位置：表达式总长-插入位置后面的表达式的长度
    let finalTextInputIndex: number = CommonUtil.expIndexToDisplayIndex(newEXPString, newEXPString.length - finalIndex);
    // 更新表达式和光标位置
    AppStorage.set<string>('globalExpression', newEXPString);
    CommonUtil.updateTextInputOffset(finalTextInputIndex);
    return finalTextInputIndex;
  }

  /**
   * 如果是在特殊表达式中间需要插入到（后面
   *
   * @param index 索引
   * @param displayExpression 表达式
   * @returns 最终索引
   */
  public static getTrueIndex(index: number, displayExpression: string): number {
    let trueIndex: number = index;
    if (displayExpression !== '' && displayExpression !== null && trueIndex > 0) {
      if (['a', 'c', 'o', 'n', 'l', 's', 'g', 't', 'i', '\u207B',
        '\u00B9'].includes(displayExpression[trueIndex - 1])) {
        trueIndex = CommonUtil.getSpecialIndex(trueIndex, displayExpression);
      }
    }
    return trueIndex;
  }

  /**
   * 获取settings数据（同步方法）
   * @param taskContext Context
   * @param name 名称
   * @param defValue 默认值
   * @return 值
   */
  public static getScreenReaderValueSync(taskContext: Context, name: string, defValue: string): boolean {
    LogUtil.info('getScreenReaderValueSync start');
    if (!taskContext) {
      LogUtil.error(TAG, 'getScreenReaderValueSync context is null');
      return false;
    }
    try {
      let resultGlobal: string = settings.getValueSync(taskContext, name, defValue);
      LogUtil.info(TAG, `getScreenReaderValueSync global value: ${resultGlobal}`);
      return defValue === resultGlobal;
    } catch (err) {
      LogUtil.error(TAG, 'getScreenReaderValueSync Failed:', err.message);
      return false;
    }
  }

  /**
   * 获取屏幕朗读是否开启
   * @param taskContext Context
   * @param name 屏幕朗读开关值name
   * @param defValue 默认值
   * @param storageKey 屏幕朗读存储键值
   */
  public static async getBarrierFreeReading(
    taskContext: Context, name: string, defValue: string, storageKey: string): Promise<void> {
    LogUtil.info(TAG, 'getBarrierFreeReading start');
    if (!taskContext) {
      LogUtil.error(TAG, 'getBarrierFreeReading context is null');
      return;
    }
    settings.getValue(taskContext, name, settings.domainName.DEVICE_SHARED).then((value) => {
      AppStorage.setOrCreate(storageKey, value === defValue);
      LogUtil.info(TAG, `getBarrierFreeReading: ${AppStorage.get(storageKey)} Barrier status: ${value}`);
    }).catch((err: Error) => {
      LogUtil.error(TAG, 'getBarrierFreeReading fail: ', err?.message);
    });
  }

  /**
   * 监听屏幕朗读开启
   * @param taskContext Context
   * @param name 屏幕朗读开关值name
   * @param defValue 默认值
   * @param storageKey 屏幕朗读存储键值
   */
  public static async onBarrierFreeReading(
    taskContext: Context, name: string, defValue: string, storageKey: string): Promise<void> {
    LogUtil.info(TAG, 'onBarrierFreeReading start');
    if (!taskContext) {
      LogUtil.error(TAG, 'onBarrierFreeReading context is null');
      return;
    }
    try {
      settings.registerKeyObserver(taskContext, name, settings.domainName.DEVICE_SHARED, () => {
        let isOpen: string = settings.getValueSync(taskContext, name, settings.domainName.DEVICE_SHARED);
        LogUtil.info(TAG, `onBarrierFreeReading: ${isOpen}`);
        AppStorage.setOrCreate(storageKey, defValue === isOpen);
        LogUtil.info(TAG, `storageKey: ${AppStorage.get(storageKey)}`);
      });
    } catch (err) {
      LogUtil.error(TAG, 'onBarrierFreeReading Failed:', err.message);
    }
  }

  /**
   * 监听屏幕朗读关闭
   * @param taskContext Context
   * @param name 屏幕朗读开关值name
   */
  public static offBarrierFreeReading(taskContext: Context, name: string): void {
    LogUtil.info('offBarrierFreeReading start');
    if (!taskContext) {
      LogUtil.error(TAG, 'offBarrierFreeReading context is null');
      return;
    }
    try {
      let isOff: boolean = settings.unregisterKeyObserver(taskContext, name, settings.domainName.DEVICE_SHARED);
      LogUtil.info(TAG, `isOpenoffBarrierFreeReading: ${isOff}`);
    } catch (err) {
      LogUtil.error(TAG, 'offBarrierFreeReading Failed:', err.message);
    }
  }

  /**
   * 获取孩子模式是否开启
   * @param taskContext Context
   * @param name 健康使用设备开关值name
   * @param defValue 默认值
   */
  public static getHealthyUseStatus(taskContext: Context, name: string, defValue: string): string {
    LogUtil.info(TAG, 'getHealthyUseStatus start');
    if (!taskContext) {
      LogUtil.error(TAG, 'getHealthyUseStatus context is null');
      return defValue;
    }
    try {
      let switchStatus: string = defValue;
      if (CommonUtil.checkIfDeviceIsPC()) {
        switchStatus = settings.getValueSync(taskContext, name, defValue, settings.domainName.USER_PROPERTY);
      } else {
        switchStatus = settings.getValueSync(taskContext, name, defValue, settings.domainName.DEVICE_SHARED);
      }
      return switchStatus;
    } catch (err) {
      LogUtil.error(TAG, 'getHealthyUseStatus Failed:', err?.message);
      return defValue;
    }
  }

  /**
   * 退出自由多窗时加载主页(解决横屏标准计算器问题)
   * @param isFreeWindow 自由多窗开关值
   */
  /* instrument ignore next */
  public static loadMainPage(isFreeWindow: string): void {
    if (isFreeWindow === TYPE_TRUE) {
      return;
    }
    try {
      const stage: window.WindowStage = AppStorage.get<window.WindowStage>('windowStage') as window.WindowStage;
      stage.loadContent('pages/main', (err) => {
        if (err.code) {
          LogUtil.error(TAG, `Failed to load the content. Cause: ${err.message}`);
          return;
        }
        LogUtil.info(TAG, 'Succeeded in loading the content.');
      });
    } catch (err) {
      LogUtil.error(TAG, 'onFreeScreenEvent Failed:', err.message);
    }
  }

  /**
   * 监听自由多窗开启
   * @param taskContext Context
   * @param name 自由多窗开关值name
   * @param storageKey 自由多窗存储键值
   */
  public static async onFreeWindowEvent(taskContext: Context, name: string, storageKey: string): Promise<void> {
    LogUtil.info(TAG, 'onFreeScreenEvent start');
    if (!taskContext) {
      LogUtil.error(TAG, 'onFreeScreenEvent context is null');
      return;
    }
    try {
      settings.registerKeyObserver(taskContext, name, settings.domainName.USER_PROPERTY, () => {
        settings.getValue(taskContext, name, settings.domainName.USER_PROPERTY).then((value) => {
          AppStorage.setOrCreate(storageKey, value === TYPE_TRUE);
          LogUtil.info(TAG, `onFreeScreenEvent storageKey: ${AppStorage.get(storageKey)}`);
          CommonUtil.loadMainPage(value);
        });
      });
    } catch (err) {
      LogUtil.error(TAG, 'onFreeScreenEvent Failed:', err.message);
    }
  }

  /**
   * 获取自由多窗状态
   * @param taskContext Context
   * @param name 自由多窗开关值name
   * @param storageKey 自由多窗存储键值
   */
  public static async getFreeWindowStatus(taskContext: Context, name: string, storageKey: string): Promise<void> {
    if (!taskContext) {
      LogUtil.error(TAG, 'getFreeScreenStatus context is null');
      return;
    }
    try {
      settings.getValue(taskContext, name, settings.domainName.USER_PROPERTY).then((value) => {
        AppStorage.setOrCreate(storageKey, value === TYPE_TRUE);
        LogUtil.info(TAG, `getFreeScreenStatus: ${AppStorage.get(storageKey)} Free Window status: ${value}`);
      });
    } catch (err) {
      LogUtil.error(TAG, 'getFreeScreenStatus Failed:', err.message);
    }
  }

  /**
   * 监听自由多窗关闭
   * @param taskContext Context
   * @param name 自由多窗开关值name
   */
  public static offFreeWindowEvent(taskContext: Context, name: string): void {
    LogUtil.info('offFreeScreenEvent start');
    if (!taskContext) {
      LogUtil.error(TAG, 'offFreeScreenEvent context is null');
      return;
    }
    try {
      let isOff: boolean = settings.unregisterKeyObserver(taskContext, name, settings.domainName.USER_PROPERTY);
      LogUtil.info(TAG, `isOpenoffFreeScreenEvent: ${isOff}`);
    } catch (err) {
      LogUtil.error(TAG, 'offFreeWindowEvent Failed:', err.message);
    }
  }

  /**
   * 判断屏幕是否被锁定
   *
   * @return {boolean} 如果屏幕被锁定，返回true，否则返回false
   * @throws {BusinessError} 如果获取屏幕锁定状态失败，将抛出BusinessError异常
   */
  public static isScreenLocked(): boolean {
    let result: boolean = false;
    try {
      result = screenLock.isLocked();
    } catch (error) {
      LogUtil.error(TAG, `get screenLock state failed, error code: ${(error as BusinessError).code}`);
    }
    return result;
  }

  /**
   * 是否是XX折叠屏设备
   *
   * @returns true 是
   */
  public static isNewFoldDevice(): boolean {
    try {
      let foldType: string = systemParameterEnhance.getSync(FOLD_PRODUCT_TYPE_KEY, '');
      LogUtil.info(TAG, `current Display Type：`, foldType);
      return foldType === NEW_FOLD_DEVICE_FOLD_TYPE;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(TAG, `isXXdevice failed, errorCode: ${err.code}, errorMessage: ${err.message}`);
      return false;
    }
  }

  /**
   * 设置pad 自由多窗模式下，将最大化按钮隐藏
   *
   * @param isMax 最大化是否开启
   * @returns
   */
  public static setWindowTitleVisible(isMax: boolean): void {
    let windowStage: window.WindowStage | undefined = AppStorage.get<window.WindowStage>('windowStage');
    let mainWindow: window.Window | undefined = undefined;
    // 获取应用主窗口
    windowStage?.getMainWindow().then(
      data => {
        mainWindow = data;
        mainWindow.setTitleButtonVisible(isMax, true, false);
        LogUtil.info(TAG, `Succeeded setting the title Maximize visible: ${isMax}`);
      }
    ).catch((err: BusinessError) => {
      if (err.code) {
        LogUtil.error(TAG, `Failed to obtain the main window. Cause code: ${err.code}, message: ${err.message}`);
      }
    });
  }

  /**
   * 获取对应模式下表达式栏展示位置
   *
   * @param isMultiState 是否分屏
   * @returns
   */
  public static getPositionByTag(isMultiState: boolean): number {
    // 直扳机分屏1:2,1:1屏;直扳机横屏;折叠屏折叠态横屏;平板分屏1:2;显示在左边,其他一律底部 (GRL 全展开上下分屏1:1)
    // BREAKPOINT_LG_SM 对应pce自由多窗以及GRL 全展开上下分屏1:1
    let isFreeWindow: boolean = AppStorage.get('isFreeWindow') ?? false;
    let curBp: string = CommonUtil.getCurBp();
    if (curBp === BREAKPOINT_SM_SM || curBp === BREAKPOINT_MD_SM || curBp === BREAKPOINT_SM_MD ||
      (curBp === BREAKPOINT_LG_SM && isMultiState && !isFreeWindow)) {
      return POSITION_LEFT;
    } else {
      return POSITION_BOTTOM;
    }
  }

  /**
   * 设置窗口大小
   *
   * @param winWidth 待设置宽度
   * @param winHeight 待设置高度
   * @returns
   */
  public static reSizeWindow(winWidth: number, winHeight: number): void {
    let windowIns: window.Window | undefined = AppStorage.get('windowIns');
      if (windowIns !== undefined) {
        windowIns.resize(winWidth, winHeight).then(() => {
          LogUtil.info(TAG, 'Succeeded in changing the window size.');
        }).catch((err: BusinessError) => {
          LogUtil.error(TAG, `Failed to change the window size. Cause: ${err?.code}`);
        });
      }
  }

  /**
   * 当前系统可用存储空间是否低于安全值(安全值128MB)
   *
   * @returns true 低于安全值
   */
  public static isLowSystemSafeSpace(): boolean {
    try {
      let context: Context = GlobalContext.getContext().getObject('calculatorContext') as Context;
      if (context !== undefined) {
        let freeSize: number = statfs.getFreeSizeSync(context.databaseDir);
        LogUtil.info(TAG, `isLowSystemSafeSpace freeSize:${freeSize}`);
        return freeSize < SYSTEM_SAFE_FREE_SIZE;
      }
    } catch (error) {
      LogUtil.error(TAG, `isLowSystemSafeSpace failed, errorCode: ${error?.code}, errorMessage: ${error?.message}`);
    }
    return false;
  }

  /**
   * 获取当前设备卡槽数量
   *
   * @returns number 卡槽数量
   */
  public static getSimCount(): number {
    let simCount: number = 0;
    try {
      simCount = sim.getMaxSimCount();
    } catch (error) {
      LogUtil.error(TAG, `getSimCount failed, errorCode: ${error?.code}, errorMessage: ${error?.message}`);
    }
    return simCount;
  }
}