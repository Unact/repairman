import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'package:repairman/app/app.dart';

class AppConfig {
  AppConfig({
    @required this.isPhysicalDevice,
    @required this.env,
    @required this.databaseVersion,
    @required this.apiBaseUrl,
    @required this.sentryDsn
  });

  final bool isPhysicalDevice;
  final String env;
  final String sentryDsn;
  final String clientId = 'repairman';
  final String secretKeyWord = '5005';
  final int databaseVersion;

  String apiBaseUrl;
  bool autoRefresh = true;
  bool geocode = true;

  Future<void> save() async {
    await App.application.data.prefs.setBool('autoRefresh', autoRefresh);
    await App.application.data.prefs.setBool('geocode', geocode);
    await App.application.data.prefs.setString('apiBaseUrl', apiBaseUrl);
  }

  void loadSaved() {
    apiBaseUrl = App.application.data.prefs.getString('apiBaseUrl') ?? apiBaseUrl;
    autoRefresh = App.application.data.prefs.getBool('autoRefresh') ?? autoRefresh;
    geocode = App.application.data.prefs.getBool('geocode') ?? geocode;
  }
}
