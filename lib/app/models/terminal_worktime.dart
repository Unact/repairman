import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/utils/nullify.dart';

class TerminalWorktime extends DatabaseModel {
  static final String _tableName = 'terminal_worktimes';

  int id;
  int ppsTerminalId;
  int weekday;
  int timeBegin;
  int timeEnd;
  bool exclude;

  get tableName => _tableName;

  TerminalWorktime({
    Map<String, dynamic> values,
    this.id,
    this.ppsTerminalId,
    this.weekday,
    this.timeBegin,
    this.timeEnd,
    this.exclude
  }) {
    if (values != null) build(values);
  }

  @override
  void build(Map<String, dynamic> values) {
    super.build(values);

    id = values['id'];
    ppsTerminalId = values['pps_terminal_id'];
    weekday = values['weekday'];
    timeBegin = values['time_begin'];
    timeEnd = values['time_end'];
    exclude = Nullify.parseBool(values['exclude']);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['id'] = id;
    map['pps_terminal_id'] = ppsTerminalId;
    map['weekday'] = weekday;
    map['time_begin'] = timeBegin;
    map['time_end'] = timeEnd;
    map['exclude'] = exclude;

    return map;
  }

  static Future<TerminalWorktime> create(Map<String, dynamic> values) async {
    TerminalWorktime rec = TerminalWorktime(values: values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<TerminalWorktime>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => TerminalWorktime(values: rec)).toList();
  }

  static Future<List<TerminalWorktime>> byPpsTerminalId(int ppsTerminalId) async {
    return (await App.application.data.db.rawQuery("""
      select
        terminal_worktimes.*
      from $_tableName terminal_worktimes
      where pps_terminal_id = $ppsTerminalId
      order by terminal_worktimes.weekday
    """)).map((rec) => TerminalWorktime(values: rec)).toList();
  }

  static Future<void> import(List<dynamic> recs) async {
    await TerminalWorktime.deleteAll();
    await Future.wait(recs.map((rec) => TerminalWorktime.create(rec)));
  }
}
