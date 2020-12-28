import 'dart:async';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_user_agent/flutter_user_agent.dart';
import 'package:package_info/package_info.dart';

import 'package:repairman/app/modules/sentry.dart';
import 'package:repairman/config/app_config.dart';
import 'package:repairman/data/app_data.dart';
import 'package:repairman/config/app_env.dart' show appEnv;

class App {
  App._({
    @required this.config,
    @required this.data,
    @required this.sentry
  }) {
    _application = this;
  }

  static App _application;
  static App get application => _application;
  final String name = 'repairman';
  final String title = 'Семен';
  final AppConfig config;
  final AppData data;
  final Sentry sentry;

  static Future<App> init() async {
    if (_application != null)
      return _application;

    AndroidDeviceInfo androidDeviceInfo;
    IosDeviceInfo iosDeviceInfo;
    String developmentUrl;
    String osVersion;
    String deviceModel;
    bool isPhysicalDevice;
    bool development = false;
    assert(development = true); // Метод выполняется только в debug режиме

    // If you're running an application and need to access the binary messenger before `runApp()` has been called (for example, during plugin initialization), then you need to explicitly call the `WidgetsFlutterBinding.ensureInitialized()` first.
    WidgetsFlutterBinding.ensureInitialized();

    await FlutterUserAgent.init();

    if (Platform.isIOS) {
      developmentUrl = 'http://localhost:3000';
      iosDeviceInfo = await DeviceInfoPlugin().iosInfo;
      isPhysicalDevice = iosDeviceInfo.isPhysicalDevice;
      osVersion = iosDeviceInfo.systemVersion;
      deviceModel = iosDeviceInfo.utsname.machine;
    } else {
      developmentUrl = 'http://10.0.2.2:3000';
      androidDeviceInfo = await DeviceInfoPlugin().androidInfo;
      isPhysicalDevice = androidDeviceInfo.isPhysicalDevice;
      osVersion = androidDeviceInfo.version.release;
      deviceModel = androidDeviceInfo.brand + ' - ' + androidDeviceInfo.model;
    }

    await appEnv.load();

    AppConfig config = AppConfig(
      packageInfo: await PackageInfo.fromPlatform(),
      isPhysicalDevice: isPhysicalDevice,
      deviceModel: deviceModel,
      osVersion: osVersion,
      env: development ? 'development' : 'production',
      databaseVersion: 11,
      apiBaseUrl: '${development ? developmentUrl : 'https://data.unact.ru'}/api/',
      sentryDsn: appEnv['SENTRY_DSN']
    );
    AppData data = AppData(config);

    await data.setup();

    Sentry sentry = Sentry.setup(config);

    FlutterError.onError = (FlutterErrorDetails details) async {
      if (config.env == 'development') {
        FlutterError.dumpErrorToConsole(details);
      } else {
        Zone.current.handleUncaughtError(details.exception, details.stack);
      }
    };

    return App._(
      sentry: sentry,
      config: config,
      data: data
    );
  }

  Future<void> reportError(dynamic error, dynamic stackTrace) async {
    print(error);
    print(stackTrace);
    await sentry.captureException(error, stackTrace);
  }
}
