import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/utils/nullify.dart';

class ComponentGroup extends DatabaseModel {
  static String _tableName = 'component_groups';
  int localId;
  DateTime localTs;

  int id;
  String name;
  bool isManualReplacement;

  get tableName => _tableName;

  ComponentGroup(Map<String, dynamic> values) {
    build(values);
  }

  void build(Map<String, dynamic> values) {
    id = values['id'];
    name = values['name'];
    isManualReplacement = Nullify.parseBool(values['is_manual_replacement']);
    localId = values['local_id'];
    localTs = Nullify.parseDate(values['local_ts']);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['id'] = id;
    map['name'] = name;
    map['is_manual_replacement'] = isManualReplacement;

    return map;
  }

  static Future<ComponentGroup> create(Map<String, dynamic> values) async {
    ComponentGroup rec = ComponentGroup(values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<ComponentGroup>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => ComponentGroup(rec)).toList();
  }

  static Future<List<ComponentGroup>> import(List<dynamic> recs) async {
    await ComponentGroup.deleteAll();
    return await Future.wait(recs.map((rec) => ComponentGroup.create(rec)));
  }
}
