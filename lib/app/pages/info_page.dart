import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/pages/person_page.dart';
import 'package:repairman/app/models/user.dart';
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
    User user = User.currentUser();
    List<Terminal> terminals = await Terminal.all();
    List<Task> tasks = await Task.all();

    terminals.sort((term1, term2) {
      double dist1 = (term1.latitude - user.curLatitude).abs() + (term1.longitude - user.curLongitude).abs();
      double dist2 = (term2.latitude - user.curLatitude).abs() + (term2.longitude - user.curLongitude).abs();
      return dist1.compareTo(dist2);
    });

    _distance = (await Location.currentDistance()) ?? 0.0;
    _nearTerminalName = terminals.isNotEmpty ? terminals.first.address : 'Не найден';
    _terminalCnt = terminals.length;
    _allTasksCnt = tasks.length;
    _redCnt = tasks.where((task) => !task.servstatus && task.routePriority == Task.redRoute).length;
    _yellowCnt = tasks.where((task) => !task.servstatus && task.routePriority == Task.yellowRoute).length;
    _greenCnt = tasks.where((task) => !task.servstatus && task.routePriority == Task.greenRoute).length;
    _uncompletedTasksCnt = tasks.where((task) => !task.servstatus).length;

    if (mounted) {
      Timer(Duration(seconds: 10), _loadData);

      setState(() {});
    }
  }

  Future<Null> _refresh() async {
    _refreshIndicatorKey.currentState.show();
    return Future(() async {
      await _importData();
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
    String exportLocationErrors = App.application.data.dataSync.exportLocationErrors;

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
          subtitle: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey),
              children: <TextSpan>[
                TextSpan(text: 'Геотрек: $_distance км'),
                TextSpan(text: exportLocationErrors != null ? 'Ошибки: $exportLocationErrors' : '')
              ]
            )
          )
        )
      ),
      _buildErrorCard()
    ];
  }

  Widget _buildErrorCard() {
    String exportSyncErrors = App.application.data.dataSync.exportSyncErrors;

    if (exportSyncErrors != null) {
      return Card(
        child: ListTile(
          isThreeLine: true,
          title: Text('Ошибки'),
          subtitle: Text(exportSyncErrors, style: TextStyle(color: Colors.red[300])),
        )
      );
    } else {
      return Container();
    }
  }

  Widget _buildTasksSubtitle() {
    return RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.grey),
        children: <TextSpan>[
          TextSpan(text: 'Не выполненных: $_uncompletedTasksCnt '),
          _redCnt == 0 ? TextSpan() : TextSpan(text: '$_redCnt ', style: TextStyle(color: Colors.red[400])),
          _yellowCnt == 0 ? TextSpan() : TextSpan(text: '$_yellowCnt ', style: TextStyle(color: Colors.yellow[400])),
          _greenCnt == 0 ? TextSpan() : TextSpan(text: '$_greenCnt', style: TextStyle(color: Colors.green[400])),
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

    if (App.application.config.autoRefresh) {
      _importData();
    }

    _loadData();
  }

  Future<void> _importData() async {
    if (App.application.api.isLogged()) {

      try {
        await App.application.data.dataSync.importData();
        await _loadData();
      } on ApiException catch(e) {
        _showErrorSnackBar(e.errorMsg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(App.application.config.packageInfo.appName),
        actions: <Widget>[
          IconButton(
            color: Colors.white,
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (BuildContext context) => PersonPage(), fullscreenDialog: true)
              );
            }
          ),
          Builder(builder: _buildInfoButton)
        ],
      ),
      body: _buildBody(context)
    );
  }
}
