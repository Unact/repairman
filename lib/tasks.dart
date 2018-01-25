import 'package:flutter/material.dart';
import 'db_synch.dart';




String fmtSrok(DateTime date) {

  String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

 DateTime today = new DateTime(new DateTime.now().year, new DateTime.now().month, new DateTime.now().day);
 DateTime yesterday = today.subtract(new Duration(days:1));
 DateTime yesterday2 = today.subtract(new Duration(days:2));
 DateTime tomorrow = today.add(new Duration(days:1));
 DateTime tomorrow2 = today.add(new Duration(days:2));
 DateTime tomorrow3 = today.add(new Duration(days:3));
 String strdate;

if ((date.isAfter(yesterday2))&&(date.isBefore(yesterday))) {strdate="Позавчера, ";}
if ((date.isAfter(yesterday))&&(date.isBefore(today))) {strdate="Вчера, ";}
if ((date.isAfter(today))&&(date.isBefore(tomorrow))) {strdate="";}
if ((date.isAfter(tomorrow))&&(date.isBefore(tomorrow2))) {strdate="Завтра, ";}
if ((date.isAfter(tomorrow2))&&(date.isBefore(tomorrow3))) {strdate="Послезавтра, ";}
if (strdate==null) {strdate = _twoDigits(date.day)+"."+_twoDigits(date.month)+" ";}

return strdate+date.hour.toString()+":"+_twoDigits(date.minute);

}


Widget oneTask(DbSynch cfg, BuildContext context, DateTime dobefore, int servstatus, int routepriority, int task_id, String code, String address) {
var bcolor;
var tcolor;

if (servstatus == 1) {bcolor = Colors.grey; tcolor = Colors.blueGrey;}
else
  switch (routepriority) {
    case 3:
      bcolor = Colors.red;
      tcolor = Colors.white;
      break;
    case 2:
      bcolor = Colors.yellow;
      tcolor = Colors.black;
      break;
    case 1:
      bcolor = Colors.green;
      tcolor = Colors.black;
      break;
    case 0:
      bcolor = Colors.white;
      tcolor = Colors.black;
  }

return new GestureDetector(
           onTap: () async
           {
              cfg.cur_task = task_id;
              await Navigator.of(context).pushNamed(taskSubpageRoute);
           },
           child: new Container(
                color: bcolor,
                height: 48.0,
                child:

                //Почему-то не работает выравнивание во вложенном Column, если вложить его в Row

                //child: new Row(
                //  children: <Widget>[
                   /*new Container(
                     width: 40.0,   //это работает!
                     child: const FlutterLogo(),
                   ),*/
                   new Column(
                     children: <Widget>[
                       new Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: <Widget>[
                           new Text(code),
                           new Text(fmtSrok(dobefore), style: new TextStyle(color: Colors.blue)),
                         ]
                       ),
                       new Text(address, style: new TextStyle(color: tcolor, fontSize: 12.0))
                     ]
                   )
                  //]
                )
              //)
         );

}


Widget oneCGroup(BuildContext context, String name, int freeremains) {


return new GestureDetector(
           onTap: () async
           {
              //Здесь будет рутинг
              //await Navigator.of(context).pushNamed(terminalSubpageRoute);
           },
           child: new Container(
                height: 48.0,
                decoration: const BoxDecoration(
                  border: const Border(
                        bottom: const BorderSide(width: 1.0, color: const Color(0xFFFF000000))
                )),
                child:
                   new Column(
                     children: <Widget>[
                       new Text(name),
                       new Text("Остаток: $freeremains", style: new TextStyle(color: Colors.blue))
                     ]
                   ),
                )
         );
}


//Возможно следует переименовать


class MyCheckBox extends StatefulWidget {
  MyCheckBox({Key key, this.status}) : super(key: key);
  final bool status;

  @override
  _MyCheckBoxState createState() => new _MyCheckBoxState(status: status);
}

class _MyCheckBoxState extends State<MyCheckBox> {
  bool status;
  _MyCheckBoxState({this.status});


/*
  @override
  void initState() {
    super.initState();
    status = false;
  }
*/

  @override
  Widget build(BuildContext context) {
    return new Checkbox(
      value: status,
      onChanged: (bool value) {
        setState((){status = value;});
      }
    );
  }
}


Widget oneDefect(DbSynch cfg, BuildContext context, String name, int status) {
bool initstatus = false;

if (status == 1) {initstatus = true;}

return new Container(
                height: 48.0,
                decoration: const BoxDecoration(
                  border: const Border(
                        bottom: const BorderSide(width: 1.0, color: const Color(0xFFFF000000))
                )),
                child:
                   new Row(
                     children: <Widget>[
                       new Text(name,  style: new TextStyle(fontSize: 12.0)),
                       new MyCheckBox(status: initstatus)
                     ]
                   ),
                );

}


//Возможно следует переименовать

