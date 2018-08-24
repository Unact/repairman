import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/base_model.dart';

abstract class DatabaseModel<T> extends BaseModel  {
  int localId;
  DateTime localTs;
  get tableName;

  void build(Map<String, dynamic> values);

  Future<void> reload() async {
    build((await App.application.data.db.query(tableName, where: 'local_id = $localId')).first);
  }

  Future<DatabaseModel<T>> insert() async {
    localId = (await App.application.data.db.insert(tableName, toMap()));
    return this;
  }

  Future<DatabaseModel<T>> update() async {
    await App.application.data.db.update(tableName, toMap(), where: 'local_id = $localId');
    return this;
  }

  Future<void> delete() async {
    await App.application.data.db.delete(tableName, where: 'local_id = $localId');
  }

  Future<void> save() async {
    throw('Not implemented');
  }
}
