import 'dart:async';

import 'package:flutter/material.dart';
import 'package:great_circle_distance/great_circle_distance.dart';
import 'package:sqflite/sqflite.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/utils/nullify.dart';

class Terminal extends DatabaseModel {
  static final String _tableName = 'terminals';

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
  bool exclude;
  bool hasTask;
  bool hasInc;
  DateTime closedDaysBegin;
  DateTime closedDaysEnd;

  double distance;

  get tableName => _tableName;
  get forTech => hasTask || !hasInc;

  Terminal({
    Map<String, dynamic> values,
    this.id,
    this.terminalId,
    this.latitude,
    this.longitude,
    this.code,
    this.address,
    this.errorText,
    this.srcSystemName,
    this.mobileop,
    this.lastActivityTime,
    this.lastPaymentTime,
    this.hasTask,
    this.hasInc
  }) {
    if (values != null) build(values);
  }

  @override
  void build(Map<String, dynamic> values) {
    super.build(values);

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
    exclude = Nullify.parseBool(values['exclude']);
    hasTask = Nullify.parseBool(values['has_task']);
    hasInc = Nullify.parseBool(values['has_inc']);
    closedDaysBegin = Nullify.parseDate(values['closed_days_begin']);
    closedDaysEnd = Nullify.parseDate(values['closed_days_end']);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
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
    map['exclude'] = exclude;
    map['has_task'] = hasTask;
    map['has_inc'] = hasInc;
    map['closed_days_begin'] = closedDaysBegin?.toIso8601String();
    map['closed_days_end'] = closedDaysEnd?.toIso8601String();

    return map;
  }

  AssetImage mobileOpImg() {
    String assetName;

    switch (mobileop) {
      case 'Мегафон':
        assetName = 'lib/app/assets/images/megafonicon.jpg';
        break;
      case 'МТС':
        assetName = 'lib/app/assets/images/mtsicon.png';
        break;
      case 'Билайн':
        assetName = 'lib/app/assets/images/beelineicon.jpg';
        break;
      case 'Теле2':
        assetName = 'lib/app/assets/images/tele2icon.jpeg';
        break;
      default:
        assetName = 'lib/app/assets/images/unknownicon.png';
    }

    return AssetImage(assetName);
  }

  static Future<List<Terminal>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => Terminal(values: rec)).toList();
  }

  static Future<Terminal> byPpsTerminalId(int ppsTerminalId) async {
    return Terminal(values: (await App.application.data.db.query(_tableName, where: 'id = $ppsTerminalId')).first);
  }

  static Future<List<Terminal>> allWithDistance(double curLatitude, double curLongitude) async {
    return (await App.application.data.db.query(_tableName)).map((rec) {
      Terminal terminal = Terminal(values: rec);
      terminal.distance = GreatCircleDistance.fromDegrees(
          latitude1: terminal.latitude ?? 0.0,
          longitude1: terminal.longitude ?? 0.0,
          latitude2: curLatitude,
          longitude2: curLongitude
        ).haversineDistance() / 1000.0;

      return terminal;
    }).toList()..sort((terminal1, terminal2) => terminal1.distance.compareTo(terminal2.distance));
  }

  static Future<void> import(List<dynamic> recs, Batch batch) async {
    batch.delete(_tableName);
    recs.forEach((rec) => batch.insert(_tableName, Terminal(values: rec).toMap()));
  }
}
