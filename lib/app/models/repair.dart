import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';

class Repair extends DatabaseModel {
  static final String _tableName = 'repairs';

  int id;
  String name;

  get tableName => _tableName;

  Repair({Map<String, dynamic> values, this.id, this.name}) {
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

  static Future<Repair> create(Map<String, dynamic> values) async {
    Repair rec = Repair(values: values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<Repair>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => Repair(values: rec)).toList();
  }

  static Future<void> import(List<dynamic> recs) async {
    await Repair.deleteAll();
    await Future.wait(recs.map((rec) => Repair.create(rec)));
  }
}
