import 'dart:async';

import 'package:flutter/material.dart';
import 'package:great_circle_distance/great_circle_distance.dart';

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
  bool monday;
  int mondayBegin;
  int mondayEnd;
  bool tuesday;
  int tuesdayBegin;
  int tuesdayEnd;
  bool wednesday;
  int wednesdayBegin;
  int wednesdayEnd;
  bool thursday;
  int thursdayBegin;
  int thursdayEnd;
  bool friday;
  int fridayBegin;
  int fridayEnd;
  bool saturday;
  int saturdayBegin;
  int saturdayEnd;
  bool sunday;
  int sundayBegin;
  int sundayEnd;
  bool exclude;
  DateTime closedDaysBegin;
  DateTime closedDaysEnd;

  double distance;

  get tableName => _tableName;

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
    this.lastPaymentTime
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
    monday = Nullify.parseBool(values['monday']);
    mondayBegin = values['monday_begin'];
    mondayEnd = values['monday_end'];
    tuesday = Nullify.parseBool(values['tuesday']);
    tuesdayBegin = values['tuesday_begin'];
    tuesdayEnd = values['tuesday_end'];
    wednesday = Nullify.parseBool(values['wednesday']);
    wednesdayBegin = values['wednesday_begin'];
    wednesdayEnd = values['wednesday_end'];
    thursday = Nullify.parseBool(values['thursday']);
    thursdayBegin = values['thursday_begin'];
    thursdayEnd = values['thursday_end'];
    friday = Nullify.parseBool(values['friday']);
    fridayBegin = values['friday_begin'];
    fridayEnd = values['friday_end'];
    saturday = Nullify.parseBool(values['saturday']);
    saturdayBegin = values['saturday_begin'];
    saturdayEnd = values['saturday_end'];
    sunday = Nullify.parseBool(values['sunday']);
    sundayBegin = values['sunday_begin'];
    sundayEnd = values['sunday_end'];
    exclude = Nullify.parseBool(values['exclude']);
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
    map['monday'] = monday;
    map['monday_begin'] = mondayBegin;
    map['monday_end'] = mondayEnd;
    map['tuesday'] = tuesday;
    map['tuesday_begin'] = tuesdayBegin;
    map['tuesday_end'] = tuesdayEnd;
    map['wednesday'] = wednesday;
    map['wednesday_begin'] = wednesdayBegin;
    map['wednesday_end'] = wednesdayEnd;
    map['thursday'] = thursday;
    map['thursday_begin'] = thursdayBegin;
    map['thursday_end'] = thursdayEnd;
    map['friday'] = friday;
    map['friday_begin'] = fridayBegin;
    map['friday_end'] = fridayEnd;
    map['saturday'] = saturday;
    map['saturday_begin'] = saturdayBegin;
    map['saturday_end'] = saturdayEnd;
    map['sunday'] = sunday;
    map['sunday_begin'] = sundayBegin;
    map['sunday_end'] = sundayEnd;
    map['exclude'] = exclude;
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

  static Future<Terminal> create(Map<String, dynamic> values) async {
    Terminal rec = Terminal(values: values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
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
          latitude1: terminal.latitude,
          longitude1: terminal.longitude,
          latitude2: curLatitude,
          longitude2: curLongitude
        ).haversineDistance() / 1000.0;

      return terminal;
    }).toList()..sort((terminal1, terminal2) => terminal1.distance.compareTo(terminal2.distance));
  }

  static Future<void> import(List<dynamic> recs) async {
    await Terminal.deleteAll();
    await Future.wait(recs.map((rec) => Terminal.create(rec)));
  }
}
