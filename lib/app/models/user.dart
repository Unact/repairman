import 'dart:async';

import 'package:location/location.dart' as geoLoc;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/base_model.dart';
import 'package:repairman/app/utils/nullify.dart';

class User extends BaseModel {
  int id = kGuestId;
  String username = kGuestUsername;
  String password;
  String email = '';
  String zoneName;
  String agentName;
  String firebaseToken = '';
  bool firebaseSubscribed = true;
  double curLatitude = kCurLatitude;
  double curLongitude = kCurLongitude;

  static const int kGuestId = 1;
  static const String kGuestUsername = 'guest';
  static const double kCurLatitude = 0.0;
  static const double kCurLongitude = 0.0;

  User({
    Map<String, dynamic> values,
    this.id,
    this.username,
    this.password,
    this.zoneName,
    this.agentName,
    this.email,
    this.firebaseToken,
    this.firebaseSubscribed,
    this.curLatitude,
    this.curLongitude
  }) {
    if (values != null) build(values);
  }

  void build(Map<String, dynamic> values) {
    id = values['id'] ?? kGuestId;
    username = values['username'];
    password = values['password'];
    zoneName = values['zone_name'];
    agentName = values['agent_name'];
    email = values['email'] ?? '';
    firebaseToken = values['firebase_token'] ?? '';
    firebaseSubscribed = Nullify.parseBool(values['firebase_subscribed']) ?? true;
    curLatitude = values['cur_latitude'] ?? kCurLatitude;
    curLongitude = values['cur_longitude'] ?? kCurLongitude;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['id'] = id;
    map['username'] = username;
    map['password'] = password;
    map['agent_name'] = agentName;
    map['zone_name'] = zoneName;
    map['email'] = email;
    map['firebase_token'] = firebaseToken;
    map['firebase_subscribed'] = firebaseSubscribed;

    return map;
  }

  static User currentUser() {
    User user = User();
    String password = App.application.data.prefs.getString('password');

    if (password != null) {
      user = User(values: {
        'id': App.application.data.prefs.getInt('id'),
        'username': App.application.data.prefs.getString('username'),
        'password': password,
        'zone_name': App.application.data.prefs.getString('zoneName'),
        'agent_name': App.application.data.prefs.getString('agentName'),
        'email': App.application.data.prefs.getString('email'),
        'firebase_token': App.application.data.prefs.getString('firebaseToken'),
        'firebase_subscribed': App.application.data.prefs.getBool('firebaseSubscribed'),
        'cur_latitude': App.application.data.prefs.getDouble('curLatitude'),
        'cur_longitude': App.application.data.prefs.getDouble('curLongitude'),
      });
    }

    return user;
  }

  bool isLogged() {
    return currentUser().password != null;
  }

  static Future<User> import(Map<String, dynamic> userData) async {
    User user = User.currentUser();
    Map<String, double> currentLocation = Map<String, double>();

    user.id = userData['id'];
    user.email = userData['email'];
    user.zoneName = userData['zone_name'];
    user.agentName = userData['agent_name'];
    user.firebaseSubscribed = userData['firebase_subscribed'];
    user.setFirebaseToken();
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
    id = kGuestId;
    username = kGuestUsername;
    password = null;
    email = null;
    zoneName = null;
    agentName = null;
    firebaseToken = '';
    firebaseSubscribed = false;
    curLatitude = kCurLatitude;
    curLongitude = kCurLongitude;

    await save();
  }

  Future<void> setFirebaseToken() async {
    App appl = App.application;
    // В связи с тем что на симуляторе firebase не работает, делаем заглушку иначе метод вешает приложение
    // https://github.com/flutter/flutter/issues/17086
    appl.data.firebaseMessaging.configure();
    firebaseToken = appl.config.isPhysicalDevice ? (await appl.data.firebaseMessaging.getToken() ?? '') : '';
  }

  Future<void> subscribeToFirebase(bool sendNotifications) async {
    await App.application.api.post('v2/repairman/subscribe?send_notifications=$sendNotifications', body: {});
    firebaseSubscribed = sendNotifications;
    await save();
  }

  Future<void> save() async {
    SharedPreferences prefs = App.application.data.prefs;

    await (id != null ? prefs.setInt('id', id) : prefs.remove('id'));
    await (username != null ? prefs.setString('username', username) : prefs.remove('username'));
    await (password != null ? prefs.setString('password', password) : prefs.remove('password'));
    await (email != null ? prefs.setString('email', email) : prefs.remove('email'));
    await (zoneName != null ? prefs.setString('zoneName', zoneName) : prefs.remove('zoneName'));
    await (agentName != null ? prefs.setString('agentName', agentName) : prefs.remove('agentName'));
    await (firebaseToken != null ? prefs.setString('firebaseToken', firebaseToken) : prefs.remove('firebaseToken'));
    await prefs.setBool('firebaseSubscribed', firebaseSubscribed);
    await (curLatitude != null ? prefs.setDouble('curLatitude', curLatitude) : prefs.remove('curLatitude'));
    await (curLongitude != null ? prefs.setDouble('curLongitude', curLongitude) : prefs.remove('curLongitude'));
  }
}
