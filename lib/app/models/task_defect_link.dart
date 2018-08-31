import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';

class TaskDefectLink extends DatabaseModel {
  static final String _tableName = 'task_defect_link';

  int taskId;
  int defectId;

  get tableName => _tableName;

  TaskDefectLink({Map<String, dynamic> values, this.taskId, this.defectId}) {
    if (values != null) build(values);
  }

  @override
  void build(Map<String, dynamic> values) {
    super.build(values);
    taskId = values['task_id'];
    defectId = values['defect_id'];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['task_id'] = taskId;
    map['defect_id'] = defectId;

    return map;
  }

  static Future<TaskDefectLink> create(Map<String, dynamic> values) async {
    TaskDefectLink rec = TaskDefectLink(values: values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<TaskDefectLink>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => TaskDefectLink(values: rec)).toList();
  }

  static Future<List<TaskDefectLink>> byTaskId(int taskId) async {
    return (await App.application.data.db.query(_tableName, where: 'task_id = $taskId')).map((rec) {
      return TaskDefectLink(values: rec);
    }).toList();
  }

  static Future<void> import(List<dynamic> recs) async {
    await TaskDefectLink.deleteAll();
    await Future.wait(recs.map((rec) => TaskDefectLink.create(rec)));
  }
}
