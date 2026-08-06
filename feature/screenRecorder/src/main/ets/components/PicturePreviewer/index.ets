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
  ACTION_CLICK,
  CommonUtil,
  Constants,
  EVENT_NAME_HIDE_SCREENRECORD_THUMB,
  EVENT_NAME_PREVIEW_SCREENRECORD,
  EventReportUtil,
  GlobalThisUtil,
  LogUtil
} from '@ohos/common';
import lazy { StartOptions, wantConstant } from '@kit.AbilityKit';
import lazy { display, dragController } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import lazy UDC from '@ohos.data.unifiedDataChannel';
import lazy systemDateTime from '@ohos.systemDateTime';
import { DISAPPEAR_INTERVAL, WindowManager } from '../../manager';
import { COLOR_SHADOW, SELECT_DISPLAY_ID } from '../../manager/types';
import { RecorderUtil } from '../../util/RecorderUtil';
import { PreviewImage } from './PreviewImage';
import { ShareContent } from './ShareContent';
import { StopImage } from './StopImage';
import {
  Direction,
  FULL_CONTAINER_HEIGHT,
  FULL_CONTAINER_WIDTH,
  INITIAL_POSITION_X,
  SHADOW_BUTTON_COLOR_TV,
  SHADOW_OFFSET_X,
  SHADOW_OFFSET_Y,
  SHADOW_RADIUS,
  VIDEO_FORMAT,
  VIEW_DATA_ACTION
} from './types';

const TAG = 'PreviewPicture';

/**
 * Picture Previewer
 *
 * @since 2022-05-20
 */
@Component
export struct PicturePreviewer {
  @StorageLink('thumbnail') thumbnail: PixelMap | undefined = undefined;
  @StorageLink('previewPosX') winPosX: number = vp2px(INITIAL_POSITION_X);
  @StorageLink('borderColorOpacityValue') opacityValue: number = 0;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageProp('isPreviewDisabled') isPreviewDisabled: boolean = true;
  @StorageLink('isAnimating') isAnimating: boolean = false;
  @StorageLink('thumbWidth') thumbWidth: number = 270;
  @StorageLink('thumbHeight') thumbHeight: number = 626;
  @State private isDrag: boolean = false;
  @State private isDragStart: boolean = false;
  private preX: number = 0;
  private preY: number = 0;
  private curX: number = 0;
  private curY: number = 0;
  private startX: number = 0;
  private startY: number = 0;
  private isMoved: boolean = false;
  private moveDirection: Direction = Direction.LEFT;
  private isClick: boolean = false;
  private isHover: boolean = false;
  private isTv: boolean = CommonUtil.checkIfDeviceIsTv();
  private movingSpeed: number = 0;
  private preTime: number = 0;
  private videoUri: string | undefined = '';
  private globalThisInstance: GlobalThisUtil = GlobalThisUtil.getInstance();
  private windowManagerInstance: WindowManager = WindowManager.getInstance();
  private shadowOptions: ShadowOptions = {
    radius: SHADOW_RADIUS,
    color: COLOR_SHADOW,
    offsetX: SHADOW_OFFSET_X,
    offsetY: SHADOW_OFFSET_Y
  }
  private shadowOptionsTv: ShadowOptions = {
    radius: SHADOW_RADIUS,
    color: SHADOW_BUTTON_COLOR_TV,
    offsetX: SHADOW_OFFSET_X,
    offsetY: SHADOW_OFFSET_Y
  }

  aboutToAppear(): void {
    try {
      let displayId = this.globalThisInstance.getObject(SELECT_DISPLAY_ID);
      const dftDisplay =
        displayId != undefined ? display.getDisplayByIdSync(displayId as number) : display.getDefaultDisplaySync()
      const dftDisplayWidth = dftDisplay.width;
      LogUtil.info(TAG, 'aboutToAppear');
      this.winPosX = this.windowManagerInstance.isRTL() ? dftDisplayWidth - this.thumbWidth - vp2px(INITIAL_POSITION_X)
        : vp2px(INITIAL_POSITION_X);
      this.videoUri = AppStorage.Get('videoUri');
    } catch (err) {
      LogUtil.error(TAG, 'preview aboutToAppear getDefaultDisplaySync fail, err:' + (err as BusinessError).message);
    }
  }

