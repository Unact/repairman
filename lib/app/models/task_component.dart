import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/utils/nullify.dart';

class TaskComponent extends DatabaseModel {
  static String _tableName = 'task_components';
  int localId;
  DateTime localTs;

  int id;
  int taskId;
  int compId;
  int ppsTerminalId;
  bool isRemoved;

  get tableName => _tableName;

  TaskComponent(Map<String, dynamic> values) {
    build(values);
  }

  void build(Map<String, dynamic> values) {
    id = values['id'];
    taskId = values['task_id'];
    compId = values['comp_id'];
    ppsTerminalId = values['pps_terminal_id'];
    isRemoved = Nullify.parseBool(values['is_removed']);
    localId = values['local_id'];
    localTs = Nullify.parseDate(values['local_ts']);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['id'] = id;
    map['task_id'] = taskId;
    map['comp_id'] = compId;
    map['pps_terminal_id'] = ppsTerminalId;
    map['is_removed'] = isRemoved;

    return map;
  }

  static Future<TaskComponent> create(Map<String, dynamic> values) async {
    TaskComponent rec = TaskComponent(values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<TaskComponent>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => TaskComponent(rec)).toList();
  }

  static Future<List<TaskComponent>> import(List<dynamic> recs) async {
    await TaskComponent.deleteAll();
    return await Future.wait(recs.map((rec) => TaskComponent.create(rec)));
  }
}
