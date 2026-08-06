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

import { CommonUtil } from '@ohos/common/src/main/ets/util/CommonUtil';
import { DisplayUtil, DisplayId } from '@ohos/common/src/main/ets/util/DisplayUtil';
import { GlobalThisUtil } from '@ohos/common/src/main/ets/util/GlobalThisUtil';
import { LogUtil } from '@ohos/common/src/main/ets/util/LogUtil';
import lazy { display, screen } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { SELECT_DISPLAY_ID } from '../manager/types';

/* instrument ignore file */
const TAG = 'ExpansionScreenUtil';

/**
 * 从Screen中获取的有用字段
 */
export interface ScreenData {
  id: number,
  sourceMode: screen.ScreenSourceMode,
  rsId: number
}

/**
 * 扩展屏工具类
 *
 * @author caijiangtao
 * @since 2025-04-12
 */
export class ExpansionScreenUtil {
  private static readonly DEFAULT_RECT: display.Rect = {
    left: 0,
    top: 0,
    width: 0,
    height: 0
  };

  /**
   * 获取所有的Display，过滤掉镜像屏
   *
   * @returns 所有的display集合
   */
  public static async getAllDisplays(): Promise<display.Display[]> {
    // 如果需要更新，例如再次发起截屏。或者首次执行此方式是
    let mirrorIdArr: number[] = await ExpansionScreenUtil.getAllMirrorScreenId();
    let displays: display.Display[] = await display.getAllDisplays().catch((err: BusinessError) => {
      LogUtil.error(TAG, `getAllDisplays, failed, code is ${err?.code}, message is ${err?.message}`);
      return [];
    });
    // 虚拟display的ID大于等于1000，例如录屏胶囊就是一个虚拟display
    displays = displays.filter(display => display.id < DisplayId.VIRTUAL_DISPLAY_MIN_ID &&
      (mirrorIdArr.indexOf(display.id) === -1));
    return displays;
  }

  /**
   * 1.Hopper悬停态接扩展屏，上半屏和扩展屏显示不一样的提示语，下半屏不显示提示语
   * 2.Hopper全展态接扩展屏，两屏都显示一样的提示语
   *
   * @param displayId
   * @param displays
   * @returns 提示语
   */
  static getTextInSelectMask(displayId: number, displays: display.Display[]): Resource | undefined {
    if (ExpansionScreenUtil.isNormalHalfFoldedInner(displays)) {
      if (displayId === DisplayId.DEFAULT) {
        return $r('app.string.select_a_screen');
      } else if (displayId < DisplayId.LOWER_OF_FOLD_DEVICE) {
        return $r('app.string.select_this_display_to_recorder');
      } else {
        return undefined;
      }
    }
    return $r('app.string.select_this_display_to_recorder');
  }

  /**
   * 悬停态的C面（c面非磁吸键盘）, 半展态，并且有display的id是999的屏
   *
   * @param display 当前的display的id
   * @returns 是PC的悬停态
   */
  public static isLowerScreenOfNormalHalfFolded(displays: display.Display[], display: number | undefined): boolean {
    return display === DisplayId.LOWER_OF_FOLD_DEVICE && ExpansionScreenUtil.isNormalHalfFoldedInner(displays);
  }


  /**
   * 获取Hopper的铰链区域尺寸
   *
   * @returns 铰链区域
   */
  public static getCreaseRect(): display.Rect {
    let creaseData: display.FoldCreaseRegion | undefined = undefined;
    try {
      // 若不存在铰链区，接口返回undefined
      creaseData = display.getCurrentFoldCreaseRegion();
    } catch (error) {
      LogUtil.error(TAG, `getCreaseRect failed: { code: ${error?.code}, message: ${error?.message}}`);
    }
    if (creaseData && creaseData?.creaseRects?.length >= 1) {
      return creaseData.creaseRects[0];
    }
    return ExpansionScreenUtil.DEFAULT_RECT;
  }

  public static isCreaseExist(displayId: number): boolean {
    let creaseData: display.FoldCreaseRegion | undefined = undefined;
    try {
      // 若不存在铰链区，接口返回undefined
      creaseData = display.getCurrentFoldCreaseRegion();
    } catch (error) {
      LogUtil.error(TAG, `getCurrentFoldCreaseRegion failed: { code: ${error?.code}, message: ${error?.message}}`);
    }
    return creaseData?.displayId === DisplayId.DEFAULT && ExpansionScreenUtil.isHalfFoldedState() &&
      displayId === DisplayId.DEFAULT;
  }

