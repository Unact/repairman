import 'dart:async';

import 'package:flutter/material.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/utils/nullify.dart';

class Task extends DatabaseModel {
  static final String _tableName = 'tasks';

  int id;
  bool servstatus;
  int ppsTerminalId;
  int routePriority;
  double markLatitude;
  double markLongitude;
  String invNum;
  String terminalBreakName;
  String info;
  DateTime dobefore;
  DateTime executionmarkTs;

  bool isSeen;

  static const int redRoute = 3;
  static const int yellowRoute = 2;
  static const int greenRoute = 1;

  get tableName => _tableName;

  Task({
    Map<String, dynamic> values,
    this.id,
    this.servstatus,
    this.ppsTerminalId,
    this.routePriority,
    this.markLatitude,
    this.markLongitude,
    this.invNum,
    this.terminalBreakName,
    this.info,
    this.dobefore,
    this.executionmarkTs
  }) {
    if (values != null) build(values);
  }

  @override
  void build(Map<String, dynamic> values) {
    super.build(values);

    id = values['id'];
    servstatus = Nullify.parseBool(values['servstatus']);
    ppsTerminalId = values['pps_terminal_id'];
    routePriority = values['route_priority'];
    markLatitude = Nullify.parseDouble(values['mark_latitude']);
    markLongitude = Nullify.parseDouble(values['mark_longitude']);
    invNum = values['inv_num'];
    terminalBreakName = values['terminal_break_name'];
    info = values['info'];
    dobefore = Nullify.parseDate(values['dobefore']);
    executionmarkTs = Nullify.parseDate(values['executionmark_ts']);

    isSeen = Nullify.parseBool(values['is_seen']) ?? false;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['id'] = id;
    map['servstatus'] = servstatus;
    map['pps_terminal_id'] = ppsTerminalId;
    map['route_priority'] = routePriority;
    map['mark_latitude'] = markLatitude;
    map['mark_longitude'] = markLongitude;
    map['inv_num'] = invNum;
    map['terminal_break_name'] = terminalBreakName;
    map['info'] = info;
    map['dobefore'] = dobefore?.toIso8601String();
    map['executionmark_ts'] = executionmarkTs?.toIso8601String();
    map['is_seen'] = isSeen;

    return map;
  }

  Map<String, Color> colors() {
    Color bcolor;
    Color tcolor;

      if (servstatus) {
        bcolor = Colors.grey;
        tcolor = Colors.blueGrey;
      } else {
        switch (routePriority) {
          case redRoute:
            bcolor = Colors.red;
            tcolor = Colors.white;
            break;
          case yellowRoute:
            bcolor = Colors.yellow;
            tcolor = Colors.black;
            break;
          case greenRoute:
            bcolor = Colors.green;
            tcolor = Colors.black;
            break;
          default:
            bcolor = Colors.white;
            tcolor = Colors.black;
        }
      }

    return {
      'bcolor': bcolor,
      'tcolor': tcolor
    };
  }

  static Future<Task> create(Map<String, dynamic> values) async {
    Task rec = Task(values: values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<Task>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => Task(values: rec)).toList();
  }

  static Future<void> import(List<dynamic> recs) async {
    List<Task> allTasks = await Task.all();
    List<dynamic> recsWithInfo = recs.map((rec) {
      rec['is_seen'] = allTasks.any((task) => task.id == rec['id'] && task.isSeen) ? 1 : 0;

      return rec;
    }).toList();
    await Task.deleteAll();
    await Future.wait(recsWithInfo.map((rec) => Task.create(rec)));
  }

  static Future<List<Map<String, dynamic>>> export() async {
    List<Task> recs = await Task.all();
    return recs.
      where((Task rec) => rec.localInserted || rec.localUpdated || rec.localDeleted).
      map((req) => req.toExportMap()).toList();
  }

  static Future<List<Task>> byPpsTerminalId(int ppsTerminalId) async {
    return (await App.application.data.db.rawQuery("""
      select
        tasks.*
      from $_tableName tasks
      where pps_terminal_id = $ppsTerminalId
      order by tasks.servstatus, tasks.route_priority desc, tasks.dobefore
    """)).map((rec) => Task(values: rec)).toList();
  }
}
