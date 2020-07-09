import 'dart:async';

import 'package:sqflite/sqflite.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/utils/nullify.dart';

class Component extends DatabaseModel {
  static String _tableName = 'components';

  int id;
  String name;
  String serial;
  int componentGroupId;

  bool isFree;

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

  static Future<List<Component>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => Component(values: rec)).toList();
  }

  static Future<List<Component>> byComponentGroup(int componentGroupId) async {
    return (await App.application.data.db.rawQuery('''
      select
        c.*,
        ifnull((select 0 from terminal_component_links tcl where tcl.comp_id = c.id), 1) is_free
      from $_tableName c
      where c.component_group_id = $componentGroupId
      order by c.name
    ''')).map((rec) {
      Component comp = Component(values: rec);
      comp.isFree = Nullify.parseBool(rec['is_free']);
      return comp;
    }).toList();
  }

  static Future<void> import(List<dynamic> recs, Batch batch) async {
    batch.delete(_tableName);
    recs.forEach((rec) => batch.insert(_tableName, Component(values: rec).toMap()));
  }

  static Future<void> deleteAll() async {
    return await App.application.data.db.delete(_tableName);
  }
}
