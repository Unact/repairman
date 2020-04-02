import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/geo_point.dart';
import 'package:repairman/app/models/user.dart';
import 'package:repairman/config/app_config.dart';
import 'package:repairman/data/data_sync.dart';

class AppData {
  AppData(AppConfig config) : env = config.env, version = config.databaseVersion;

  final String schemaPath = 'lib/data/schema.sql';
  final String env;
  final int version;
  Database db;
  String dbPath;
  SharedPreferences prefs;
  DataSync dataSync;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  final MethodChannel _locationChannel = MethodChannel("ru.unact.repairman/location");

  Future<void> setup() async {
    String currentPath = (await getApplicationDocumentsDirectory()).path;

    dbPath = '$currentPath/$env.db';

    await _setupDatabase();
    _setupFirebase();
    _setupPlatform();
    prefs = await SharedPreferences.getInstance();
    dataSync = DataSync();

    print('Initialized AppData');
  }

  Future<void> recreateDatabase() async {
    await deleteDatabase(dbPath);
    await _setupDatabase();
  }

  Future<void> _setupDatabase() async {
    int prevVersion = version;
    List<String> schemaExps = (await rootBundle.loadString(schemaPath)).split(';');
    schemaExps.removeLast(); // Уберем перенос строки

    db = await openDatabase(dbPath, version: version,
      onCreate: (Database db, int version) async {
        await Future.wait(schemaExps.map((exp) => db.execute(exp)));
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) => prevVersion = oldVersion,
      onDowngrade: (Database db, int oldVersion, int newVersion) => prevVersion = oldVersion
    );

    if (prevVersion != version) {
      await db.close();
      await recreateDatabase();
    } else {
      print('Started database');
    }
  }

  void _setupFirebase() {
    firebaseMessaging.configure();
    firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(sound: true, badge: true, alert: true));

    print('Initialized Firebase');
  }

  void _setupPlatform() {
    _locationChannel.setMethodCallHandler((call) async {
      switch(call.method) {
        case 'onLocationChanged':
          await _onLocationChanged(call.arguments);
          break;
        default:
          throw MissingPluginException();
      }
    });
  }

  Future<void> _onLocationChanged(Map<dynamic, dynamic> arguments) async {
    User user = User.currentUser;

    if (App.application.config.geocode && user != null) {
      user.curLatitude = arguments['latitude'];
      user.curLongitude = arguments['longitude'];
      await user.save();

      GeoPoint geoPoint = GeoPoint(
        latitude: arguments['latitude'],
        longitude: arguments['longitude'],
        accuracy: arguments['accuracy'],
        altitude: arguments['altitude']
      );
      await geoPoint.markAndInsert();
    }
  }
}
