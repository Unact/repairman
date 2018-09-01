import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';

class TerminalComponentLink extends DatabaseModel {
  static final String _tableName = 'terminal_component_links';

  int taskId;
  int compId;
  bool isRemoved;
  String name;
  String serial;
  int componentGroupId;
  int ppsTerminalId;

  get tableName => _tableName;

  TerminalComponentLink({Map<String, dynamic> values, this.taskId, this.compId, this.componentGroupId}) {
    if (values != null) build(values);
  }

  @override
  void build(Map<String, dynamic> values) {
    super.build(values);

    taskId = values['task_id'];
    compId = values['comp_id'];
    componentGroupId = values['component_group_id'];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['task_id'] = taskId;
    map['comp_id'] = compId;
    map['component_group_id'] = componentGroupId;

    return map;
  }

  static Future<TerminalComponentLink> create(Map<String, dynamic> values) async {
    TerminalComponentLink rec = TerminalComponentLink(values: values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<TerminalComponentLink>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => TerminalComponentLink(values: rec)).toList();
  }

  static Future<List<TerminalComponentLink>> byTaskId(int taskId) async {
    return (await App.application.data.db.query(_tableName, where: 'task_id = $taskId')).map((rec) {
      return TerminalComponentLink(values: rec);
    }).toList();
  }

  static Future<List<TerminalComponentLink>> forTaskComponentGroup(int taskId, int componentGroupId) async {
    return (await App.application.data.db.query(
      _tableName,
      where: 'task_id = $taskId and component_group_id = $componentGroupId'
    )).map((rec) {
      return TerminalComponentLink(values: rec);
    }).toList();
  }

  static Future<void> import(List<dynamic> recs) async {
    await TerminalComponentLink.deleteAll();
    await Future.wait(recs.map((rec) => TerminalComponentLink.create(rec)));
  }

  static Future<List<Map<String, dynamic>>> export() async {
    List<TerminalComponentLink> recs = await TerminalComponentLink.all();
    return recs.
      where((TerminalComponentLink rec) => rec.localInserted || rec.localUpdated || rec.localDeleted).
      map((req) => req.toExportMap()).toList();
  }
}
