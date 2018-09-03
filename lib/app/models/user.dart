import 'dart:async';

import 'package:location/location.dart' as geoLoc;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/base_model.dart';

class User extends BaseModel {
  String username = defaultUsername;
  String password;
  String email;
  String zoneName;
  String agentName;
  String firebaseToken = '';
  double curLatitude = defaultCurLatitude;
  double curLongitude = defaultCurLongitude;

  static const String defaultUsername = 'guest';
  static const double defaultCurLatitude = 0.0;
  static const double defaultCurLongitude = 0.0;

  User({Map<String, dynamic> values}) {
    if (values != null) build(values);
  }

  void build(Map<String, dynamic> values) {
    username = values['username'];
    password = values['password'];
    zoneName = values['zoneName'];
    agentName = values['agentName'];
    email = values['email'];
    firebaseToken = values['firebaseToken'];
    curLatitude = values['curLatitude'];
    curLongitude = values['curLongitude'];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['username'] = username;
    map['password'] = password;
    map['agent_name'] = agentName;
    map['zone_name'] = zoneName;
    map['email'] = email;
    map['firebase_token'] = firebaseToken;

    return map;
  }

  static User currentUser() {
    User user = User();
    String password = App.application.data.prefs.getString('password');

    if (password != null) {
      user = User(values: {
        'username': App.application.data.prefs.getString('username'),
        'password': password,
        'zoneName': App.application.data.prefs.getString('zoneName'),
        'agentName': App.application.data.prefs.getString('agentName'),
        'email': App.application.data.prefs.getString('email'),
        'firebaseToken': App.application.data.prefs.getString('firebaseToken'),
        'curLatitude': App.application.data.prefs.getDouble('curLatitude'),
        'curLongitude': App.application.data.prefs.getDouble('curLongitude'),
      });
    }

    return user;
  }

  bool isLogged() {
    return currentUser().password != null;
  }

  static Future<User> import(Map<String, dynamic> userData) async {
    App appl = App.application;
    User user = User.currentUser();
    Map<String, double> currentLocation = Map<String, double>();

    user.email = userData['email'];
    user.zoneName = userData['zone_name'];
    user.agentName = userData['agent_name'];
    // В связи с тем что на симуляторе firebase не работает, делаем заглушку иначе метод вешает приложение
    // https://github.com/flutter/flutter/issues/17086
    appl.data.firebaseMessaging.configure();
    user.firebaseToken = appl.config.isPhysicalDevice ? (await appl.data.firebaseMessaging.getToken() ?? '') : '';

    try {
      currentLocation = await geoLoc.Location().getLocation();

      user.curLatitude = currentLocation['latitude'];
      user.curLongitude = currentLocation['longitude'];
    } on PlatformException {}
    await user.save();

    return user;
  }

  static Future<Map<String, dynamic>> export() async {
    return currentUser().toMap();
  }

  static Future<User> create(Map<String, dynamic> values) async {
    User user = User(values: values);
    await user.save();

    return user;
  }

  Future<User> insert() async {
    await save();

    return this;
  }

  Future<User> update() async {
    await save();

    return this;
  }

  Future<void> delete() async {
    username = defaultUsername;
    password = null;
    email = null;
    zoneName = null;
    agentName = null;
    firebaseToken = '';
    curLatitude = defaultCurLatitude;
    curLongitude = defaultCurLongitude;

    await save();
  }

  Future<void> save() async {
    SharedPreferences prefs = App.application.data.prefs;

    await (username != null ? prefs.setString('username', username) : prefs.remove('username'));
    await (password != null ? prefs.setString('password', password) : prefs.remove('password'));
    await (email != null ? prefs.setString('email', email) : prefs.remove('email'));
    await (zoneName != null ? prefs.setString('zoneName', zoneName) : prefs.remove('zoneName'));
    await (agentName != null ? prefs.setString('agentName', agentName) : prefs.remove('agentName'));
    await (firebaseToken != null ? prefs.setString('firebaseToken', firebaseToken) : prefs.remove('firebaseToken'));
    await (curLatitude != null ? prefs.setDouble('curLatitude', curLatitude) : prefs.remove('curLatitude'));
    await (curLongitude != null ? prefs.setDouble('curLongitude', curLongitude) : prefs.remove('curLongitude'));
  }
}
