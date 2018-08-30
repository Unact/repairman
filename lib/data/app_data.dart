import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/location.dart';
import 'package:repairman/app/models/user.dart';
import 'package:repairman/config/app_config.dart';
import 'package:repairman/data/data_sync.dart';

class AppData {
  AppData(AppConfig config) : env = config.env, version = config.databaseVersion;

  final String env;
  final int version;
  Database db;
  String dbPath;
  String schemaPath;
  SharedPreferences prefs;
  DataSync dataSync;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  BasicMessageChannel<String> _incrementPlatform = BasicMessageChannel<String>('increment', StringCodec());

  Future<void> setup() async {
    String currentPath = (await getApplicationDocumentsDirectory()).path;

    dbPath = '$currentPath/$env.db';
    schemaPath = 'lib/data/schemas/v$version.sql';

    await recreateDatabase();
    _setupFirebase();
    _setupPlatform();
    prefs = await SharedPreferences.getInstance();
    dataSync = DataSync();

    print('Initialized AppData');
  }

  Future<void> recreateDatabase() async {
    await deleteDatabase(schemaPath);
    await _setupDatabase();
  }

  Future<void> _setupDatabase() async {
    List<String> schemaExps = (await rootBundle.loadString(schemaPath)).split(';');
    schemaExps.removeLast(); // Уберем перенос строки

    db = await openDatabase(dbPath, version: version,
      onCreate: (Database db, int version) async {
        await Future.wait(schemaExps.map((exp) => db.execute(exp)));
      },
      onOpen: (Database db) async {
        print('Started database');
        print('Database version: $version');
      }
    );
  }

  void _setupFirebase() {
    firebaseMessaging.configure();
    firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(sound: true, badge: true, alert: true));

    print('Initialized Firebase');
  }

  void _setupPlatform() {
    _incrementPlatform.setMessageHandler(_handlePlatformIncrement);
  }

  Future<String> _handlePlatformIncrement(String message) async {
    List<String> messageParts = message.split(' ');
    User user = User.currentUser();

    if (App.application.config.geocode) {
      user.curLatitude = double.parse(messageParts[0]);
      user.curLongitude = double.parse(messageParts[1]);
      user.save();

      Location.create({
        'latitude': messageParts[0],
        'longitude': messageParts[1],
        'accuracy': messageParts[2],
        'altitude': messageParts[3]
      });

      if ((await Location.allNew()).length > Location.newLimit) {
        dataSync.exportLocations();
      }
    }

    return '';
  }
}
