import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:repairman/app/modules/api.dart';
import 'package:repairman/app/modules/sentry.dart';
import 'package:repairman/app/pages/home_page.dart';
import 'package:repairman/app/pages/login_page.dart';
import 'package:repairman/config/app_config.dart';
import 'package:repairman/data/app_data.dart';

class App {
  App.setup(this.config) :
    data = AppData(config),
    api = Api(config)
  {
    _setupEnv();
    _application = this;
  }

  static App _application;
  static App get application => _application;
  final String name = 'repairman';
  final String title = 'Семен';
  final AppConfig config;
  final AppData data;
  final Api api;
  Sentry sentry;
  Widget widget;

  Future<void> run() async {
    await data.setup();
    config.loadSaved();
    widget = _buildWidget();

    print('Started $name in ${config.env} environment');
    runApp(widget);
  }

  void _setupEnv() {
    if (config.env != 'development') {
      sentry = Sentry.setup(config);
    }
  }

  Widget _buildWidget() {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blue
      ),
      routes: {
        '/': (BuildContext context) => HomePage(),
        '/login': (BuildContext context) => LoginPage()
      },
      initialRoute: api.isLogged() ? '/' : '/login',
      locale: Locale('ru', 'RU'),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', 'US'),
        Locale('ru', 'RU'),
      ]
    );
  }
}