  dragOrMoveOnRight() {
    if (!this.windowManagerInstance.isRTL()) {
      this.moveWindow();
    } else {
      this.dragWindow();
    }
  }

  dragOrMoveOnLeft() {
    if (!this.windowManagerInstance.isRTL()) {
      this.dragWindow();
    } else {
      this.moveWindow();
    }
  }

  private async updateActionMove(event: GestureEvent): Promise<void> {
    // Cancel the auto-disappearing countdown while touching the window.
    CommonUtil.clearPreviewTimeout();

    // Get current location
    this.curX = event.offsetX;
    this.curY = event.offsetY;
    LogUtil.info(TAG, `curX: ${this.curX}, curY: ${this.curY}`);

    // Determine the movement direction.
    if (Math.abs(this.curX - this.preX) <= Math.abs(this.curY - this.preY)) {
      // Y-direction movement, no response
      LogUtil.info(TAG, 'move Y direction');
    } else {
      this.isMoved = true;
      LogUtil.info(TAG, 'move X direction');
      this.moveDirection = this.curX > 0 ? Direction.RIGHT : Direction.LEFT;
      if (this.curX > 0) {
        if (CommonUtil.checkIfDeviceIsPC()) {
          this.dragOrMoveOnRight();
        } else {
          this.moveWindow();
        }
      } else {
        if (CommonUtil.checkIfDeviceIsPC()) {
          this.dragOrMoveOnLeft();
        } else {
          this.moveWindow();
        }
      }
    }
    // Record the last coordinate.
    this.preX = this.curX;
    this.preY = this.curY;
    this.preTime = await systemDateTime.getCurrentTime();
  }

  private moveWindow(): void {
    const offset = this.curX - this.preX;
    const endTime = new Date().getTime();
    const duration = endTime - this.preTime;
    if (duration !== 0) {
      this.movingSpeed = Math.abs(offset / duration);
    }
    this.winPosX += offset;
    this.windowManagerInstance.movePreviewWindow(this.winPosX);
  }

  private dragWindow(): void {
    if (this.isDrag) {
      return;
    }
    this.isDrag = true;
    let customBuilders: CustomBuilder[] | DragItemInfo[] = [];
    customBuilders.push(() => {
      this.buildContent(true);
    });
    let dragInfo: dragController.DragInfo = {
      pointerId: 0,
      data: this.buildUnifiedData(),
      extraParams: ''
    }
    let dragAction: dragController.DragAction | undefined;
    try {
      dragAction = dragController.createDragAction(customBuilders, dragInfo);
    } catch (err) {
      LogUtil.error(TAG, `createDragAction failed, code is ${err.code}`);
    }
    if (!dragAction) {
      LogUtil.error(TAG, `listener dragAction is null`);
      return;
    }
    dragAction.on('statusChange', (dragAndDropInfo: dragController.DragAndDropInfo) => {
      LogUtil.info(TAG, `Register to listen on drag status: ${dragAndDropInfo.status}`);
      if (dragAndDropInfo.status === dragController.DragStatus.STARTED) {
        this.windowManagerInstance.destroyPreWindow();
        RecorderUtil.postKillProcessMessage();
      }
    })
    dragAction.startDrag()
      .then(() => {
        LogUtil.info(TAG, 'startDrag success');
      })
      .catch((err: BusinessError) => {
        LogUtil.error(TAG, `dragAction startDrag failed, code is ${err.code}`);
      });
  }

