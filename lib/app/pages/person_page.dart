import 'package:flutter/material.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/user.dart';

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
    return Container(
      padding: EdgeInsets.only(top: 64.0, left: 8.0, right: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ListTile(
            title: Text(_zoneName ?? '',
              style: TextStyle(fontWeight: FontWeight.w500)
            ),
            leading: Icon(
              Icons.dns,
              color: Colors.blue[500],
            ),
          ),
          ListTile(
            title: Text(_agentName ?? '',
              style: TextStyle(fontWeight: FontWeight.w500)
            ),
            leading: Icon(
              Icons.contacts,
              color: Colors.blue[500],
            ),
          ),
          ListTile(
            title: Text(_email ?? '',
              style: TextStyle(fontWeight: FontWeight.w500)
            ),
            leading: Icon(
              Icons.contact_mail,
              color: Colors.blue[500],
            ),
          )
        ]
      )
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return FloatingActionButton(
      child: Icon(
        Icons.exit_to_app,
        semanticLabel: 'Выйти',
      ),
      backgroundColor: Colors.red,
      onPressed: _logout,
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
      floatingActionButton: Builder(builder: _buildActionButton),
      body: _buildBody(context)
    );
  }
}
