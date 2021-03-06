import 'dart:async';

import 'package:location/location.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/modules/api.dart';

class User {
  int id = kGuestId;
  String username = kGuestUsername;
  String password;
  String email = '';
  String zoneName;
  String agentName;
  String token;
  String firebaseToken = '';
  String remoteVersion;
  bool firebaseSubscribed = true;
  double curLatitude = kCurLatitude;
  double curLongitude = kCurLongitude;

  static const int kGuestId = 1;
  static const String kGuestUsername = 'guest';
  static const double kCurLatitude = 0.0;
  static const double kCurLongitude = 0.0;

  User.init() {
    _currentUser = this;

    id = App.application.data.prefs.getInt('id');
    username = App.application.data.prefs.getString('username');
    password = App.application.data.prefs.getString('password');
    zoneName = App.application.data.prefs.getString('zoneName');
    agentName = App.application.data.prefs.getString('agentName');
    email = App.application.data.prefs.getString('email') ?? '';
    token = App.application.data.prefs.getString('token');
    firebaseToken = App.application.data.prefs.getString('firebaseToken') ?? '';
    firebaseSubscribed = App.application.data.prefs.getBool('firebaseSubscribed') ?? true;
    remoteVersion = App.application.data.prefs.getString('remoteVersion');
    curLatitude = App.application.data.prefs.getDouble('curLatitude') ?? kCurLatitude;
    curLongitude = App.application.data.prefs.getDouble('curLongitude') ?? kCurLongitude;
  }

  static User _currentUser;
  static User get currentUser => _currentUser;

  bool get newVersionAvailable {
    String currentVersion = App.application.config.packageInfo.version;

    return remoteVersion != null && Version.parse(remoteVersion) > Version.parse(currentVersion);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['id'] = id;
    map['username'] = username;
    map['password'] = password;
    map['agent_name'] = agentName;
    map['zone_name'] = zoneName;
    map['email'] = email;
    map['token'] = token;
    map['firebase_token'] = firebaseToken;
    map['firebase_subscribed'] = firebaseSubscribed;
    map['remote_version'] = remoteVersion;

    return map;
  }

  bool isLogged() {
    return password != null;
  }

  Future<void> loadDataFromRemote() async {
    Map<String, dynamic> userData = await Api.get('v1/repairman/user_info');
    LocationData currentLocation;

    id = userData['id'];
    email = userData['email'];
    zoneName = userData['zone_name'];
    agentName = userData['agent_name'];
    firebaseSubscribed = userData['firebase_subscribed'];
    remoteVersion = userData['app']['version'];
    setFirebaseToken();
    try {
      currentLocation = await Location().getLocation();

      curLatitude = currentLocation.latitude;
      curLongitude = currentLocation.longitude;
    } on PlatformException {}

    await save();
  }

  Future<void> reset() async {
    id = kGuestId;
    username = kGuestUsername;
    password = null;
    email = null;
    zoneName = null;
    agentName = null;
    token = null;
    firebaseToken = '';
    firebaseSubscribed = false;
    remoteVersion = null;
    curLatitude = kCurLatitude;
    curLongitude = kCurLongitude;

    await save();
  }

  Future<void> setFirebaseToken() async {
    App appl = App.application;

    firebaseToken = await appl.data.firebaseMessaging.getToken() ?? '';
  }

  Future<void> subscribeToFirebase(bool sendNotifications) async {
    await Api.post('v1/repairman/subscribe', queryParameters: {"send_notifications": sendNotifications});
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
    await (token != null ? prefs.setString('token', token) : prefs.remove('token'));
    await (firebaseToken != null ? prefs.setString('firebaseToken', firebaseToken) : prefs.remove('firebaseToken'));
    await (remoteVersion != null ? prefs.setString('remoteVersion', remoteVersion) : prefs.remove('remoteVersion'));
    await prefs.setBool('firebaseSubscribed', firebaseSubscribed);
    await (curLatitude != null ? prefs.setDouble('curLatitude', curLatitude) : prefs.remove('curLatitude'));
    await (curLongitude != null ? prefs.setDouble('curLongitude', curLongitude) : prefs.remove('curLongitude'));
  }
}