  /**
   * 获取PC悬停态时, 中轴区和c面高度
   *
   * @returns 高度
   */
  public static getPcBCHeight(displays: display.Display[]): number {
    let rect: display.Rect | undefined = ExpansionScreenUtil.getCreaseRect();
    if (!rect) {
      LogUtil.warn(TAG, `getPcBCHeight failed, rect is null`);
      return 0;
    }
    if (!ExpansionScreenUtil.isNormalHalfFolded(displays)) {
      let upDisplay: display.Display | undefined =
        ExpansionScreenUtil.getDisplayByIdSync(DisplayId.DEFAULT);
      if (upDisplay !== undefined) {
        return upDisplay.height;
      } else {
        LogUtil.warn(TAG, `getPcBCHeight failed, upDisplay is null`);
        return 0;
      }
    }
    let upDisplay: display.Display | undefined =
      ExpansionScreenUtil.getDisplayByIdSync(DisplayId.DEFAULT);
    let downDisplay: display.Display | undefined =
      ExpansionScreenUtil.getDisplayByIdSync(DisplayId.LOWER_OF_FOLD_DEVICE);
    if (downDisplay !== undefined && upDisplay !== undefined) {
      return upDisplay.height + downDisplay.height + rect.height;
    } else if (downDisplay === undefined && upDisplay !== undefined) {
      return upDisplay.height;
    } else {
      LogUtil.warn(TAG, `getPcBCHeight failed, upDisplay is null`);
      return 0;
    }
  }

  private static getDisplayByIdSync(id: number): display.Display | undefined {
    let displayObj: display.Display | undefined = undefined;
    try {
      displayObj = display.getDisplayByIdSync(id);
    } catch (error) {
      LogUtil.error(TAG, `isHalfFoldedState failed: { code: ${error?.code}, message: ${error?.message}}`);
    }
    return displayObj;
  }

  /**
   * 获取PC悬停态时的画面宽度
   *
   * @returns 宽
   */
  public static getPcBCWidth(): number {
    let upDisplay: display.Display | undefined =
      ExpansionScreenUtil.getDisplayByIdSync(DisplayId.DEFAULT);
    return upDisplay !== undefined ? upDisplay.width : 0;
  }

  /**
   * 是否为折叠屏半展态, c面是磁吸键盘，虽然只有一个display，但是也是半展态。
   *
   * @returns true 是，false 不是
   */
  public static isHalfFoldedState(): boolean {
    return DisplayUtil.isHalfFoldedState();
  }

