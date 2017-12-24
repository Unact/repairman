import 'package:flutter/material.dart';
import 'db_synch.dart';


Widget oneTerminal(BuildContext context, String code, DateTime lastactivitytime, String address) {


return new GestureDetector(
           onTap: () async
           {
              //Здесь будет рутинг
              //await Navigator.of(context).pushNamed(terminalSubpageRoute);
           },
           child: new Container(
                height: 48.0,
                child:
                   new Column(
                     children: <Widget>[
                       new Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: <Widget>[
                           new Text(code),
                           new Text(lastactivitytime.toString(), style: new TextStyle(color: Colors.blue)),
                         ]
                       ),
                       new Text(address, style: new TextStyle(color: Colors.red))
                     ]
                   )
                )
         );
}





class TerminalsPage extends StatefulWidget {
  TerminalsPage({Key key, this.cfg}) : super(key: key);
  final DbSynch cfg;
  @override
  _TerminalsPageState createState() => new _TerminalsPageState(cfg: cfg);
}

class _TerminalsPageState extends State<TerminalsPage> {
  _TerminalsPageState({this.cfg});
  DbSynch cfg;
  List<Widget> terminallist;
  List<Map> _terminals=[];

  @override
  void initState() {
    super.initState();
    cfg.getTerminals().then((List<Map> list){
      setState((){
        _terminals = list;
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    terminallist = [];
    for (var r in _terminals) {

      terminallist.add(oneTerminal(context,r["code"],DateTime.parse(r["lastactivitytime"]),r["address"]));

    }


    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Терминалы")
      ),
      body: new ListView(
      shrinkWrap: true,
      children: terminallist,
    )
    );
  }
}
