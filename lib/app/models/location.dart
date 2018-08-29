import 'dart:async';

import 'package:great_circle_distance/great_circle_distance.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/utils/nullify.dart';

class Location extends DatabaseModel {
  static final String _tableName = 'locations';
  int localId;
  DateTime localTs;
  bool isNew;

  double latitude;
  double longitude;
  double accuracy;
  double altitude;
  DateTime ts;

  static const int newLimit = 7;

  get tableName => _tableName;

  Location(Map<String, dynamic> values) {
    build(values);
  }

  void build(Map<String, dynamic> values) {
    latitude = Nullify.parseDouble(values['latitude']);
    longitude = Nullify.parseDouble(values['longitude']);
    accuracy = Nullify.parseDouble(values['accuracy']);
    altitude = Nullify.parseDouble(values['altitude']);
    ts = Nullify.parseDate(values['ts']);

    localId = values['local_id'];
    localTs = Nullify.parseDate(values['local_ts']);
    isNew = Nullify.parseBool(values['is_new']);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['latitude'] = latitude;
    map['longitude'] = longitude;
    map['accuracy'] = accuracy;
    map['altitude'] = altitude;
    map['ts'] = ts;
    map['is_new'] = isNew;

    return map;
  }

  static Future<Location> create(Map<String, dynamic> values) async {
    Location rec = Location(values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<List<Location>> todayLocations() async {
    return (await App.application.data.db.query(_tableName, where: "ts >= date('now')", orderBy: 'ts')).map((rec) {
      return Location(rec);
    }).toList();
  }

  static Future<double> currentDistance() async {
    List<Location> locs = (await todayLocations());

    if (locs.length == 0) {
      return 0.0;
    }

    Location firstLoc = locs.removeAt(0);
    Map<String, dynamic> distData = locs.fold({'prevLoc': firstLoc, 'dist': 0.0}, (data, curLoc) {
      return {
        'prevLoc': curLoc,
        'dist': data['dist'] += GreatCircleDistance.fromDegrees(
          latitude1: data['prevLoc'].latitude,
          longitude1: data['prevLoc'].longitude,
          latitude2: curLoc.latitude,
          longitude2: curLoc.longitude
        ).haversineDistance() / 1000.0
      };
    });

    return distData['dist'];
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<Location>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => Location(rec)).toList();
  }

  static Future<List<Location>> allNew() async {
    return (await App.application.data.db.query(_tableName, where: 'is_new = 1')).map((rec) => Location(rec)).toList();
  }
}
