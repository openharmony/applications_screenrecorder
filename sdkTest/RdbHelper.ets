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
import dataRdb from '@ohos.data.relationalStore';
import promptAction from '@ohos.promptAction';
import relationalStore from '@ohos.data.relationalStore';
import { CommonUtil } from '.';
import DB from '../data/TableData';
import { LooseObject } from '../data/LooseObject';
import { LogUtil } from './LogUtil';

const TAG: string = 'RdbHelper';
const RDB_ERROR_CODE: number = 14800011;
const RDB_IO_ERROR_CODE: number = 14800028;
const RDB_FULL_ERROR_CODE: number = 14800029;
const PROMPT_TIME: number = 2000;

/**
 * max count for history record
 */
const MAX_HISTORY_RECORD: number = 100;

/**
 * Database helper
 *
 * @since 2025-04-23
 */
export class RdbHelper {
  private static instance: RdbHelper;
  private rdbStore: relationalStore.RdbStore | null = null;
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  /**
   * private constructor()
   */
  private constructor() {
    this.getRdbStore();
  }

  /**
   * single instance
   *
   * @return instance
   */
  public static getInstance(): RdbHelper {
    if (RdbHelper.instance == null) {
      RdbHelper.instance = new RdbHelper();
    }
    return RdbHelper.instance;
  }

  /**
   * getRdbStore
   */
  async getRdbStore(errorCodeCallback?: Callback<number>): Promise<void> {
    //instrument ignore else
    if (this.rdbStore === null) {
      try {
        let rdbStoreV9: relationalStore.RdbStore =
          await relationalStore.getRdbStore(this.context, DB.STORE_CONFIGV9.config);
        rdbStoreV9.executeSql(DB.table.expression);
        this.rdbStore = rdbStoreV9;
        LogUtil.info(TAG, 'create table success');
      } catch (err) {
        LogUtil.info(TAG, 'create table fail: ', err?.message);
        let errorCode: number = (err as BusinessError).code;

        //instrument ignore if
        if (errorCode === RDB_IO_ERROR_CODE || errorCode === RDB_FULL_ERROR_CODE) {
          if (errorCodeCallback !== undefined) {
            errorCodeCallback(errorCode);
          }
        }
      }
    } else {
      LogUtil.info(TAG, 'this.rdbStore is not null');
    }
  }

  /**
   * insert record
   *
   * @param expression entry
   */
  /* instrument ignore next */
  async insert(valueBucket: relationalStore.ValuesBucket): Promise<void> {
    await this.getRdbStore((errorCode: number) => {
      try {
        if (errorCode === RDB_IO_ERROR_CODE || errorCode === RDB_FULL_ERROR_CODE) {
          if (CommonUtil.isLowSystemSafeSpace()) {
            promptAction.showToast({ message: $r('app.string.low_storage_space_toast'), duration: PROMPT_TIME });
          }
        }
      } catch (error) {
        LogUtil.error(TAG, 'errorCodeCallback failed: ', (error as BusinessError).message);
      }
    });
    if (this.rdbStore === null) {
      LogUtil.error(TAG, 'rdbStore is null, insert fail.');
      return;
    }
    try {
      let insertPromise: Promise<number> = this.rdbStore.insert(DB.STORE_CONFIGV9.tableName, valueBucket);
      insertPromise.then((ret: number) => {
        LogUtil.info(TAG, 'insert history record success: ', ret.toString());
      }).catch((err: Error) => {
        LogUtil.error(TAG, `insert history record fail: ${err?.message}`);
        let errorCode: number = (err as BusinessError).code;
        if (errorCode === RDB_IO_ERROR_CODE || errorCode === RDB_FULL_ERROR_CODE) {
          if (CommonUtil.isLowSystemSafeSpace()) {
            promptAction.showToast({ message: $r('app.string.low_storage_space_toast'), duration: PROMPT_TIME });
          }
        }
      });
    } catch (err) {
      LogUtil.error(TAG, `insert failed, err: ${err?.message}`);
      if ((err as BusinessError).code === RDB_ERROR_CODE) {
        await this.rdbStore.restore();
      }
    }
  }

  /**
   * delete oldest record.
   */
  /* instrument ignore next */
  async delOldestRecord(): Promise<void> {
    await this.getRdbStore();
    if (this.rdbStore === null) {
      LogUtil.error(TAG, 'rdbStore is null, delOldestRecord fail.');
      return;
    }
    try {
      let res: relationalStore.ResultSet = await this.rdbStore.querySql(DB.queryMinRecord);
      res.goToFirstRow();
      let timeStamp: string = res.getString(0);
      res.close();
      LogUtil.info(TAG, 'delOldestRecord timeStamp: ', timeStamp);
      this.deleteItem(timeStamp, () => {
      });
    } catch (err) {
      LogUtil.error(TAG, `executeSql failed, err: ${err?.message}`);
      if ((err as BusinessError).code === RDB_ERROR_CODE) {
        await this.rdbStore.restore();
      }
    }
  }

  /**
   * delete record
   *
   * @param timeStamp expression record time stamp
   * @param callback for delete record rowId
   */
  /* instrument ignore next */
  async deleteItem(timeStamp: string, callback: Function): Promise<void> {
    await this.getRdbStore();
    if (this.rdbStore === null) {
      LogUtil.error(TAG, 'rdbStore is null, deleteItem fail.');
      return;
    }
    try {
      let predicates: relationalStore.RdbPredicates =
        new relationalStore.RdbPredicates(DB.STORE_CONFIGV9.tableName);
      if (timeStamp !== '') {
        predicates.equalTo('time_stamp', timeStamp);
      }
      let rows: number = await this.rdbStore.delete(predicates);
      LogUtil.info(TAG, 'delete rows: ', rows.toString());
      callback(rows);
    } catch (err) {
      LogUtil.error(TAG, 'delete failed, err: ', err?.message);
      if ((err as BusinessError).code === RDB_ERROR_CODE) {
        await this.rdbStore.restore();
      }
    }
  }

