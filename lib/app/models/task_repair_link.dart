import 'dart:async';

import 'package:sqflite/sqflite.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';

class TaskRepairLink extends DatabaseModel {
  static final String _tableName = 'task_repair_links';

  int taskId;
  int repairId;

  get tableName => _tableName;

  TaskRepairLink({Map<String, dynamic> values, this.taskId, this.repairId}) {
    if (values != null) build(values);
  }

  @override
  void build(Map<String, dynamic> values) {
    super.build(values);

    taskId = values['task_id'];
    repairId = values['repair_id'];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['task_id'] = taskId;
    map['repair_id'] = repairId;

    return map;
  }

  static Future<List<TaskRepairLink>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => TaskRepairLink(values: rec)).toList();
  }

  static Future<List<TaskRepairLink>> byTaskId(int taskId) async {
    return (await App.application.data.db.query(_tableName, where: 'task_id = $taskId')).map((rec) {
      return TaskRepairLink(values: rec);
    }).toList();
  }

  static Future<void> import(List<dynamic> recs, Batch batch) async {
    batch.delete(_tableName);
    recs.forEach((rec) => batch.insert(_tableName, TaskRepairLink(values: rec).toMap()));
  }

  static Future<List<Map<String, dynamic>>> export() async {
    List<TaskRepairLink> recs = await TaskRepairLink.all();
    return recs.
      where((TaskRepairLink rec) => rec.localInserted || rec.localUpdated || rec.localDeleted).
      map((req) => req.toExportMap()).toList();
  }

  static Future<void> deleteAll() async {
    return await App.application.data.db.delete(_tableName);
  }
}
