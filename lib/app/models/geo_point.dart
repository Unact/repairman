import 'dart:async';

import 'package:great_circle_distance/great_circle_distance.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/utils/nullify.dart';

class GeoPoint extends DatabaseModel {
  static final String _tableName = 'geo_points';

  double latitude;
  double longitude;
  double accuracy;
  double altitude;

  static const int minPoints = 10;

  get tableName => _tableName;

  GeoPoint({Map<String, dynamic> values, this.latitude, this.longitude, this.accuracy, this.altitude}) {
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

    return map;
  }

  Map<String, dynamic> toExportMap() {
    Map<String, dynamic> values = toMap();
    values.addEntries({
      'local_ts': localTs?.toIso8601String()
    }.entries);

    return values;
  }

  static Future<List<GeoPoint>> todayGeoPoints() async {
    return (await App.application.data.db.query(_tableName, where: "local_ts >= date('now')", orderBy: 'local_ts')).
      map((rec) {
        return GeoPoint(values: rec);
      }).toList();
  }

  static Future<double> currentDistance() async {
    List<GeoPoint> locs = (await todayGeoPoints());

    if (locs.length < minPoints) {
      return 0.0;
    }

    GeoPoint firstGeoPoint = locs.removeAt(0);
    Map<String, dynamic> distData = locs.fold({'prevGeoPoint': firstGeoPoint, 'dist': 0.0}, (data, curGeoPoint) {
      return {
        'prevGeoPoint': curGeoPoint,
        'dist': data['dist'] += GreatCircleDistance.fromDegrees(
          latitude1: data['prevGeoPoint'].latitude,
          longitude1: data['prevGeoPoint'].longitude,
          latitude2: curGeoPoint.latitude,
          longitude2: curGeoPoint.longitude
        ).haversineDistance() / 1000.0
      };
    });

    return distData['dist'];
  }

  static Future<void> deleteAll() async {
    await App.application.data.db.delete(_tableName);
  }

  static Future<List<GeoPoint>> all() async {
    return (await App.application.data.db.query(_tableName)).map((rec) => GeoPoint(values: rec)).toList();
  }

  static Future<List<GeoPoint>> allNew() async {
    return (await App.application.data.db.query(_tableName,
      where: 'local_inserted = 1',
      orderBy: 'local_ts asc')
    ).map((rec) => GeoPoint(values: rec)).toList();
  }
}
