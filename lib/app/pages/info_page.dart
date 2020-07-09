import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/pages/person_page.dart';
import 'package:repairman/app/models/geo_point.dart';
import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/models/user.dart';
import 'package:repairman/app/modules/api.dart';
import 'package:repairman/data/data_sync.dart';
import 'package:repairman/app/utils/ui_colors.dart';

class InfoPage extends StatefulWidget {
  final GlobalKey bottomNavigationBarKey;
  InfoPage({Key key, @required this.bottomNavigationBarKey}) : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> with WidgetsBindingObserver {
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
    User user = User.currentUser;
    List<Terminal> terminals = (await Terminal.allWithDistance(user.curLatitude, user.curLongitude)).
      where((term) => term.zoneTerminal).toList();
    List<Task> tasks = await Task.all();

    _distance = (await GeoPoint.currentDistance()) ?? 0.0;
    _nearTerminalName = terminals.isNotEmpty ? terminals.first.address : 'Не найден';
    _terminalCnt = terminals.length;
    _allTasksCnt = tasks.length;
    _redCnt = tasks.where((task) => task.isRedUncompletedRoute).length;
    _yellowCnt = tasks.where((task) => task.isYellowUncompletedRoute).length;
    _greenCnt = tasks.where((task) => task.isGreenUncompletedRoute).length;
    _uncompletedTasksCnt = tasks.where((task) => task.isUncompleted).length;

    if (mounted) {
      setState(() {});
    }
  }

  void _showSnackBar(String content) {
    _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(content)));
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
                TextSpan(text: 'Геотрек: ${_distance.toStringAsFixed(3)} км\n')
              ]
            )
          )
        )
      ),
      _buildInfoCard(),
    ]..addAll(_buildErrorCards());
  }

  Widget _buildInfoCard() {
    if (User.currentUser.newVersionAvailable) {
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

  List<Widget> _buildErrorCards() {
    List<Map<String, String>> errors = [
      {
        'name': 'Ошибки синхронизации данных',
        'value': App.application.data.dataSync.syncErrors
      },
      {
        'name': 'Ошибки синхронизации геотрека',
        'value': App.application.data.dataSync.syncGeoPointsErrors
      },
      {
        'name': 'Ошибки синхронизации фотографий',
        'value': App.application.data.dataSync.syncImagesErrors
      }
    ];

    return errors.where((error) => error['value'] != null).map((error) {
      return Card(
        child: ListTile(
          isThreeLine: true,
          title: Text(error['name']),
          subtitle: Text(error['value'], style: TextStyle(color: Colors.red[300])),
        )
      );
    }).toList();
  }

  Widget _buildTasksSubtitle() {
    return RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.grey),
        children: <TextSpan>[
          TextSpan(text: 'Не выполненных: $_uncompletedTasksCnt '),
          _redCnt == 0 ? TextSpan() : TextSpan(text: '$_redCnt ', style: TextStyle(color: UIColors.redTask)),
          _yellowCnt == 0 ? TextSpan() : TextSpan(text: '$_yellowCnt ', style: TextStyle(color: UIColors.yellowTask)),
          _greenCnt == 0 ? TextSpan() : TextSpan(text: '$_greenCnt', style: TextStyle(color: UIColors.greenTask)),
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
        DateTime lastsyncTime = App.application.data.dataSync.lastDataSyncTime;
        String text = lastsyncTime != null ? DateFormat.yMMMd('ru').add_jms().format(lastsyncTime) : 'Не проводилась';
        _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text('Синхронизация: $text')));
      }
    );
  }

  void _backgroundRefresh() async {
    DateTime time = App.application.data.dataSync.lastDataSyncTime ??
      DateTime.now().subtract(Duration(minutes: 1)).subtract(DataSync.kSyncTimerPeriod);

    if (DateTime.now().difference(time) > DataSync.kSyncTimerPeriod) {
      _refreshIndicatorKey.currentState?.show();
    }
  }

  @override
  void initState() {
    super.initState();

    App.application.data.dataSync.startSyncTimer();
    WidgetsBinding.instance.addObserver(this);
    SchedulerBinding.instance.addPostFrameCallback((_) => _backgroundRefresh());

    syncStreamSubscription = App.application.data.dataSync.stream.listen((SyncEvent syncEvent) => _loadData());

    _loadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) SchedulerBinding.instance.addPostFrameCallback((_) => _backgroundRefresh());
  }

  @override
  void dispose() {
    super.dispose();

    App.application.data.dataSync.stopSyncTimer();
    WidgetsBinding.instance.removeObserver(this);
    syncStreamSubscription.cancel();
  }

  Future<void> _syncData() async {
    try {
      await App.application.data.dataSync.syncAll();
      await _loadData();
      _showSnackBar('Данные успешно обновлены');
    } on ApiException catch(e) {
      _showErrorSnackBar(e.errorMsg);
    } catch(e) {
      _showErrorSnackBar('Произошла ошибка');
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
