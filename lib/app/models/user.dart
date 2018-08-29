import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/base_model.dart';

class User extends BaseModel {
  String username;
  String password;
  String email;
  String zoneName;
  String agentName;
  String firebaseToken;

  User(Map<String, dynamic> values) :
    username = values['username'],
    password = values['password'],
    zoneName = values['zoneName'],
    agentName = values['agentName'],
    email = values['email'],
    firebaseToken = values['firebaseToken'];

  User.build(this.username, this.password, {this.zoneName, this.agentName, this.email, this.firebaseToken});

  static User currentUser() {
    User user;
    String username = App.application.data.prefs.getString('username');

    if (username != null) {
      user = User.build(
        username,
        App.application.data.prefs.getString('password'),
        zoneName: App.application.data.prefs.getString('zoneName'),
        agentName: App.application.data.prefs.getString('agentName'),
        email: App.application.data.prefs.getString('email'),
        firebaseToken: App.application.data.prefs.getString('firebaseToken')
      );
    }

    return user;
  }

  static Future<User> import(Map<String, dynamic> userData) async {
    App appl = App.application;
    User user = User.currentUser();

    user.email = userData['email'];
    user.zoneName = userData['zone_name'];
    user.agentName = userData['agent_name'];
    // В связи с тем что на симуляторе firebase не работает, делаем заглушку иначе метод вешает приложение
    user.firebaseToken = appl.config.isPhysicalDevice ? (appl.data.firebaseMessaging.getToken() ?? '') : '';
    await user.save();

    return user;
  }

  static Future<Map<String, dynamic>> export() async {
    return currentUser().toMap();
  }

  static Future<User> create(Map<String, dynamic> values) async {
    User user = User(values);
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
    username = null;
    password = null;
    email = null;
    zoneName = null;
    agentName = null;
    firebaseToken = null;

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
}