  /**
   * 是PC的悬停态,并且c面是虚拟键盘（这个场景，只有b面一个display，c面对应用层不可见），
   *
   * @returns 是PC的悬停态
   */
  public static isOneDisplayHalfFolderState(displays: display.Display[]): boolean {
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

  /**
   * 悬停态的B面（c面非磁吸键盘）, 半展态，并且有display的id是999的屏
   *
   * @param display 当前的display的id
   * @returns 是PC的悬停态
   */
  public static isUpScreenOfNormalHalfFolded(displays: display.Display[], display: number | undefined): boolean {
    return display === DisplayId.DEFAULT && ExpansionScreenUtil.isNormalHalfFolded(displays);
  }

  /**
   * 当前display布局是否包括铰链区域
   *
   * @param displayId display的Id
   * @returns 是否显示铰链区域
   */
  public static isCreaseExistOfDisplay(displayId: number): boolean {
    return displayId === DisplayId.DEFAULT && ExpansionScreenUtil.isCreaseExist(displayId);
  }

  /**
   * 是否显示选面面板
   *
   * @returns true 显示
   */
  public static isChosePanelEnable(displays: display.Display[]): boolean {
    return displays.length === 2 && ExpansionScreenUtil.isNormalHalfFoldedInner(displays);
  }

  /**
   * 是PC的悬停态,并且c面不是虚拟键盘,并且没接扩展屏
   *
   * @param displays 当前显示的display的集合
   * @returns true 是PC的悬停态,并且没接扩展屏
   */
  public static isNormalHalfFoldedWithoutExpansion(displays: display.Display[]): boolean {
    if (!displays || displays.length !== 2) {
      LogUtil.error(TAG, `isNormalHalfFoldedWithoutExpansion, displays is invalid.`);
      return false;
    }
    return ExpansionScreenUtil.isNormalHalfFoldedInner(displays);
  }

  /**
   * 获取镜像屏的id集合
   *
   * @returns 镜像屏的id
   */
  public static async getAllMirrorScreenId(): Promise<number[]> {
    let screenData: screen.Screen[] = await screen.getAllScreens().catch((err: BusinessError) => {
      LogUtil.error(TAG, `Failed to get all screens. code is ${err.code}, message is ${err.message}`);
      return [];
    });
    if (!screenData || screenData.length <= 1) {
      return [];
    }
    let mirrorIdArr: number[] = [];
    let i: number = 0;
    screenData.filter(data => (data && data.id < DisplayId.VIRTUAL_DISPLAY_MIN_ID))
      .filter(data => data.sourceMode === screen.ScreenSourceMode.SCREEN_MIRROR)
      .forEach(data => mirrorIdArr[i++] = data.id);
    return mirrorIdArr;
  }

  /**
   * 保存变化前的sourceMode，如果正在录屏的id的mode由扩展屏变成了镜像屏。则需停止录屏
   *
   * @param recorderId 正在录屏的id
   * @returns 查询的display的mode是否改变， true 改变了，false 没变
   */
  public static async getScreenModeMap(recorderId: number): Promise<Map<number, ScreenData>> {
    let screenMap: Map<number, ScreenData> = new Map<number, ScreenData>();
    let screenData: screen.Screen[] = await screen.getAllScreens().catch((err: BusinessError) => {
      LogUtil.error(TAG, `Failed to get all screens. code is ${err.code}, message is ${err.message}`);
      return [];
    });
    if (!screenData || screenData.length <= 1) {
      return screenMap;
    }
    screenData.filter((data) => {
      if (!data || data.id >= DisplayId.VIRTUAL_DISPLAY_MIN_ID) {
        return;
      }
      LogUtil.info(TAG, `reId ${recorderId}, id ${data.id}, mode ${data.sourceMode}`);
      screenMap.set(data.id, {
        id: data.id,
        sourceMode: data.sourceMode,
        rsId: data['rsId']
      });
    });
    return screenMap;
  }

  /**
   * 是否显示蒙层的提示语，分屏选面时，
   *
   * @param displayId
   * @returns true 显示蒙层里的提示语
   */
  public static isShowNoticeText(displays: display.Display[], displayId: number): boolean {
    if (!displays || displays.length == 0) {
      LogUtil.error(TAG, `isShowNoticeText, displays is invalid.`);
      return false;
    }
    if (ExpansionScreenUtil.isNormalHalfFolded(displays) && displayId === 0) {
      return true;
    }
    return CommonUtil.isExpandedDevice() && displays.length === 1;
  }

  /**
   * 获取选择录屏的display
   *
   * @returns 选中的，异常返回默认的
   */
  public static getSelectDisplay(): display.Display | undefined {
    try {
      let obj = GlobalThisUtil.getInstance().getObject(SELECT_DISPLAY_ID);
      if (obj != undefined) {
        const dftDisplay = display.getDisplayByIdSync(obj as number);
        return dftDisplay;
      }
    } catch (error) {
      LogUtil.warn(TAG, 'getDisplay failed, use default display');
    }
    try {
      // 异常时使用默认display
      return display.getDefaultDisplaySync();
    } catch (error) {
      LogUtil.warn(TAG, 'getDefaultDisplaySync failed');
    }
    return undefined;
  }

  /**
   * 是PC的悬停态,并且c面不是虚拟键盘
   *
   * @param displays 当前显示的display的集合
   * @returns true 是PC的悬停态
   */
  public static isNormalHalfFolded(displays: display.Display[]): boolean {
    if (!displays || displays.length == 0) {
      LogUtil.error(TAG, `isNormalHalfFolded, displays is invalid.`);
      return false;
    }
    return ExpansionScreenUtil.isNormalHalfFoldedInner(displays);
  }

  /**
   * 如果扩展模式改变，停止录屏
   */
  public static checkModeChanged(recorderId: number, modeMap: Map<number, ScreenData>,
    newModeMap: Map<number, ScreenData>): boolean {
    let newDate: ScreenData | undefined = newModeMap?.get(recorderId);
    let date: ScreenData | undefined = modeMap?.get(recorderId);
    if (!newDate || !date) {
      return false;
    }
    // 如果录屏的display的mode由扩展屏变成了镜像屏，就停止录屏
    if (newDate.sourceMode === screen.ScreenSourceMode.SCREEN_MIRROR &&
      date.sourceMode === screen.ScreenSourceMode.SCREEN_EXTEND) {
      LogUtil.info(TAG, 'stop when mirror mode changed');
      return true;
    }
    let newRsId: number | undefined = newDate?.rsId;
    let rsId: number | undefined = date?.rsId;
    // 如果录屏的display的mode由扩展屏变成了主屏，就停止录屏
    if (newRsId !== undefined && rsId !== undefined && newRsId !== rsId) {
      LogUtil.info(TAG, 'stop when main screen changed');
      return true;
    }
    return false;
  }

  private static isNormalHalfFoldedInner(displays: display.Display[]): boolean {
    if (!ExpansionScreenUtil.isHalfFoldedState()) {
      return false;
    }
    for (let display of displays) {
      if (display?.id === DisplayId.LOWER_OF_FOLD_DEVICE) {
        return true;
      }
    }
    return false;
  }
}