  private preDragChange(preDragStatus: PreDragStatus): void {
    if (preDragStatus === PreDragStatus.READY_TO_TRIGGER_DRAG_ACTION) {
      this.isDrag = true;
      CommonUtil.clearPreviewTimeout();
    } else if (preDragStatus === PreDragStatus.PREVIEW_LANDING_FINISHED ||
      preDragStatus === PreDragStatus.ACTION_CANCELED_BEFORE_DRAG) {
      this.isDrag = false;
      const previewTimeoutId = setTimeout(() => this.windowManagerInstance.destroyPreviewWindow(), DISAPPEAR_INTERVAL);
      this.globalThisInstance!.setObject('previewTimeoutId', previewTimeoutId);
    } else {
      LogUtil.debug(TAG, 'other preDragStatus');
    }
  }

  private dragStart(event: DragEvent) {
    //Set the record video uri
    event.setData(this.buildUnifiedData());
    this.isDragStart = true;
    this.windowManagerInstance.hidePreviewWindow();
  }

  private buildUnifiedData(): UDC.UnifiedData {
    let video: UDC.Video = new UDC.Video();
    video.videoUri = AppStorage.Get('videoUri') as string;
    let data: UDC.UnifiedData = new UDC.UnifiedData(video);
    return data;
  }

  private dragEnd(): void {
    LogUtil.info(TAG, 'dragEnd and destroy preview window');
    this.windowManagerInstance.destroyPreWindow();
    RecorderUtil.postKillProcessMessage();
  }

  private async jumpToAlbum(): Promise<void> {
    const previewTimeoutId = this.globalThisInstance!.getObject('previewTimeoutId') as number;
    if (previewTimeoutId !== undefined) {
      clearTimeout(previewTimeoutId);
      this.globalThisInstance!.setObject('previewTimeoutId', undefined);
    }
    this.isClick = true;
    LogUtil.info(TAG, `start preview ability`);
    let wantData: Want = CommonUtil.checkIfDeviceIsPC() ? this.getHiPreviewWantData() : this.getWantData();
    LogUtil.debug(TAG, 'Data used to jump to album:', JSON.stringify(wantData));
    await this.windowManagerInstance.destroyPreviewWindow();
    await this.windowManagerInstance.destroyShareWindow();
    const context = this.globalThisInstance!.getObject('screenRecorderContext') as common.ServiceExtensionContext;
    let displayId = this.globalThisInstance.getObject(SELECT_DISPLAY_ID) as number;
    LogUtil.info(TAG, 'start photo displayId:' + displayId);
    let startOptions: StartOptions = {
      displayId: displayId
    }
    await context!.startAbility(wantData, startOptions);
  }

  private getWantData(): Want {
    const wantData: Want = {
      action: VIEW_DATA_ACTION,
      type: VIDEO_FORMAT,
      uri: this.videoUri,
      bundleName: 'com.ohos.photos',
      abilityName: 'com.ohos.photos.MainAbility',
    };
    return wantData;
  }

  private getHiPreviewWantData(): Want {
    const wantData: Want = {
      action: VIEW_DATA_ACTION,
      type: VIDEO_FORMAT,
      uri: this.videoUri,
      bundleName: 'com.ohos.hipreview',
      abilityName: 'MediaMainAbility',
      flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION | wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION
    };
    return wantData;
  }

  @Styles
  accessibilityStyle() {
    .accessibilityLevel(Constants.ACCESSIBILITY_LEVEL_YES)
  }

