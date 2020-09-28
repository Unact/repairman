import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/user.dart';
import 'package:repairman/app/modules/api.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextStyle headingStyle = TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, height: 24.0/15.0);

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(top: 16.0, left: 8.0, right: 8.0,),
      children: [
        Text(App.application.config.packageInfo.appName, style: headingStyle),
        _buildSwitches(),
        Padding(
          padding: EdgeInsets.only(top: 16.0),
          child: Text('О программе', style: headingStyle),
        ),
        _buildInfo()
      ]
    );
  }

  Widget _buildInfoRow(String leftStr, String rightStr) {
    return Padding(
      padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(leftStr)),
          Text(rightStr)
        ]
      )
    );
  }

  Widget _buildInfo() {
    return Column(
      children: <Widget>[
        _buildInfoRow(
          'Версия',
          App.application.config.packageInfo.version + '+' + App.application.config.packageInfo.buildNumber
        ),
        User.currentUser.newVersionAvailable ?
          RaisedButton(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
            child: Text('Обновить приложение'),
            onPressed: _launchAppUpdate,
            color: Colors.blueAccent,
            textColor: Colors.white,
          ) :
          Container()
      ]
    );
  }

  Widget _buildSwitches() {
    User user = User.currentUser;

    return Column(
      children: [
        Row(
          children: <Widget>[
            Expanded(child: Text('Авто-обновление')),
            Switch(
              value: App.application.config.autoRefresh,
              onChanged: (bool value) async {
                App.application.config.autoRefresh = value;
                await App.application.config.save();
                setState(() {});
              }
            )
          ]
        ),
        Row(
          children: <Widget>[
            Expanded(child: Text('Геокодирование')),
            Switch(
              value: App.application.config.geocode,
              onChanged: (bool value) async {
                App.application.config.geocode = value;
                await App.application.config.save();
                setState(() {});
              }
            )
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(child: Text('Push-сообщения')),
            Switch(
              value: user.firebaseSubscribed,
              onChanged: (bool value) async {
                try {
                  await user.subscribeToFirebase(value);
                } on ApiException catch(e) {
                  _showErrorSnackBar(e.errorMsg);
                }
                setState(() {});
              }
            )
          ],
        )
      ]
    );
  }

  void _showErrorSnackBar(String content) {
    _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(content)));
  }

  Future<void> _launchAppUpdate() async {
    final String androidUpdateUrl = "https://github.com/Unact/repairman/releases/download/${User.currentUser.remoteVersion}/app-release.apk";
    final String iosUpdateUrl = 'itms-services://?action=download-manifest&url=https://unact.github.io/mobile_apps/repairman/manifest.plist';
    String url = Platform.isIOS ? iosUpdateUrl : androidUpdateUrl;

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _showErrorSnackBar('Произошла ошибка');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Настройки'),
      ),
      body: _buildBody(context)
    );
  }
}
