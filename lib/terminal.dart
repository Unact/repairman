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

  _TerminalPageState({this.cfg});
  @override
  void initState() {
    super.initState();
    cfg.getTerminal().then((List<Map> list){
      setState((){
        _latitude = list[0]["latitude"].toDouble();
        _logitude = list[0]["longitude"].toDouble();
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Карточка терминала")
      ),
      body: new Container(
        padding: const EdgeInsets.all(8.0),
        child: new ListView(
          children: [
            new Text("Тест карты"),
            new GestureDetector(
                       onTap: () async
                       {
                          _launchURL();
                       },
                       child: new Image.network('https://static-maps.yandex.ru/1.x/?ll=$_logitude,$_latitude&size=250,200&z=15&l=map&pt=$_logitude,$_latitude,pm2gnm', fit: BoxFit.cover),
            ),
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