class CGroupPage extends StatefulWidget {
  CGroupPage({Key key, this.cfg}) : super(key: key);
  final DbSynch cfg;
  @override
  _CGroupPageState createState() => new _CGroupPageState(cfg: cfg);
}

class _CGroupPageState extends State<CGroupPage> {
  _CGroupPageState({this.cfg});
  DbSynch cfg;
  List<Widget> cgrouplist;
  List<Map> _cgroups=[];

  @override
  void initState() {
    super.initState();
    cfg.getCGroups().then((List<Map> list){
      setState((){
        _cgroups = list;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    cgrouplist = [];
    for (var r in _cgroups) {

      cgrouplist.add(oneCGroup(context,r["name"],r["freeremains"]));

    }


    return new Scaffold(
      appBar: new AppBar(
        title: new Text("ЗИПы тест")
      ),
      body: new ListView(
      shrinkWrap: true,
      children: cgrouplist,
    )
    );
  }

}








class TaskPage extends StatefulWidget {
  TaskPage({Key key, this.cfg}) : super(key: key);
  final DbSynch cfg;
  @override
  _TaskPageState createState() => new _TaskPageState(cfg: cfg);
}

class _TaskPageState extends State<TaskPage> {
  _TaskPageState({this.cfg});
  DbSynch cfg;
  List<Widget> tasklist;
  List<Map> _tasks=[];

  @override
  void initState() {
    super.initState();
    cfg.getTasks().then((List<Map> list){
      setState((){
        _tasks = list;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    var curservstat;
    String code;
    String address;


    tasklist = [
      new Container(
        height: 20.0,
        child: new Text("Невыполненные"),
        color: Colors.grey.shade300,
      ),
    ];

    curservstat = 0;

    for (var r in _tasks) {
      if (r["servstatus"] > curservstat) {
        curservstat = r["servstatus"];
        tasklist.add(new Container(
                height: 20.0,
                child: new Text("Выполненные"),
                color: Colors.grey.shade300,
              ),);
      }

if (r["code"]==null)
  {code = 'нулл';
   address = 'нулл';}
else
  {code = r["code"];
   address = r["address"];}

      tasklist.add(oneTask(cfg,context,DateTime.parse(r["dobefore"]),r["servstatus"],r["routepriority"],r["id"],code,address));

    }

    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Задачи")
      ),
      body: new ListView(
      shrinkWrap: true,
      children: tasklist,
    ));
  }
}





class TaskSubpage extends StatefulWidget {
  TaskSubpage({Key key, this.cfg}) : super(key: key);
  final DbSynch cfg;
  @override
  _TaskSubpageState createState() => new _TaskSubpageState(cfg: cfg);
}

class _TaskSubpageState extends State<TaskSubpage> {
  _TaskSubpageState({this.cfg});
  DbSynch cfg;

  @override
  void initState() {
    super.initState();
    cfg.getOneTask(cfg.cur_task).then((List<Map> list){
      setState((){

      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("одна задача")
      ),
      body: new Column(
              children:

              [
              new Text("здесь будет карточка задачи: "+cfg.cur_task.toString()),

               new GestureDetector(
                         onTap: () async
                         {

                            await Navigator.of(context).pushNamed(taskDefectsSubpageRoute);
                         },
                         child: new Container(
                              color: Colors.teal,
                              height: 48.0,
                              child:

                                 new Column(
                                   children: <Widget>[
                                     /*
                                     new Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: <Widget>[
                                         new Text("code"),
                                         new Text(fmtSrok(dobefore), style: new TextStyle(color: Colors.blue)),
                                       ]
                                     ),*/
                                     new Text("Поломки (х)", style: new TextStyle(color: Colors.white, fontSize: 12.0))
                                   ]
                                 )
                              )
                       ),




            ]
            )
        );

  }


}



/////////////////////////

class TaskDefectsSubpage extends StatefulWidget {
  TaskDefectsSubpage({Key key, this.cfg}) : super(key: key);
  final DbSynch cfg;
  @override
  _TaskDefectsSubpageState createState() => new _TaskDefectsSubpageState(cfg: cfg);
}

class _TaskDefectsSubpageState extends State<TaskDefectsSubpage> {
  _TaskDefectsSubpageState({this.cfg});
  DbSynch cfg;
  List<Widget> defectslist;
  List<Map> _defects=[]; //Странно что атом дает ворнинг. Выше, в аналогичном случае - не дает


  @override
  void initState() {
    super.initState();
    cfg.getDefects(cfg.cur_task).then((List<Map> list){
      setState((){
        _defects = list;
      });
    });
  }

  @override
  Widget build(BuildContext context) {


    defectslist = [];


    for (var r in _defects) {
      defectslist.add(oneDefect(cfg,context,r["name"],r["status"]));
    }





    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Дефекты")
      ),
      body: new ListView(
      shrinkWrap: true,
      children: defectslist,
    )
    );

  }


}
