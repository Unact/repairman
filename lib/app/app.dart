import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_user_agent/flutter_user_agent.dart';
import 'package:package_info/package_info.dart';
import 'package:sentry_flutter/sentry_flutter.dart' as sentryLib;

import 'package:repairman/app/models/user.dart';
import 'package:repairman/config/app_config.dart';
import 'package:repairman/data/app_data.dart';

class App {
  App._({
    @required this.config,
    @required this.data
  }) {
    _application = this;
  }

  static App _application;
  static App get application => _application;
  final String name = 'repairman';
  final String title = 'Семен';
  final AppConfig config;
  final AppData data;

  static const List<String> _skipErrors = [
    'HttpException',
    'SocketException',
    'ClientException',
    'HandshakeException',
    'HttpExceptionWithStatus'
  ];

  static Future<App> init() async {
    if (_application != null)
      return _application;

    String developmentUrl = Platform.isIOS ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
    bool isDebug = false;
    assert(isDebug = true); // Метод выполняется только в debug режиме

    WidgetsFlutterBinding.ensureInitialized();

    await FlutterUserAgent.init();
    await DotEnv().load('.env');

    AppConfig config = AppConfig(
      packageInfo: await PackageInfo.fromPlatform(),
      env: isDebug ? 'development' : 'production',
      databaseVersion: 11,
      apiBaseUrl: '${isDebug ? developmentUrl : 'https://data.unact.ru'}/api/'
    );
    AppData data = AppData(config);

    await data.setup();
    await _initSentry(dsn: DotEnv().env['SENTRY_DSN'], capture: !isDebug);

    return App._(
      config: config,
      data: data
    );
  }

  Future<void> reportError(dynamic error, dynamic stackTrace) async {
    print(error);
    print(stackTrace);
    await sentryLib.Sentry.captureException(error, stackTrace: stackTrace);
  }

  static Future<void> _initSentry({
    @required String dsn,
    @required bool capture
  }) async {
    if (!capture)
      return;

    await sentryLib.SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.beforeSend = (sentryLib.SentryEvent event, {dynamic hint}) {
          User user = User.currentUser;

          return _skipErrors.any((el) => el == event.exception.type) ? null : event.copyWith(user: sentryLib.User(
            id: user.id.toString(),
            username: user.username,
            email: user.email
          ));
        };
      }
    );
  }
}
