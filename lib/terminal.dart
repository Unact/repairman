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
  _TerminalPageState({this.cfg});
  @override
  void initState() {
    super.initState();
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
            new Image.network('https://static-maps.yandex.ru/1.x/?ll=37.620070,55.753630&size=250,200&z=13&l=map&pt=37.620070,55.753630,pm2gnm', fit: BoxFit.cover),
            new RaisedButton(
              onPressed: _launchURL,
              child: new Text('Показать терминал на карте'),
            ),
          ]
        )
      )
    );
  }
  _launchURL() async {
    const url = 'https://maps.yandex.ru/?pt=30.335429,59.944869&ll=30.335429,59.944869&z=18&l=map';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