  @Builder
  buildContent(isDrag: boolean) {
    Stack() {
      PreviewImage();
      StopImage({
        stopImageWidth: CommonUtil.checkIfDeviceIsPhone() ? $r('app.float.icon_play_size') :
        $r('app.float.icon_play_size_pc'),
        stopImageHeight: CommonUtil.checkIfDeviceIsPhone() ? $r('app.float.icon_play_size') :
        $r('app.float.icon_play_size_pc')
      });
    }
    .width(`${this.thumbWidth}px`)
    .height(`${this.thumbHeight}px`)
    .shadow(isDrag ? null : this.isTv ? this.shadowOptionsTv : this.shadowOptions)
    .borderRadius(CommonUtil.checkIfDeviceIsPhone() ? $r('app.float.default_corner_radius_s') :
    $r('app.float.pc_corner_radius_s'))
    .backgroundColor(Color.Transparent)
    .accessibilityStyle()
    .draggable(!CommonUtil.checkIfDeviceIsPC())
    .dragPreviewOptions({ mode: DragPreviewMode.DISABLE_SCALE })
    .onPreDrag((status: PreDragStatus) => this.preDragChange(status))
    .onDragStart((event) => this.dragStart(event))
    .onDragEnd(() => this.dragEnd())
    .dragPreview(isDrag ? null : this.buildContent(true))
    .onAccessibilityHover(()=>{
      CommonUtil.broadcastAccessibilityText(this.getStringSafe($r('app.string.preview_image_accessibility_text')));
    })
    .gesture(GestureGroup(
      GestureMode.Exclusive,
      TapGesture().onAction(() => this.tapGesture()),
      PanGesture()
        .onActionStart(async (event: GestureEvent | undefined) => this.onPanGestureActionStart(event))
        .onActionUpdate((event: GestureEvent) => this.updateActionMove(event))
        .onActionEnd(async () => this.onPanGestureActionEnd())
    ))
    .onHover((isHover: boolean | undefined) => this.onHoverAction(isHover))
    .id('id_preview_card')
  }

  build() {
    Column({ space: 16 }) {
      this.buildContent(false);
      if (!CommonUtil.checkIfDeviceIsPC()) {
        ShareContent();
      }
    }
    .visibility(this.isDragStart ? Visibility.Hidden : Visibility.Visible)
    .width(FULL_CONTAINER_WIDTH)
    .height(FULL_CONTAINER_HEIGHT)
    .backgroundColor(Color.Transparent)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  private tapGesture(): void {
    if (this.isPreviewDisabled) {
      return;
    }
    if (this.isAnimating) {
      LogUtil.info(TAG, 'performing animation, skip jump to album');
      return;
    }
    EventReportUtil.reportEvent(EVENT_NAME_PREVIEW_SCREENRECORD,
      { 'ACTION': ACTION_CLICK });
    this.jumpToAlbum();
  }

  private async onPanGestureActionStart(event: GestureEvent | undefined): Promise<void> {
    this.startX = event!.offsetX;
    this.startY = event!.offsetY;
    this.preX = this.startX;
    this.preY = this.startY;
    this.preTime = await systemDateTime.getCurrentTime();
  }

  private async onPanGestureActionEnd(): Promise<void> {
    this.isDrag = false;
    CommonUtil.clearPreviewTimeout();
    if (this.isMoved && !this.isClick) {
      LogUtil.info(TAG, 'isMoved');
      EventReportUtil.reportEvent(EVENT_NAME_HIDE_SCREENRECORD_THUMB,
        { 'TYPE': this.moveDirection });
      await this.windowManagerInstance.stopMovingPreviewWindow(this.movingSpeed);
    }
    if (!this.isHover) {
      LogUtil.info(TAG, 'current is not hover');
      const previewTimeoutId = setTimeout(() => this.windowManagerInstance.destroyPreviewWindow(), DISAPPEAR_INTERVAL);
      this.globalThisInstance!.setObject('previewTimeoutId', previewTimeoutId);
    }
  }

  private async onHoverAction(isHover: boolean | undefined): Promise<void> {
    this.isHover = isHover!;
    if (isHover) {
      LogUtil.info(TAG, `onHoverAction, clear preview timeout`);
      CommonUtil.clearPreviewTimeout();
    } else {
      const previewTimeoutId = setTimeout(() => this.windowManagerInstance.destroyPreviewWindow(), DISAPPEAR_INTERVAL);
      this.globalThisInstance!.setObject('previewTimeoutId', previewTimeoutId);
      LogUtil.info(TAG, `set a new timeout with id ${previewTimeoutId}`);
    }
  }

  private getStringSafe(resource: Resource): string {
    try {
      return getContext().resourceManager.getStringSync(resource.id);
    } catch (error) {
      LogUtil.error(TAG, `Failed to get string resource: ${error}`);
      return '';
    }
  }
}
