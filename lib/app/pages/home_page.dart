import 'package:flutter/material.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/pages/info_page.dart';
import 'package:repairman/app/pages/tasks_page.dart';
import 'package:repairman/app/pages/terminals_page.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  final List<Widget> _children = [
    InfoPage(),
    TasksPage(),
    TerminalsPage()
  ];

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (int index) => setState(() => _currentIndex = index),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          title: Text('Главная')
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          title: Text('Задачи'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.computer),
          title: Text('Терминалы'),
        )
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return _children[_currentIndex];
  }

  @override
  void initState() {
    super.initState();

    if (App.application.api.isLogged()) {
      App.application.data.dataSync.startSyncTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      bottomNavigationBar: _buildBottomNavigationBar(context),
      body: _buildBody(context)
    );
  }
}
