import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/utils/nullify.dart';

class Terminal extends DatabaseModel {
  static final String _tableName = 'terminals';
  int localId;
  DateTime localTs;

  int id;
  int terminalId;
  double latitude;
  double longitude;
  String code;
  String address;
  String errorText;
  String srcSystemName;
  String mobileop;
  DateTime lastActivityTime;
  DateTime lastPaymentTime;

  get tableName => _tableName;

  Terminal(Map<String, dynamic> values) {
    build(values);
  }

  void build(Map<String, dynamic> values) {
    id = values['id'];
    terminalId = values['terminalId'];
    latitude = Nullify.parseDouble(values['latitude']);
    longitude = Nullify.parseDouble(values['longitude']);
    code = values['code'];
    address = values['address'];
    errorText = values['errortext'];
    srcSystemName = values['src_system_name'];
    mobileop = values['mobileop'];
    lastActivityTime = Nullify.parseDate(values['lastactivitytime']);
    lastPaymentTime = Nullify.parseDate(values['lastpaymenttime']);
    localId = values['local_id'];
    localTs = Nullify.parseDate(values['local_ts']);
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map['id'] = id;
    map['terminalId'] = terminalId;
    map['latitude'] = latitude?.toString();
    map['longitude'] = longitude?.toString();
    map['code'] = code;
    map['address'] = address;
    map['errortext'] = errorText;
    map['src_system_name'] = srcSystemName;
    map['mobileop'] = mobileop;
    map['lastactivitytime'] = lastActivityTime?.toIso8601String();
    map['lastpaymenttime'] = lastPaymentTime?.toIso8601String();

    return map;
  }

  static Future<Terminal> create(Map<String, dynamic> values) async {
    Terminal rec = Terminal(values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<Terminal>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => Terminal(rec)).toList();
  }

  static Future<void> import(List<dynamic> recs) async {
    await Terminal.deleteAll();
    await Future.wait(recs.map((rec) => Terminal.create(rec)));
  }
}
