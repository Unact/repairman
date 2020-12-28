import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/user.dart';
import 'package:repairman/app/pages/home_page.dart';
import 'package:repairman/app/pages/login_page.dart';

void main() async {
  App app = await App.init();

  User.init();
  app.config.loadSaved();

  runZonedGuarded<Future<void>>(() async {
    runApp(MaterialApp(
      title: app.title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        platform: TargetPlatform.android
      ),
      home: User.currentUser.isLogged() ? HomePage() : LoginPage(),
      locale: Locale('ru', 'RU'),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', 'US'),
        Locale('ru', 'RU'),
      ]
    ));
  }, (Object error, StackTrace stackTrace) {
    app.reportError(error, stackTrace);
  });
}
