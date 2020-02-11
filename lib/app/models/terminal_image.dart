import 'dart:async';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/modules/api.dart';
import 'package:repairman/app/utils/nullify.dart';

class TerminalImage extends DatabaseModel {
  static final String _tableName = 'terminal_images';

  int id;
  int ppsTerminalId;
  String shortUrl;
  DateTime cts;

  get tableName => _tableName;

  TerminalImage({
    Map<String, dynamic> values,
    this.id,
    this.ppsTerminalId,
    this.shortUrl,
    this.cts
  }) {
    if (values != null) build(values);
  }

  @override
  void build(Map<String, dynamic> values) {
    super.build(values);

    id = values['id'];
    ppsTerminalId = values['pps_terminal_id'];
    shortUrl = values['short_url'];
    cts = Nullify.parseDate(values['cts']);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['id'] = id;
    map['pps_terminal_id'] = ppsTerminalId;
    map['short_url'] = shortUrl;
    map['cts'] = cts?.toIso8601String();

    return map;
  }

  static Future<void> saveToRemote(int ppsTerminalId, File file) async {
    List<dynamic> res =  await Api.post(
      'v2/images/PpsTerminal',
      data: <String, dynamic>{'model_id': ppsTerminalId},
      files: [file],
      filesKey: 'images'
    );
    List<dynamic> data = res.map((el) {
      el['pps_terminal_id'] = ppsTerminalId;
      return el;
    }).toList();

    await Future.forEach(data, (rec) => App.application.data.db.insert(_tableName, TerminalImage(values: rec).toMap()));
  }

  static Future<List<TerminalImage>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => TerminalImage(values: rec)).toList();
  }

  static Future<List<TerminalImage>> byPpsTerminalId(int ppsTerminalId) async {
    return (await App.application.data.db.rawQuery("""
      select
        terminal_images.*
      from $_tableName terminal_images
      where pps_terminal_id = $ppsTerminalId
      order by terminal_images.cts
    """)).map((rec) => TerminalImage(values: rec)).toList();
  }

  static Future<void> import(List<dynamic> recs, Batch batch) async {
    batch.delete(_tableName);
    recs.forEach((rec) => batch.insert(_tableName, TerminalImage(values: rec).toMap()));
  }
}
