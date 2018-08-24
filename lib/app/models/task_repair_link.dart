import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/utils/nullify.dart';

class TaskRepairLink extends DatabaseModel {
  static final String _tableName = 'task_repair_link';
  int localId;
  DateTime localTs;

  int taskId;
  int repairId;

  get tableName => _tableName;

  TaskRepairLink(Map<String, dynamic> values) {
    build(values);
  }

  void build(Map<String, dynamic> values) {
    taskId = values['task_id'];
    repairId = values['repair_id'];
    localId = values['local_id'];
    localTs = Nullify.parseDate(values['local_ts']);
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map['task_id'] = taskId;
    map['repair_id'] = repairId;

    return map;
  }

  static Future<TaskRepairLink> create(Map<String, dynamic> values) async {
    TaskRepairLink rec = TaskRepairLink(values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<TaskRepairLink>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) {
      return TaskRepairLink(rec);
    }).toList();
  }

  static Future<void> import(List<dynamic> recs) async {
    await TaskRepairLink.deleteAll();
    await Future.wait(recs.map((rec) {
      return TaskRepairLink.create(rec);
    }));
  }
}
