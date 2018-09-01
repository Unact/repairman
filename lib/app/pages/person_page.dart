import 'package:flutter/material.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/user.dart';
import 'package:repairman/app/pages/settings_page.dart';

class PersonPage extends StatefulWidget {
  PersonPage({Key key}) : super(key: key);

  @override
  _PersonPageState createState() => _PersonPageState();
}

class _PersonPageState extends State<PersonPage> {
  String _agentName;
  String _zoneName;
  String _email;

  void _logout() async {
    await App.application.api.logout();
    App.application.data.dataSync.stopSyncTimer();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (Route<dynamic> route) => false);
  }

  void _loadData() async {
    User user = User.currentUser();

    _email = user.email;
    _agentName = user.agentName;
    _zoneName = user.zoneName;

    setState(() {});
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(top: 16.0, left: 8.0, right: 8.0),
      children: [
        _buildInfo(),
        Divider(height: 1.0, color: Colors.grey),
        _buildHelp()
      ]
    );
  }

  Widget _buildHelp() {
    return Column(
      children: [
        ListTile(
          title: Text(
            'Настройки',
            style: TextStyle(fontWeight: FontWeight.w500)
          ),
          leading: Icon(
            Icons.settings,
            color: Colors.grey,
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (BuildContext context) => SettingsPage(), fullscreenDialog: true)
            );
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: Text(
            'Выйти',
            style: TextStyle(fontWeight: FontWeight.w500)
          ),
          leading: Icon(
            Icons.exit_to_app,
            color: Colors.red,
          ),
          onTap: _logout
        ),
      ]
    );
  }

  Widget _buildInfo() {
    return Column(
      children: [
        ListTile(
          title: Text(
            _zoneName ?? '',
            style: TextStyle(fontWeight: FontWeight.w500)
          ),
          leading: Icon(
            Icons.dns,
            color: Colors.blue[500],
          ),
        ),
        ListTile(
          title: Text(
            _agentName ?? '',
            style: TextStyle(fontWeight: FontWeight.w500)
          ),
          leading: Icon(
            Icons.contacts,
            color: Colors.blue[500],
          ),
        ),
        ListTile(
          title: Text(
            _email ?? '',
            style: TextStyle(fontWeight: FontWeight.w500)
          ),
          leading: Icon(
            Icons.contact_mail,
            color: Colors.blue[500],
          ),
        )
      ]
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Пользователь'),
      ),
      body: _buildBody(context)
    );
  }
}
