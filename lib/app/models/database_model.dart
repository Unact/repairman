import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/base_model.dart';
import 'package:repairman/app/utils/nullify.dart';

abstract class DatabaseModel<T> extends BaseModel {
  int localId;
  DateTime localTs;
  bool localInserted;
  bool localUpdated;
  bool localDeleted;
  get tableName;

  void build(Map<String, dynamic> values) {
    localId = values['local_id'];
    localTs = Nullify.parseDate(values['local_ts']);
    localInserted = Nullify.parseBool(values['local_inserted']);
    localUpdated = Nullify.parseBool(values['local_updated']);
    localDeleted = Nullify.parseBool(values['local_deleted']);
  }

  Map<String, dynamic> toExportMap() {
    Map<String, dynamic> values = toMap();
    values.addEntries({
      'local_id': localId,
      'local_ts': localTs?.toIso8601String(),
      'local_inserted': localInserted,
      'local_updated': localUpdated,
      'local_deleted': localDeleted,
    }.entries);

    return values;
  }

  Future<void> reload() async {
    build((await App.application.data.db.query(tableName, where: 'local_id = $localId')).first);
  }

  Future<DatabaseModel<T>> insert() async {
    localId = (await App.application.data.db.insert(tableName, toMap()));
    return this;
  }

  Future<DatabaseModel<T>> markInserted(bool inserted) async {
    await updateField('local_inserted', inserted);
    localInserted = inserted;
    return this;
  }

  Future<DatabaseModel<T>> markAndInsert() async {
    await insert();
    await markInserted(true);
    await reload();
    return this;
  }

  Future<DatabaseModel<T>> update() async {
    await App.application.data.db.update(tableName, toMap(), where: 'local_id = $localId');
    return this;
  }

  Future<DatabaseModel<T>> markUpdated(bool updated) async {
    await updateField('local_updated', updated);
    localUpdated = updated;
    return this;
  }

  Future<DatabaseModel<T>> markAndUpdate() async {
    await update();
    await markUpdated(true);
    await reload();
    return this;
  }

  Future<void> delete() async {
    await App.application.data.db.delete(tableName, where: 'local_id = $localId');
  }

  Future<DatabaseModel<T>> markDeleted(bool deleted) async {
    await updateField('local_deleted', deleted);
    localDeleted = deleted;
    return this;
  }

  Future<DatabaseModel<T>> updateField(String field, dynamic value) async {
    await App.application.data.db.update(tableName, {field: value}, where: 'local_id = $localId');
    return this;
  }

  static Future<List<DatabaseModel>> createOrDeleteFromList(
    List<DatabaseModel> searchList,
    Function searchFn,
    DatabaseModel newRec,
    [bool toCreate]
  ) async {
    Function searchDeletedFn = (rec) => searchFn(rec) && rec.localDeleted;
    Function searchInsertedFn = (rec) => searchFn(rec) && rec.localInserted;
    toCreate = toCreate ?? !searchList.any((rec) => searchFn(rec) && !rec.localDeleted);

    if (toCreate) {
      if (searchList.any(searchDeletedFn)) {
        await searchList.firstWhere(searchDeletedFn).markDeleted(false);
      } else {
        await newRec.markAndInsert();
        searchList.add(newRec);
      }
    } else {
      if (searchList.any(searchInsertedFn)) {
        DatabaseModel insertedRec = searchList.firstWhere(searchInsertedFn);

        await insertedRec.delete();
        searchList.remove(insertedRec);
      } else {
        await searchList.firstWhere(searchFn).markDeleted(true);
      }
    }

    return searchList;
  }
}
