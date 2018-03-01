import 'package:flutter/material.dart';
import 'db_synch.dart';


Widget oneTerminal(DbSynch cfg, BuildContext context, String code, DateTime lastactivitytime, String address, int terminalId) {


return new GestureDetector(
           behavior: HitTestBehavior.translucent,
           onTap: () async
           {
              cfg.dbTerminalId = terminalId;
              await Navigator.of(context).pushNamed(terminalPageRoute);
           },
           child: new Container(
                height: 48.0,
                padding: const EdgeInsets.all(4.0),
                child:
                   new Column(
                     children: <Widget>[
                       new Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: <Widget>[
                           new Text(code),
                           new Text(fmtSrok(lastactivitytime), style: new TextStyle(color: Colors.blue)),
                         ]
                       ),
                       new Text(address, style: new TextStyle(fontSize: 10.0))
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
  bool isError = true;

  @override
  void initState() {
    super.initState();
    cfg.getTerminals(isError).then((List<Map> list){
      setState((){
        _terminals = list;
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    terminallist = [];
    for (var r in _terminals) {
      terminallist.add(oneTerminal(cfg, context,r["code"],safeParseDate(r["lastactivitytime"]),r["address"], r["id"] ));
      terminallist.add(new Divider(height: 1.0));
    }


    return new Scaffold(
      appBar: new AppBar(
        title: new Row(
          children: [
            new Expanded(flex: 3, child: new Text("Терминалы")),
            new Expanded(flex: 2, child: new GestureDetector(
                       onTap: () async {
                         bool f = isError?false:true;
                         cfg.getTerminals(f).then((List<Map> list){
                           setState((){
                             isError = f;
                             _terminals = list;
                           });
                         });
                       },
                       child: isError?new Text("Все", textAlign: TextAlign.end):new Text("С ошибкой", textAlign: TextAlign.end))
            )
        ]),
      ),
      body: new ListView(
      shrinkWrap: true,
      children: terminallist,
    )
    );
  }
}
