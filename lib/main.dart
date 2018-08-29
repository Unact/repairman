import 'dart:io';

import 'package:device_info/device_info.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/config/app_config.dart';
import 'package:repairman/config/app_env.dart' show appEnv;
import 'package:package_info/package_info.dart';

void main() async {
  String developmentUrl;
  bool isPhysicalDevice;
  bool development = false;
  assert(development = true); // Метод выполняется только в debug режиме

  if (Platform.isIOS) {
    developmentUrl = 'http://localhost:3000';
    isPhysicalDevice = (await DeviceInfoPlugin().iosInfo).isPhysicalDevice;
  } else {
    developmentUrl = 'http://10.0.2.2:3000';
    isPhysicalDevice = (await DeviceInfoPlugin().androidInfo).isPhysicalDevice;
  }

  await appEnv.load();
  App.setup(AppConfig(
    packageInfo: await PackageInfo.fromPlatform(),
    isPhysicalDevice: isPhysicalDevice,
    env: development ? 'development' : 'production',
    databaseVersion: 1,
    apiBaseUrl: '${development ? developmentUrl : 'https://rapi.unact.ru'}/api/',
    sentryDsn: appEnv['SENTRY_DSN']
  )).run();
}
