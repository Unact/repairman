import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/utils/nullify.dart';

class ComponentGroup extends DatabaseModel {
  static String _tableName = 'component_groups';

  int id;
  String name;
  bool isManualReplacement;

  int inscnt;
  int remcnt;
  int freecnt;

  get tableName => _tableName;

  ComponentGroup({Map<String, dynamic> values, this.id, this.name, this.isManualReplacement}) {
    if (values != null) build(values);
  }

  @override
  void build(Map<String, dynamic> values) {
    super.build(values);

    id = values['id'];
    name = values['name'];
    isManualReplacement = Nullify.parseBool(values['is_manual_replacement']);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['id'] = id;
    map['name'] = name;
    map['is_manual_replacement'] = isManualReplacement;

    return map;
  }

  static Future<ComponentGroup> create(Map<String, dynamic> values) async {
    ComponentGroup rec = ComponentGroup(values: values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<ComponentGroup>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => ComponentGroup(values: rec)).toList();
  }

  static Future<List<ComponentGroup>> allFree(int taskId) async {
    return (await App.application.data.db.rawQuery("""
      select
        cg.id,
        cg.name,
        cg.is_manual_replacement,
        (
          select count(*)
          from components c
          where c.component_group_id = cg.id and
            not exists(select 1 from terminal_component_links l where l.comp_id = c.id and l.local_deleted != 1)
        ) freecnt,
        (
          select count(*)
          from terminal_component_links tcl
          join components c on c.id = tcl.comp_id
          where tcl.task_id=$taskId and c.component_group_id = cg.id and tcl.local_deleted != 1
        ) inscnt
      from $_tableName cg
      where freecnt > 0 or inscnt > 0
      order by cg.name
    """)).map((rec) {
      ComponentGroup componentGroup = ComponentGroup(values: rec);
      componentGroup.freecnt = rec['freecnt'];
      componentGroup.inscnt = rec['inscnt'];
      componentGroup.remcnt = componentGroup.freecnt - componentGroup.inscnt;


      return componentGroup;
    }).toList();
  }

  static Future<List<ComponentGroup>> import(List<dynamic> recs) async {
    await ComponentGroup.deleteAll();
    return await Future.wait(recs.map((rec) => ComponentGroup.create(rec)));
  }
}
