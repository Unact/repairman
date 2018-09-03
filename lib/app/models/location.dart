import 'dart:async';

import 'package:great_circle_distance/great_circle_distance.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/utils/nullify.dart';

class Location extends DatabaseModel {
  static final String _tableName = 'locations';

  double latitude;
  double longitude;
  double accuracy;
  double altitude;

  static const int newLimit = 7;
  static const int minPoints = 5;

  get tableName => _tableName;

  Location({Map<String, dynamic> values, this.latitude, this.longitude, this.accuracy, this.altitude}) {
    if (values != null) build(values);
  }

  @override
  void build(Map<String, dynamic> values) {
    super.build(values);

    latitude = Nullify.parseDouble(values['latitude']);
    longitude = Nullify.parseDouble(values['longitude']);
    accuracy = Nullify.parseDouble(values['accuracy']);
    altitude = Nullify.parseDouble(values['altitude']);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['latitude'] = latitude;
    map['longitude'] = longitude;
    map['accuracy'] = accuracy;
    map['altitude'] = altitude;
    map['ts'] = localTs;

    return map;
  }

  static Future<Location> create(Map<String, dynamic> values) async {
    Location rec = Location(values: values);
    await rec.insert();
    await rec.reload();
    return rec;
  }

  static Future<List<Location>> todayLocations() async {
    return (await App.application.data.db.query(_tableName, where: "ts >= date('now')", orderBy: 'ts')).map((rec) {
      return Location(values: rec);
    }).toList();
  }

  static Future<double> currentDistance() async {
    List<Location> locs = (await todayLocations());

    if (locs.length != minPoints) {
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
    return (await App.application.data.db.query(_tableName)).map((rec) => Location(values: rec)).toList();
  }

  static Future<List<Location>> allNew() async {
    return (await App.application.data.db.query(_tableName, where: 'local_inserted = 1')).
      map((rec) => Location(values: rec)).toList();
  }
}
