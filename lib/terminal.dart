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
  double _latitude;
  double _logitude;
  String _code;
  String _srcSystemName;
  DateTime _lastActivityTime;
  DateTime _lastPaymentTime;
  String _address;
  String _errorText;
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
          tt = _tasks;
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
          children: [
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
                    dateFormat.format(_lastActivityTime),
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
                    dateFormat.format(_lastPaymentTime),
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
            ) /*,
            new ListView(
              children: _tasks.map((var a) {
                return new Text("terminalbreakname");
              }).toList()
            )*/
          ]
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
