import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/utils/nullify.dart';

class Component extends DatabaseModel {
  static String _tableName = 'components';
  int localId;
  DateTime localTs;

  int id;
  String name;
  String serial;
  int componentGroupId;

  get tableName => _tableName;

  Component(Map<String, dynamic> values) {
    build(values);
  }

  void build(Map<String, dynamic> values) {
    id = values['id'];
    name = values['name'];
    serial = values['serial'];
    componentGroupId = values['component_group_id'];
    localId = values['local_id'];
    localTs = Nullify.parseDate(values['local_ts']);
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map['id'] = id;
    map['name'] = name;
    map['serial'] = serial;
    map['component_group_id'] = componentGroupId;

    return map;
  }

  static Future<Component> create(Map<String, dynamic> values) async {
    Component rec = Component(values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<Component>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) {
      return Component(rec);
    }).toList();
  }

  static Future<List<Component>> import(List<dynamic> recs) async {
    await Component.deleteAll();
    return await Future.wait(recs.map((rec) {
      return Component.create(rec);
    }));
  }
}
