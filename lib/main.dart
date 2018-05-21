import 'package:flutter/material.dart';
import 'db_synch.dart';
import 'tasks.dart';
import 'terminals.dart';
import 'terminal.dart';
import 'auth.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final DbSynch cfg = new DbSynch();
  var routes;
  AppLifecycleState _lastLifecyleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    routes = <String, WidgetBuilder>{
          taskPageRoute: (BuildContext context) => new TaskPage(cfg: cfg),
          terminalsPageRoute: (BuildContext context) => new TerminalsPage(cfg: cfg),
          taskSubpageRoute: (BuildContext context) => new TaskSubpage(cfg: cfg),
          taskSubpageCgroupRoute: (BuildContext context) => new CGroupPage(cfg: cfg),
          taskSubpageComponentRoute: (BuildContext context) => new ComponentPage(cfg: cfg),
          taskDefectsSubpageRoute: (BuildContext context) => new TaskDefectsSubpage(cfg: cfg),
          taskRepairsSubpageRoute: (BuildContext context) => new TaskRepairsSubpage(cfg: cfg),
          terminalPageRoute: (BuildContext context) => new TerminalPage(cfg: cfg),
          taskSubpageRouteComment: (BuildContext context) => new TaskCommentSubpage(cfg: cfg),
          loginPageRoute: (BuildContext context) => new AuthPage(cfg: cfg),
    };
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("LifecycleWatcherState#didChangeAppLifecycleState state=${state.toString()}");
    setState(() {
      _lastLifecyleState = state;
    });
    if (_lastLifecyleState == AppLifecycleState.paused) {
      print("paused!!!");
    }
    if (_lastLifecyleState == AppLifecycleState.resumed) {
      print("resumed!!!");
    }

  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Семен',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(cfg: cfg),
      routes: routes,
    );
  }
}


