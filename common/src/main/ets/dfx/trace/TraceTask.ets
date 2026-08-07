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
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { LogUtil } from '../../util/LogUtil';

const TAG: string = 'Trace';

/**
 * Trace任务类
 */
export class Trace {
  private static taskId: number = 0;
  private static traceMap: Map<string, number> = new Map<string, number>();

  /**
   * 开始trace打点
   *
   * @param name 点位名称
   */
  public static begin(name: string): void {
    LogUtil.info(TAG, name + ' begin');
    Trace.traceMap.set(name, Trace.taskId);
    hiTraceMeter.startTrace(name, Trace.taskId++);
  }

  /**
   * 结束Trace点
   * @param name 点位名
   * @param id 点位id
   */
  public static end(name: string): void {
    if (Trace.traceMap.has(name)) {
      LogUtil.debug(TAG, name + ' end');
      hiTraceMeter.finishTrace(name, Trace.traceMap.get(name));
    } else {
      LogUtil.error(TAG, `trace name: ${name} not found, can not end`);
    }
  }
}

