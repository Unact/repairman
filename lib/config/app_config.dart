import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

import 'package:repairman/app/app.dart';

class AppConfig {
  AppConfig({
    @required this.isPhysicalDevice,
    @required this.deviceModel,
    @required this.osVersion,
    @required this.packageInfo,
    @required this.env,
    @required this.databaseVersion,
    @required this.apiBaseUrl,
    @required this.sentryDsn
  });

  final PackageInfo packageInfo;
  final bool isPhysicalDevice;
  final String deviceModel;
  final String osVersion;
  final String env;
  final String sentryDsn;
  final String clientId = 'repairman';
  final String secretKeyWord = '5005';
  final int databaseVersion;

  String apiBaseUrl;
  bool autoRefresh = true;
  bool geocode = true;
  String remoteVersion;

  bool get newVersionAvailable => remoteVersion != packageInfo.version;


  Future<void> save() async {
    await App.application.data.prefs.setBool('autoRefresh', autoRefresh);
    await App.application.data.prefs.setBool('geocode', geocode);
    await App.application.data.prefs.setString('apiBaseUrl', apiBaseUrl);
    await App.application.data.prefs.setString('remoteVersion', remoteVersion);
  }

  void loadSaved() {
    apiBaseUrl = App.application.data.prefs.getString('apiBaseUrl') ?? apiBaseUrl;
    autoRefresh = App.application.data.prefs.getBool('autoRefresh') ?? autoRefresh;
    geocode = App.application.data.prefs.getBool('geocode') ?? geocode;
    remoteVersion = App.application.data.prefs.getString('remoteVersion') ?? packageInfo.version;
  }

  Future<void> importRemote(Map<String, dynamic> data) async {
    remoteVersion = data['version'];
    await save();
  }
}
