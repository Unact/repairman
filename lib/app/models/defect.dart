import 'dart:async';

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

  static Future<Defect> create(Map<String, dynamic> values) async {
    Defect rec = Defect(values: values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<Defect>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => Defect(values: rec)).toList();
  }

  static Future<void> import(List<dynamic> recs) async {
    await Defect.deleteAll();
    await Future.wait(recs.map((rec) => Defect.create(rec)));
  }
}