  /**
   * delete record by id
   *
   * @param record id
   * @param callback for delete record rowId
   */
  /* instrument ignore next */
  async deleteItemById(id: string, callback: Function): Promise<void> {
    await this.getRdbStore();
    if (this.rdbStore === null) {
      LogUtil.error(TAG, 'rdbStore is null, deleteItem fail.');
      return;
    }
    try {
      let predicates: relationalStore.RdbPredicates =
        new relationalStore.RdbPredicates(DB.STORE_CONFIGV9.tableName);
      if (id !== '') {
        predicates.equalTo('id', id);
      }
      let rows: number = await this.rdbStore.delete(predicates);
      LogUtil.info(TAG, `delete rows: ${rows.toString()}`);
      callback(rows);
    } catch (err) {
      LogUtil.info(TAG, `delete failed, err: ${err.message}`);
      if ((err as BusinessError).code === RDB_ERROR_CODE) {
        await this.rdbStore.restore();
      }
    }
  }

  /**
   * judge table is full for max count
   */
  /* instrument ignore next */
  async isTableFull(): Promise<boolean> {
    await this.getRdbStore();
    if (this.rdbStore === null) {
      LogUtil.error(TAG, 'rdbStore is null, isTableFull fail.');
      return false;
    }
    try {
      let resultSet: relationalStore.ResultSet = await this.rdbStore.querySql(DB.queryCount);
      resultSet.goToFirstRow();
      const cnt: string = resultSet.getString(0);
      LogUtil.info(TAG, 'table count is: ', cnt);
      resultSet.close();
      return Number.parseInt(cnt) >= MAX_HISTORY_RECORD;
    } catch (err) {
      LogUtil.error(TAG, `executeSql failed, err: ${err?.message}`);
      if ((err as BusinessError).code === RDB_ERROR_CODE) {
        await this.rdbStore.restore();
      }
      return false;
    }
  }

  /**
   * query record.
   *
   * @param callback callback for expression result set.
   */
  /* instrument ignore next */
  async queryAll(callback: Function): Promise<void> {
    await this.getRdbStore();
    if (this.rdbStore === null) {
      LogUtil.error(TAG, 'rdbStore is null, query fail.');
      callback([]);
      return;
    }
    try {
      let predicatesV9: relationalStore.RdbPredicates =
        new relationalStore.RdbPredicates(DB.STORE_CONFIGV9.tableName);
      predicatesV9.orderByDesc(DB.expressionField.timeStamp);
      let resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicatesV9);
      let exps: LooseObject[] = [];
      while (resultSet.goToNextRow()) {
        let exp: LooseObject = new LooseObject();
        exp.dbId = resultSet.getString(resultSet.getColumnIndex(DB.expressionField.id));
        exp.expression = resultSet.getString(resultSet.getColumnIndex(DB.expressionField.expression));
        exp.result = resultSet.getString(resultSet.getColumnIndex(DB.expressionField.result));
        exp.time_stamp = resultSet.getLong(resultSet.getColumnIndex(DB.expressionField.timeStamp));
        exps.push(exp);
      }
      resultSet.close();
      callback(exps);
    } catch (err) {
      LogUtil.error(TAG, 'query failed, err: ', err?.message);
      if ((err as BusinessError).code === RDB_ERROR_CODE) {
        await this.rdbStore.restore();
      }
    }
  }

  /**
   * 是否存在历史记录.
   *
   * @param callback 返回查询结果.
   */
  /* instrument ignore next */
  async isEmpty(callback: Function): Promise<void> {
    await this.getRdbStore();
    if (this.rdbStore === null) {
      LogUtil.error(TAG, 'rdbStore is null, query fail.');
      callback(false);
      return;
    }
    try {
      let predicatesV9: relationalStore.RdbPredicates =
        new relationalStore.RdbPredicates(DB.STORE_CONFIGV9.tableName);
      predicatesV9.orderByDesc(DB.expressionField.timeStamp);
      let resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicatesV9);
      let rowCount: number = resultSet.rowCount;
      resultSet.close();
      if (rowCount === 0) {
        callback(true);
        return;
      }
    } catch (err) {
      LogUtil.error(TAG, 'query failed, err: ', err?.message);
      if ((err as BusinessError).code === RDB_ERROR_CODE) {
        await this.rdbStore.restore();
      }
    }
    callback(false);
  }

  /**
   * 恢复自动(实时)备份数据
   * 配置为双写备份的数据库抛出14800011错误码
   *
   * @param resultSets resultSets
   */
  /* instrument ignore next */
  async restore(rdbStore: dataRdb.RdbStore, resultSets?: Array<dataRdb.ResultSet>): Promise<void> {
    try {
      LogUtil.info(TAG, `restore`);
      if (resultSets !== undefined && resultSets !== null && resultSets.length > 0) {
        for (const resultSet of resultSets) {
          try {
            if (resultSet?.rowCount === -1) {
              resultSet?.isColumnNull(0);
            }
            resultSet.close();
          } catch (e) {
            resultSet.close();
            if (e.code !== RDB_ERROR_CODE) {
              LogUtil.error(TAG, `resultSet restore, ${JSON.stringify(e)}`);
            }
          }
        }
      }
      await rdbStore.restore();
    } catch (error) {
      LogUtil.error(TAG, `restore failed, err:${(error as BusinessError).code} ${(error as BusinessError).message}`);
    }
  }
}