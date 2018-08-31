import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';

class Component extends DatabaseModel {
  static String _tableName = 'components';

  int id;
  String name;
  String serial;
  int componentGroupId;

  get tableName => _tableName;

  Component({Map<String, dynamic> values, this.id, this.name, this.serial}) {
    if (values != null) build(values);
  }

  @override
  void build(Map<String, dynamic> values) {
    super.build(values);

    id = values['id'];
    name = values['name'];
    serial = values['serial'];
    componentGroupId = values['component_group_id'];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['id'] = id;
    map['name'] = name;
    map['serial'] = serial;
    map['component_group_id'] = componentGroupId;

    return map;
  }

  static Future<Component> create(Map<String, dynamic> values) async {
    Component rec = Component(values: values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<Component>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => Component(values: rec)).toList();
  }

  static Future<List<Component>> byComponentGroup(int componentGroupId) async {
    return (await App.application.data.db.query(
      _tableName,
      where: 'component_group_id = $componentGroupId'
    )).map((rec) {
      return Component(values: rec);
    }).toList();
  }

  static Future<List<Component>> import(List<dynamic> recs) async {
    await Component.deleteAll();
    return await Future.wait(recs.map((rec) => Component.create(rec)));
  }
}
