import 'package:flutter/material.dart';
import 'db_synch.dart';
import 'package:url_launcher/url_launcher.dart';

class TerminalPage extends StatefulWidget {
  final DbSynch cfg;
  TerminalPage({Key key, this.cfg}) : super(key: key);
  @override
  _TerminalPageState createState() => new _TerminalPageState(cfg: cfg);
}

class _TerminalPageState extends State<TerminalPage> {
  DbSynch cfg;
  double _latitude = 55.754226;
  double _logitude = 37.617582;
  String _code = "";
  String _srcSystemName = "";
  DateTime _lastActivityTime = new DateTime(1999, 1, 1);
  DateTime _lastPaymentTime = new DateTime(1999, 1, 1);
  String _address = "";
  String _errorText = "";
  List<Map> _tasks=[];

  _TerminalPageState({this.cfg});

  @override
  void initState() {
    super.initState();
    cfg.getTerminal().then((List<Map> list){
      cfg.getTerminalTasks().then((List<Map> tt){
        setState((){
          _latitude = list[0]["latitude"].toDouble();
          _logitude = list[0]["longitude"].toDouble();
          _code = list[0]["code"];
          _srcSystemName = list[0]["src_system_name"];
          _lastActivityTime = DateTime.parse(list[0]["lastactivitytime"]);
          _lastPaymentTime = DateTime.parse(list[0]["lastpaymenttime"]);
          _address = list[0]["address"];
          _errorText = list[0]["errortext"];
          _tasks = tt;
        });
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Терминал $_code")
      ),
      body: new Container(
        padding: const EdgeInsets.all(8.0),
        child: new ListView(
          children: [[
            new Row(
              children: [
                new Expanded(
                  flex: 18,
                  child: new Container(
                    padding: const EdgeInsets.all(4.0),
                    child: new Text(
                    "Система:",
                    textAlign: TextAlign.end,
                    style: new TextStyle(
                      color: Colors.blue
                    )
                  ))
                ),
                new Expanded(
                  flex: 50,
                  child: new Text(
                    "$_srcSystemName",
                    textAlign: TextAlign.start
                  )
                )
              ]
            ),
            new Divider(),
            new Row(
              children: [
                new Expanded(
                  flex: 18,
                  child: new Container(
                    padding: const EdgeInsets.all(4.0),
                    child: new Text(
                    "Сигнал:",
                    textAlign: TextAlign.end,
                    style: new TextStyle(
                      color: Colors.blue
                    )
                  ))
                ),
                new Expanded(
                  flex: 50,
                  child: new Text(
                    fmtSrok(_lastActivityTime),
                    textAlign: TextAlign.start
                  )
                )
              ]
            ),
            new Divider(),
            new Row(
              children: [
                new Expanded(
                  flex: 18,
                  child: new Container(
                    padding: const EdgeInsets.all(4.0),
                    child: new Text(
                    "Платеж:",
                    textAlign: TextAlign.end,
                    style: new TextStyle(
                      color: Colors.blue
                    )
                  ))
                ),
                new Expanded(
                  flex: 50,
                  child: new Text(
                    fmtSrok(_lastPaymentTime),
                    textAlign: TextAlign.start
                  )
                )
              ]
            ),
            new Divider(),
            new GestureDetector(
                       onTap: () async
                       {
                          _launchURL();
                       },
                       child: new Image.network('https://static-maps.yandex.ru/1.x/?ll=$_logitude,$_latitude&size=250,200&z=15&l=map&pt=$_logitude,$_latitude,pm2gnm', fit: BoxFit.cover),
            ),
            new Text( "$_address" ),
            new Divider(),
            new Text( "$_errorText" ),
            new Divider(),
            new Text(
              "Задачи",
              style: new TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0
              )
            )
          ], _tasks.map((var a) {

            var bcolor;

            if (a["servstatus"] == 1)
              bcolor = Colors.grey;
            else
              switch (a["routepriority"]) {
                case 3:
                  bcolor = Colors.red;
                  break;
                case 2:
                  bcolor = Colors.yellow;
                  break;
                case 1:
                  bcolor = Colors.green;
                  break;
                case 0:
                  bcolor = Colors.white;
              }

            return
              new GestureDetector(
              onTap: () async {
                  cfg.curTask = a["id"];
                  await Navigator.of(context).pushNamed(taskSubpageRoute);
              },
              child: new Column(
              children: [
                new Container(
                  color: bcolor,
                  height: 32.0,
                  child: new Row(
                    children: [
                      new Expanded(
                        flex: 2,
                        child: new Text("${a["routepriority"]}", textAlign: TextAlign.end)
                      ),
                      new Expanded(
                        flex: 1,
                        child: new Text(":")
                      ),
                      new Expanded(
                        flex: 20,
                        child: new Text(a["terminalbreakname"])
                      ),
                      new Expanded(
                        flex: 10,
                        child: new Text(fmtSrok(DateTime.parse(a["dobefore"])),
                          textAlign: TextAlign.end,
                          style: new TextStyle(color: Colors.blue)
                        )
                      ),
                    ]
                  )
                ),
                new Divider(),
              ]
            ));
          }).toList()].expand((x) => x).toList()
        )
      )
    );
  }
  _launchURL() async {
    String url = 'https://maps.yandex.ru/?pt=$_logitude,$_latitude&ll=$_logitude,$_latitude&z=18&l=map';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
