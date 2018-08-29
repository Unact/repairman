import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/location.dart';
import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/modules/api.dart';

class InfoPage extends StatefulWidget {
  InfoPage({Key key}) : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  double _distance = 0.0;
  String _nearTerminalName = '....';
  int _terminalCnt = 0;
  int _redCnt = 0;
  int _yellowCnt = 0;
  int _greenCnt = 0;
  int _uncompletedTasksCnt = 0;
  int _allTasksCnt = 0;

  Future<void> _loadData() async {
    if (App.application.api.isLogged()) {
      try {
        await App.application.data.dataSync.importData();
        List<Terminal> terminals = await Terminal.all();
        List<Task> tasks = await Task.all();

        _distance = (await Location.currentDistance()) ?? 0.0;
        _nearTerminalName = terminals.first?.address ?? 'Не найден';
        _terminalCnt = terminals.length;
        _allTasksCnt = tasks.length;
        _redCnt = tasks.where((task) => !task.servstatus && task.routePriority == Task.redRoute).length;
        _yellowCnt = tasks.where((task) => !task.servstatus && task.routePriority == Task.yellowRoute).length;
        _greenCnt = tasks.where((task) => !task.servstatus && task.routePriority == Task.greenRoute).length;
        _uncompletedTasksCnt = tasks.where((task) => !task.servstatus).length;

        if (mounted) {
          setState((){});
        }
      } on ApiException catch(e) {
        _showErrorSnackBar(e.errorMsg);
      }
    }
  }

  Future<Null> _refresh() async {
    _refreshIndicatorKey.currentState.show();
    return Future(() async {
      await _loadData();
    });
  }

  void _showErrorSnackBar(String content) {
    _scaffoldKey.currentState?.showSnackBar(SnackBar(
      content: Text(content),
      action: SnackBarAction(
        label: 'Повторить',
        onPressed: _refresh
      )
    ));
  }

  Widget _buildBody(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _refresh,
      child: ListView.builder(
        padding: EdgeInsets.only(top: 24.0, left: 8.0, right: 8.0),
        itemCount: 1,
        itemBuilder: (BuildContext context, int index) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildInfoCards(context)
          );
        }
      )
    );
  }

  List<Widget> _buildInfoCards(BuildContext context) {
    return <Widget>[
      Card(
        child: ListTile(
          isThreeLine: true,
          title: Text('Задачи'),
          subtitle: _buildTasksSubtitle()
        ),
      ),
      Card(
        child: ListTile(
          isThreeLine: true,
          title: Text('Терминалы'),
          subtitle: Text('Ближайший: $_nearTerminalName\nВсего: $_terminalCnt'),
        ),
      ),
      Card(
        child: ListTile(
          isThreeLine: true,
          title: Text('Управление'),
          subtitle: Text('Геотрек: $_distance км'),
        ),
      ),
    ];
  }

  Widget _buildTasksSubtitle() {
    return RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.grey),
        children: <TextSpan>[
          TextSpan(text: 'Не выполненных: $_uncompletedTasksCnt '),
          _redCnt == 0 ? TextSpan() : TextSpan(text: '$_redCnt ', style: TextStyle(color: Colors.red)),
          _yellowCnt == 0 ? TextSpan() : TextSpan(text: '$_yellowCnt ', style: TextStyle(color: Colors.yellow)),
          _greenCnt == 0 ? TextSpan() : TextSpan(text: '$_greenCnt', style: TextStyle(color: Colors.green)),
          TextSpan(text: '\nВсего: $_allTasksCnt')
        ]
      )
    );
  }

  Widget _buildInfoButton(BuildContext context) {
    return IconButton(
      color: Colors.white,
      icon: Icon(Icons.info),
      onPressed: () {
        DateTime lastsyncTime = App.application.data.dataSync.lastSyncTime;
        String content = lastsyncTime != null ? DateFormat.yMMMd('ru').add_jm().format(lastsyncTime) : 'Не проводилась';
        _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text('Синхронизация: $content')));
      }
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
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Техник'),
        actions: <Widget>[
          IconButton(
            color: Colors.white,
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/person');
            }
          ),
          Builder(builder: _buildInfoButton)
        ],
      ),
      body: _buildBody(context)
    );
  }
}
