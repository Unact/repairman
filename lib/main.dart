import 'package:flutter/material.dart';
import 'db_synch.dart';
import 'tasks.dart';
import 'terminals.dart';
import 'terminal.dart';
import 'auth.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DbSynch cfg = new DbSynch();
  var routes;
  @override
  void initState() {
    super.initState();
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
    };
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
  _MyHomePageState({this.cfg});
  int _currentIndex = 0;
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
  static const BasicMessageChannel<String> platform =
      const BasicMessageChannel<String>(_channel, const StringCodec());
  int _counter = 0;
  String lastCoord = "";
  TextEditingController _controllerText = new TextEditingController(text: 'Test Value');

  Future<File> _getLocalFile() async {
     String dir = (await getApplicationDocumentsDirectory()).path;
     return new File('$dir/locations.txt');
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
        cfg.getGeo();
        cfg.saveGeo();
        refreshDistance();
      });

  //Это нужно, но не в таком виде
  /*
      if (cfg.login == null || cfg.login == '' ||
          cfg.password == null || cfg.password == '') {
        _currentIndex = 1;
      }
  */
    });

  }

  Future<String> _handlePlatformIncrement(String message) async {
    var a = message.split(" ");
    print("a = $a");
    if (cfg.db != null) {
      cfg.db.insert("location", {
        "latitude":   a[0],
        "longitude":  a[1],
        "accuracy":   a[2],
        "altitude":   a[3]
      });

      setState(() {
        _counter++;
        lastCoord = message;
      });
    }
    print("message = $message");

    return _emptyMessage;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> cntcolorboxes=[];

    if (cfg.redcnt>0) {cntcolorboxes.add(new Container(height: 30.0, width: 30.0, color: Colors.red, child: new Column(mainAxisAlignment: MainAxisAlignment.center, children: [new Text(cfg.redcnt.toString(), style: new TextStyle(fontSize: 16.0))])));}
    if (cfg.yellowcnt>0) {cntcolorboxes.add(new Container(height: 30.0, width: 30.0, color: Colors.yellow, child: new Column(mainAxisAlignment: MainAxisAlignment.center, children: [new Text(cfg.yellowcnt.toString(), style: new TextStyle(fontSize: 16.0))])));}
    if (cfg.greencnt>0) {cntcolorboxes.add(new Container(height: 30.0, width: 30.0, color: Colors.green, child: new Column(mainAxisAlignment: MainAxisAlignment.center, children: [new Text(cfg.greencnt.toString(), style: new TextStyle(fontSize: 16.0))])));}


    final BottomNavigationBar botNavBar = new BottomNavigationBar(
      items: [new BottomNavigationBarItem(
                    icon: const Icon(Icons.airline_seat_recline_extra),
                    title: const Text('Техник'),
                    backgroundColor: Theme.of(context).primaryColor,
              ),
              new BottomNavigationBarItem(
                    icon: const Icon(Icons.account_box),
                    title: const Text('Настройки'),
                    backgroundColor: Theme.of(context).primaryColor,
              ),
      ],
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.shifting,
      onTap: (int index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );

    final Widget mainPage = new ListView(
    shrinkWrap: true,
    children: <Widget>[
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
                   new Expanded(flex: 100, child:
                   new Column(
                     children: <Widget>[
                       new Row(children: [new Text("Ближайший: ", textAlign: TextAlign.start)]),
                       new Row(children: [new Text("проспект Тестовый, 1А", textAlign: TextAlign.start, )])
                     ],
                   )),

                   new Expanded(
                   flex:5,
                   child: new Text("${cfg.terminalcnt}", style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)))

                   ]),
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
            child: new Text(" км")
          )
        ]
      ),
      new Divider(),
      updating?  new CircularProgressIndicator() :
      new RaisedButton(
        color: Colors.blue,
        onPressed: () async {
          setState((){updating = true;});

          cfg.synchDB().then((res){
            if (res=="ok") {
              print("completed synchDB...");
              cfg.fillDB().then((v){updating = false; print("completed...");});
            } else {updating = false;}

          });

        },
        child: new Text('Обновить данные', style: new TextStyle(color: Colors.white)),
      ),
      new Divider(),
      new Text("Platform get $_counter $lastCoord"),
      new Divider(),
      new RaisedButton(
        onPressed: () async {
          File file = await _getLocalFile();
          String contents = await file.readAsString();
          setState((){
            _controllerText.text = contents;
          });
        },
        child: new Text('Файл'),
      ),
      new TextField(
          controller: _controllerText,
          maxLines: 10
      ),

/*
      new RaisedButton(
        color: Colors.red,
        onPressed: () async {
          await cfg.synchDB();
          print("completed synchDB...");
        },
        child: new Text('Тест апдейт', style: new TextStyle(color: Colors.white)),
      ) */
    ]);

    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Техник")
      ),
      body: new Container(
        padding: const EdgeInsets.all(8.0),
        child: _currentIndex==0?(mainPage):(new AuthPage(cfg: cfg))
      ),
      bottomNavigationBar: botNavBar,
    );
  }
}
