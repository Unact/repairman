import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/utils/nullify.dart';

class Defect extends DatabaseModel {
  static final String _tableName = 'defects';
  int localId;
  DateTime localTs;

  int id;
  String name;

  get tableName => _tableName;

  Defect(Map<String, dynamic> values) {
    build(values);
  }

  void build(Map<String, dynamic> values) {
    id = values['id'];
    name = values['name'];
    localId = values['local_id'];
    localTs = Nullify.parseDate(values['local_ts']);
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map['id'] = id;
    map['name'] = name;

    return map;
  }

  static Future<Defect> create(Map<String, dynamic> values) async {
    Defect rec = Defect(values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<Defect>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) {
      return Defect(rec);
    }).toList();
  }

  static Future<void> import(List<dynamic> recs) async {
    await Defect.deleteAll();
    await Future.wait(recs.map((rec) {
      return Defect.create(rec);
    }));
  }
}
