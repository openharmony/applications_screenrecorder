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

export {
  RecordManager,
  WindowManager,
  PREVIEW_WINDOW_NAME,
  CAPSULE_WINDOW_NAME,
  FreeScreenArea,
  NotificationManager,
  LIGHT_NOTIFICATION_COLOR,
  DARK_NOTIFICATION_COLOR,
  COLOR_TRANSPARENT,
  AI_TRIGGER_TYPE,
  SELECT_DISPLAY_ID,
  MicManager,
  AccessManager,
  RecorderFileManager,
  RecorderToast,
  PcRecordManager,
  PcWindowManager,
  INTENT_NAME_STOP,
  ERROR_CODE_NO_RECORDING,
  IntentStopRecordImpl,
} from './src/main/ets/manager';

export { SupportResolution } from './src/main/ets/manager/types';

export { Capsule } from './src/main/ets/components/Capsule';

export { ExpansionScreenUtil, ScreenData } from './src/main/ets/util/ExpansionScreenUtil';

export { PicturePreviewer } from './src/main/ets/components/PicturePreviewer';

export { PcPicturePreviewer } from './src/main/ets/components/PicturePreviewer/PcPicturePreviewer';

export { MaskPreviewer } from './src/main/ets/components/MaskPreviewer';

export { ControlPhone } from './src/main/ets/components/ScreenRecorderControlPage/ControlPhone';

export { RecorderUtil } from './src/main/ets/util/RecorderUtil';

export { PhoneRecorderConfig } from './src/main/ets/manager/config/PhoneRecorderConfigImpl';

export { PcRecorderConfig } from './src/main/ets/manager/config/PcRecorderConfigImpl';

export { PadRecorderConfig } from './src/main/ets/manager/config/PadRecorderConfigImpl';

export { PickerSelectWindowPage } from './src/main/ets/components/PickerSelectWindowPage/PickerSelectWindowPage';

export { CommonSelectPicker } from './src/main/ets/components/PickerSelectWindowPage/CommonSelectPicker';
