import 'package:flutter/material.dart';
import 'package:sentry/sentry.dart' as sentryLib;

import 'package:repairman/app/models/user.dart';
import 'package:repairman/config/app_config.dart';

class Sentry {
  sentryLib.SentryClient client;
  final String osVersion;
  final String deviceModel;
  final String env;

  static const List<String> _skipErrors = [
    'HttpException',
    'SocketException',
    'ClientException',
    'HandshakeException'
  ];

  Sentry._({
    @required this.client,
    @required this.osVersion,
    @required this.deviceModel,
    @required this.env
  });

  Future<void> captureException(dynamic exception, dynamic stack) async {
    User user = User.currentUser;
    sentryLib.Event event = sentryLib.Event(
      exception: exception,
      stackTrace: stack,
      userContext: sentryLib.User(
        id: user.id.toString(),
        username: user.username,
        email: user.email
      ),
      environment: env,
      extra: {
        'osVersion': osVersion,
        'deviceModel': deviceModel
      }
    );

    if (env != 'development' && !_skipError(exception)) {
      await client.capture(event: event);
    }
  }

  static Sentry setup(AppConfig config) {
    sentryLib.SentryClient sentryClient = sentryLib.SentryClient(
      dsn: config.sentryDsn,
      environmentAttributes: sentryLib.Event(release: config.packageInfo.version)
    );

    return Sentry._(
      client: sentryClient,
      osVersion: config.osVersion,
      deviceModel: config.deviceModel,
      env: config.env
    );
  }

  static bool _skipError(dynamic error) {
    return _skipErrors.map<bool>(
      (String exceptionText) => error.toString().contains(exceptionText)
    ).any((bool val) => val);
  }
}
