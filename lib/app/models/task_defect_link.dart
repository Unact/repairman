import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/utils/nullify.dart';

class TaskDefectLink extends DatabaseModel {
  static final String _tableName = 'task_defect_link';
  int localId;
  DateTime localTs;

  int taskId;
  int defectId;

  get tableName => _tableName;

  TaskDefectLink(Map<String, dynamic> values) {
    build(values);
  }

  void build(Map<String, dynamic> values) {
    taskId = values['task_id'];
    defectId = values['defect_id'];
    localId = values['local_id'];
    localTs = Nullify.parseDate(values['local_ts']);
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map['task_id'] = taskId;
    map['defect_id'] = defectId;

    return map;
  }

  static Future<TaskDefectLink> create(Map<String, dynamic> values) async {
    TaskDefectLink rec = TaskDefectLink(values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<TaskDefectLink>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => TaskDefectLink(rec)).toList();
  }

  static Future<void> import(List<dynamic> recs) async {
    await TaskDefectLink.deleteAll();
    await Future.wait(recs.map((rec) => TaskDefectLink.create(rec)));
  }
}
