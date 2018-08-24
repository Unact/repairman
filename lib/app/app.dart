import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sentry/sentry.dart' as sentryLib;

import 'package:repairman/app/models/user.dart';
import 'package:repairman/app/modules/api.dart';
import 'package:repairman/config/app_config.dart';
import 'package:repairman/data/app_data.dart';

class App {
  App.setup(this.config) :
    data = new AppData(config),
    api = new Api(config)
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
  sentryLib.SentryClient sentry;
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
      sentry = new sentryLib.SentryClient(dsn: config.sentryDsn);

      FlutterError.onError = (errorDetails) async {
        final sentryLib.Event event = new sentryLib.Event(
          exception: errorDetails.exception,
          stackTrace: errorDetails.stack,
          userContext: sentryLib.User(
            id: config.clientId,
            username: User.currentUser()?.username ?? 'guest'
          ),
          environment: config.env
        );

        await sentry.capture(event: event);
      };
    }
  }

  Widget _buildWidget() {
    return new MaterialApp(
      title: title,
      theme: new ThemeData(
        primarySwatch: Colors.blue
      ),
      initialRoute: api.isLogged() ? '/' : '/login',
      routes: config.routes,
      locale: const Locale('ru', 'RU'),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', 'US'),
        const Locale('ru', 'RU'),
      ],
    );
  }
}
