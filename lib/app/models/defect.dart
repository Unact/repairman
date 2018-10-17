import 'dart:async';

import 'package:sqflite/sqflite.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';

class Defect extends DatabaseModel {
  static final String _tableName = 'defects';

  int id;
  String name;

  get tableName => _tableName;

  Defect({Map<String, dynamic> values, this.id, this.name}) {
    if (values != null) build(values);
  }

  @override
  void build(Map<String, dynamic> values) {
    super.build(values);

    id = values['id'];
    name = values['name'];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['id'] = id;
    map['name'] = name;

    return map;
  }

  static Future<List<Defect>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => Defect(values: rec)).toList();
  }

  static Future<void> import(List<dynamic> recs, Batch batch) async {
    batch.delete(_tableName);
    recs.forEach((rec) => batch.insert(_tableName, Defect(values: rec).toMap()));
  }
}