class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.cfg}) : super(key: key);
  final DbSynch cfg;
  @override
  _MyHomePageState createState() => new _MyHomePageState(cfg: cfg);
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();
  DbSynch cfg;
  bool sendingClose = false;
  bool sendingInit = false;
  bool sendingConnect = false;
  bool sendingPwd = false;
  bool loading = false;
  double _distance = 0.0;
  bool updating=false;
  static const String _channel = 'increment';
  static const String _emptyMessage = '';
  static const BasicMessageChannel<String> platform = const BasicMessageChannel<String>(_channel, const StringCodec());
  int _counter = 0;
  String _nearTerminal = "....";
  Widget syncstatuswidget;
  Timer _timer;

  _MyHomePageState({this.cfg}) {
      print("_MyHomePageState#constructor, creating new Timer.periodic");
      _timer = new Timer.periodic(
          new Duration(minutes: 1), _doTimer);
  }

  void _doTimer(Timer t) {
    print("_timer!");
    cfg.needSync().then( (bool isSync) {
      if (isSync) _refreshDB();
    });
  }

  void refreshDistance(){
    cfg.getDistance().then((double res) {
      setState((){
        _distance = res;
      });
    });
    new Timer(const Duration(seconds: 10), refreshDistance);
  }

  @override
  void initState() {
    super.initState();

    platform.setMessageHandler(_handlePlatformIncrement);

    loading = true;
    cfg.initDB().then((Database db){
      print('Connected to db!');
      cfg.getMainPageCnt().then((v){
        setState((){});
        cfg.saveGeo();
        refreshDistance();
      });

      cfg.needSync().then( (bool isSync) {
        if (isSync) _refreshDB();
      });

      if (cfg.login == null || cfg.login == '' ||
          cfg.password == null || cfg.password == '') {
        Navigator.of(context).pushNamed(loginPageRoute);
      }

      _firebaseMessaging.configure(
          onMessage: (Map<String, dynamic> message) {
            print("onMessage: $message");
            _refreshDB();
          },
          onLaunch: (Map<String, dynamic> message) {
            print("onLaunch: $message");
            _refreshDB();
          },
          onResume: (Map<String, dynamic> message) {
            print("onResume: $message");
            _refreshDB();
          },
      );

      _firebaseMessaging.requestNotificationPermissions(
          const IosNotificationSettings(sound: true, badge: true, alert: true)
      );

      _firebaseMessaging.onIosSettingsRegistered
            .listen((IosNotificationSettings settings) {
          print("Settings registered: $settings");
      });
      _firebaseMessaging.getToken().then((String token) {
        cfg.firebaseToken = token;
        print("Push Messaging token: $token");
      });

    });
  }

  Future<String> _handlePlatformIncrement(String message) async {
    var a = message.split(" ");
    if (cfg.db != null) {
      cfg.lastLatitude = double.parse(a[0]);
      cfg.lastLongitude = double.parse(a[1]);
      cfg.db.insert("location", {
        "latitude":   a[0],
        "longitude":  a[1],
        "accuracy":   a[2],
        "altitude":   a[3]
      });

      if (_counter > 7 ) {
        cfg.saveGeo();
        _counter = 0;
      }
      _counter++;

      cfg.getTerminals(true).then((List<Map> list){
        if (list.length > 0) {
          setState((){
            _nearTerminal = list[0]["address"];
          });
        }
      });
    }
    return _emptyMessage;
  }

  Future<Null> _refreshDB() async {
    setState((){updating = true;});
    cfg.synchDB().then((res){
      if (res=="ok") {
        print("completed synchDB...");
        cfg.fillDB().then((v){
          if (v != null) {
            showDialog(context: context,
              builder: (BuildContext context) {
                return new AlertDialog(
                  title: new Text("Ошибка обновления базы"),
                  content: new Text("$v"),
                );
              }
            );
          }
          cfg.getMainPageCnt().then((v){
            setState((){updating = false;});
          });
          print("completed...");
        });
      } else {
        cfg.getMainPageCnt().then((v){
          setState((){updating = false;});
        });
        showDialog(context: context,
          builder: (BuildContext context) {
            return new AlertDialog(
              title: new Text("Ошибка сохранения базы"),
              content: new Text("$res"),
            );
          }
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> cntcolorboxes=[];

    if (cfg.redcnt>0) {cntcolorboxes.add(new Container(height: 30.0, width: 30.0, color: Colors.red, child: new Column(mainAxisAlignment: MainAxisAlignment.center, children: [new Text(cfg.redcnt.toString(), style: new TextStyle(fontSize: 16.0))])));}
    if (cfg.yellowcnt>0) {cntcolorboxes.add(new Container(height: 30.0, width: 30.0, color: Colors.yellow, child: new Column(mainAxisAlignment: MainAxisAlignment.center, children: [new Text(cfg.yellowcnt.toString(), style: new TextStyle(fontSize: 16.0))])));}
    if (cfg.greencnt>0) {cntcolorboxes.add(new Container(height: 30.0, width: 30.0, color: Colors.green, child: new Column(mainAxisAlignment: MainAxisAlignment.center, children: [new Text(cfg.greencnt.toString(), style: new TextStyle(fontSize: 16.0))])));}

    if (cfg.syncing==1) {
      syncstatuswidget = new Container(
           padding: const EdgeInsets.all(4.0),
           height: 40.0,
           child:
             new Row(
               children: [new Expanded(flex: 90, child: new Text("Сохранение изменений...")),
                          new Expanded(flex: 10, child: new CircularProgressIndicator())]
             )
           );
    } else {
      syncstatuswidget = new Container(
           padding: const EdgeInsets.all(4.0),
           height: 40.0,
           child:
            null
           );
    }


    final Widget mainPage = new ListView(
    shrinkWrap: true,
    children: <Widget>[
      new Container(
        height: 20.0,
        child: new Text("${cfg.agentName} ${cfg.zoneName} синх:${new DateFormat("HH:mm:ss").format(cfg.lastSync)}")
      ),
      new Container(
        height: 20.0,
        child: new Text("Задачи"),
        color: Colors.grey.shade300,
      ),
      new GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () async
        {
          await Navigator.of(context).pushNamed(taskPageRoute);
        },
        child: new Container(
          padding: const EdgeInsets.all(4.0),
          height: 40.0,
          child: new Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               new Expanded(flex: 40, child: new Text('Невыполненных: ${cfg.uncomplcnt}', style: new TextStyle(fontSize: 16.0))),
               new Expanded(flex: 25, child: new Row(children: cntcolorboxes)),
               new Expanded(flex: 8, child: new Text("${cfg.allcnt}", textAlign: TextAlign.right,style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)))
             ]
          ),
        ),
      ),
      new Container(
        height: 20.0,
        child: new Text("Терминалы"),
        color: Colors.grey.shade300,
      ),
      new GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () async {await Navigator.of(context).pushNamed(terminalsPageRoute);},
        child: new Container(
          padding: const EdgeInsets.all(4.0),
          height: 40.0,
          child:
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              new Expanded(flex: 10, child:
                new Row(
                  children: <Widget>[
                    new Text("Ближайший: ", textAlign: TextAlign.start),
                    new Expanded(child:new Text(_nearTerminal, maxLines: 5, textAlign: TextAlign.start))
                  ],
                )),
                new Expanded(
                  flex:1,
                  child: new Text("${cfg.terminalcnt}", textAlign: TextAlign.end, style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)))
            ]
          ),
        )
      ),
      new Container(
        height: 20.0,
        child: new Text("Управление"),
        color: Colors.grey.shade300,
      ),
      new Row(
        children: [
          new Expanded(
            flex: 5,
            child: new Text("Геотрек:")
          ),
          new Expanded(
            flex: 10,
            child: new Text("${numFormat.format(_distance)}", textAlign: TextAlign.end)
          ),
          new Expanded(
            flex: 2,
            child: new Text(" км $_counter")
          )
        ]
      ),
      new Divider(),
      updating?  new CircularProgressIndicator() :
      (cfg.syncing!=1)?
      new RaisedButton(
        color: Colors.blue,
        onPressed: () async {
          _refreshDB();
        },
        child: new Text('Обновить данные', style: new TextStyle(color: Colors.white)),
      ):
      new RaisedButton(
        color: Colors.grey,
        onPressed: ()  {},
        child: new Text('Обновить данные', style: new TextStyle(color: Colors.white)),
      ),
      syncstatuswidget
    ]);

    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Техник"),
        actions: <Widget>[
          new IconButton(
            icon: const Icon(Icons.account_box),
            onPressed: () { Navigator.of(context).pushNamed(loginPageRoute); }
          )
        ],
      ),
      body: new Container(
        padding: const EdgeInsets.all(8.0),
        child: mainPage
      )
    );
  }
}
