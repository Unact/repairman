import 'dart:async';
import 'dart:io';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/models/terminal_image.dart';

class TerminalImageTemp extends DatabaseModel {
  static final String _tableName = 'terminal_images_temp';

  int ppsTerminalId;
  String filepath;

  get tableName => _tableName;

  TerminalImageTemp({
    Map<String, dynamic> values,
    this.ppsTerminalId,
    this.filepath
  }) {
    if (values != null) build(values);
  }

  @override
  void build(Map<String, dynamic> values) {
    super.build(values);

    ppsTerminalId = values['pps_terminal_id'];
    filepath = values['filepath'];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['pps_terminal_id'] = ppsTerminalId;
    map['filepath'] = filepath;

    return map;
  }

  Future<void> saveToRemote() async {
    File file = File(filepath);

    if (file.existsSync()) {
      await TerminalImage.saveToRemote(ppsTerminalId, file);
      await delete();
      await file.delete();
    } else {
      await delete();
    }
  }

  static Future<List<TerminalImageTemp>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => TerminalImageTemp(values: rec)).toList();
  }

  static Future<List<TerminalImageTemp>> byPpsTerminalId(int ppsTerminalId) async {
    return (await App.application.data.db.rawQuery("""
      select
        terminal_images_temp.*
      from $_tableName terminal_images_temp
      where pps_terminal_id = $ppsTerminalId
      order by terminal_images_temp.local_ts
    """)).map((rec) => TerminalImageTemp(values: rec)).toList();
  }

  static Future<void> deleteAll() async {
    return await App.application.data.db.delete(_tableName);
  }
}
