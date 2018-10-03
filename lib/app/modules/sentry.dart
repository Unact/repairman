import 'package:flutter/material.dart';
import 'package:sentry/sentry.dart' as sentryLib;

import 'package:repairman/app/models/user.dart';
import 'package:repairman/config/app_config.dart';

class Sentry {
  sentryLib.SentryClient client;

  // 1 ошибку убрать после решения https://github.com/flutter/flutter/issues/21313
  // 2 ошибку убрать когда флаттер выпустит 1.0 версию
  static const List<String> _skipErrors = [
    'FormatException: Invalid radix-16 number',
    'type \'_OneByteString\' is not a subtype of type \'Map<String, dynamic>\''
  ];

  Sentry._(this.client);

  static Sentry setup(AppConfig config) {
    sentryLib.SentryClient sentryClient = sentryLib.SentryClient(
      dsn: config.sentryDsn,
      environmentAttributes: sentryLib.Event(release: config.packageInfo.version)
    );

    FlutterError.onError = (FlutterErrorDetails errorDetails) async {
      if (_skipError(errorDetails)) return;

      User user = User.currentUser();
      sentryLib.Event event = sentryLib.Event(
        exception: errorDetails.exception,
        stackTrace: errorDetails.stack,
        userContext: sentryLib.User(
          id: user.id.toString(),
          username: user.username,
          email: user.email
        ),
        environment: config.env,
        extra: {
          'osVersion': config.osVersion,
          'deviceModel': config.deviceModel
        }
      );

      await sentryClient.capture(event: event);
    };

    return Sentry._(sentryClient);
  }

  static bool _skipError(FlutterErrorDetails errorDetails) {
    String exceptionStr = errorDetails.exceptionAsString();

    return _skipErrors.map((String exceptionText) => exceptionStr.contains(exceptionText)).any((bool val) => val);
  }
}
