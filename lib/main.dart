import 'package:flutter/material.dart';
import 'db_synch.dart';
import 'tasks.dart';
import 'terminals.dart';
import 'auth.dart';
import 'package:sqflite/sqflite.dart';

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
          cgroupPageRoute: (BuildContext context) => new CGroupPage(cfg: cfg),
    };
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Репейрмэн',
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


@override
void initState() {
  super.initState();
  loading = true;
  cfg.initDB().then((Database db){
    print('Connected to db!');

//Это нужно, но не в таком виде
/*
    if (cfg.login == null || cfg.login == '' ||
        cfg.password == null || cfg.password == '') {
      _currentIndex = 1;
    }
*/


  });

}



  @override
  Widget build(BuildContext context) {

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

  final Widget mainPage = new Column(
  children: <Widget>[
    new GestureDetector(
     onTap: () async
     {
        await Navigator.of(context).pushNamed(taskPageRoute);
     },
     child: new Container(
       color: Colors.yellow,
       child: new Text('Задачи'),
       height: 40.0,
     ),
   ),
   new GestureDetector(
    onTap: () async
    {
       await Navigator.of(context).pushNamed(terminalsPageRoute);
    },
    child: new Container(
      color: Colors.yellow,
      child: new Text('Терминалы'),
      height: 60.0,

    ),
  ),
  new GestureDetector(
   onTap: () async
   {
      await Navigator.of(context).pushNamed(cgroupPageRoute);
   },
   child: new Container(
     color: Colors.yellow,
     child: new Text('ЗИПы тест'),
     height: 60.0,

   ),
 ),

new RaisedButton(
  color: Colors.blue,
  onPressed: () async {

    await cfg.fillDB();
    print("completed...");

  },
  child: new Text('тест', style: new TextStyle(color: Colors.white)),
)
  ],
);


    return new Scaffold(
      appBar: new AppBar(
        title: new Text("R E P A I R M A N")
      ),
      body: _currentIndex==0?(mainPage):(new AuthPage(cfg: cfg)),
      bottomNavigationBar: botNavBar,
    );
  }
}
