import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/pages/person_page.dart';
import 'package:repairman/app/models/location.dart';
import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/models/user.dart';
import 'package:repairman/app/modules/api.dart';
import 'package:repairman/data/data_sync.dart';

class InfoPage extends StatefulWidget {
  final GlobalKey bottomNavigationBarKey;
  InfoPage({Key key, @required this.bottomNavigationBarKey}) : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> with WidgetsBindingObserver {
  static const Duration _kWaitDuration = Duration(milliseconds: 300);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  StreamSubscription<SyncEvent> syncStreamSubscription;

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
    List<Terminal> terminals = await Terminal.allWithDistance(user.curLatitude, user.curLongitude);
    List<Task> tasks = await Task.all();

    _distance = (await Location.currentDistance()) ?? 0.0;
    _nearTerminalName = terminals.isNotEmpty ? terminals.first.address : 'Не найден';
    _terminalCnt = terminals.length;
    _allTasksCnt = tasks.length;
    _redCnt = tasks.where((task) => !task.servstatus && task.routePriority == Task.redRoute).length;
    _yellowCnt = tasks.where((task) => !task.servstatus && task.routePriority == Task.yellowRoute).length;
    _greenCnt = tasks.where((task) => !task.servstatus && task.routePriority == Task.greenRoute).length;
    _uncompletedTasksCnt = tasks.where((task) => !task.servstatus).length;

    if (mounted) {
      setState(() {});
    }
  }

  void _showErrorSnackBar(String content) {
    _scaffoldKey.currentState?.showSnackBar(SnackBar(
      content: Text(content),
      action: SnackBarAction(
        label: 'Повторить',
        onPressed: _refreshIndicatorKey.currentState?.show
      )
    ));
  }

  Widget _buildBody(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _syncData,
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
          onTap: () {
            BottomNavigationBar navigationBar = widget.bottomNavigationBarKey.currentWidget;
            navigationBar.onTap(1);
          },
          isThreeLine: true,
          title: Text('Задачи'),
          subtitle: _buildTasksSubtitle()
        ),
      ),
      Card(
        child: ListTile(
          onTap: () {
            BottomNavigationBar navigationBar = widget.bottomNavigationBarKey.currentWidget;
            navigationBar.onTap(2);
          },
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
                TextSpan(text: 'Геотрек: ${_distance.toStringAsFixed(3)} км\n'),
                TextSpan(text: exportLocationErrors != null ? 'Ошибки: $exportLocationErrors' : '')
              ]
            )
          )
        )
      ),
      _buildInfoCard(),
      _buildErrorCard()
    ];
  }

  Widget _buildInfoCard() {
    if (App.application.config.newVersionAvailable) {
      return Card(
        child: ListTile(
          isThreeLine: true,
          title: Text('Информация'),
          subtitle: Text('Доступна новая версия приложения'),
        )
      );
    } else {
      return Container();
    }
  }

  Widget _buildErrorCard() {
    String syncErrors = App.application.data.dataSync.syncErrors;

    if (syncErrors != null) {
      return Card(
        child: ListTile(
          isThreeLine: true,
          title: Text('Ошибки'),
          subtitle: Text(syncErrors, style: TextStyle(color: Colors.red[300])),
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
        String text = lastsyncTime != null ? DateFormat.yMMMd('ru').add_jms().format(lastsyncTime) : 'Не проводилась';
        _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text('Синхронизация: $text')));
      }
    );
  }

  void _backgroundRefresh() async {
    DateTime time = App.application.data.dataSync.lastSyncTime ??
      DateTime.now().subtract(Duration(minutes: 1)).subtract(DataSync.kSyncTimerPeriod);

    if (DateTime.now().difference(time) > DataSync.kSyncTimerPeriod) {
      // Чтобы корректно отобразить RefreshIndicator надо подождать, когда закончится построение виджетов страницы
      await Future.delayed(_kWaitDuration);
      _refreshIndicatorKey.currentState?.show();
    }
  }

  @override
  void initState() {
    super.initState();

    if (User.currentUser().isLogged()) {
      App.application.data.dataSync.startSyncTimer();
      WidgetsBinding.instance.addObserver(this);
      _backgroundRefresh();
    }

    syncStreamSubscription = App.application.data.dataSync.stream.listen((SyncEvent syncEvent) => _loadData());

    _loadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _backgroundRefresh();
  }

  @override
  void dispose() {
    super.dispose();

    if (User.currentUser().isLogged()) {
      WidgetsBinding.instance.removeObserver(this);
    }

    syncStreamSubscription.cancel();
  }

  Future<void> _syncData() async {
    try {
      await App.application.data.dataSync.syncData();
      await _loadData();
    } on ApiException catch(e) {
      _showErrorSnackBar(e.errorMsg);
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
