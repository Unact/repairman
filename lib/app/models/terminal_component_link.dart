import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/utils/nullify.dart';

class TerminalComponentLink extends DatabaseModel {
  static final String _tableName = 'terminal_component_link';

  int taskId;
  int compId;
  bool isRemoved;
  String name;
  String serial;
  int componentGroupId;
  int ppsTerminalId;

  get tableName => _tableName;

  TerminalComponentLink(Map<String, dynamic> values) {
    build(values);
  }

  @override
  void build(Map<String, dynamic> values) {
    super.build(values);

    taskId = values['task_id'];
    compId = values['comp_id'];
    isRemoved = Nullify.parseBool(values['is_removed']);
    name = values['name'];
    serial = values['serial'];
    componentGroupId = values['component_group_id'];
    ppsTerminalId = values['pps_terminal_id'];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['task_id'] = taskId;
    map['comp_id'] = compId;
    map['is_removed'] = isRemoved;
    map['name'] = name;
    map['serial'] = serial;
    map['component_group_id'] = componentGroupId;
    map['pps_terminal_id'] = ppsTerminalId;

    return map;
  }

  static Future<TerminalComponentLink> create(Map<String, dynamic> values) async {
    TerminalComponentLink rec = TerminalComponentLink(values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<TerminalComponentLink>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => TerminalComponentLink(rec)).toList();
  }

  static Future<void> import(List<dynamic> recs) async {
    await TerminalComponentLink.deleteAll();
    await Future.wait(recs.map((rec) => TerminalComponentLink.create(rec)));
  }
}