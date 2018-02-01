import 'package:flutter/material.dart';
import 'db_synch.dart';

Map taskColors(int servstatus, int routepriority) {
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

return {"bcolor": bcolor, "tcolor": tcolor};

}



Widget oneTask(DbSynch cfg, BuildContext context, DateTime dobefore, int servstatus, int routepriority, int taskId, String code, String address) {
Map colors;

colors = taskColors(servstatus, routepriority);

return new GestureDetector(
           onTap: () async
           {
              cfg.curTask = taskId;
              await Navigator.of(context).pushNamed(taskSubpageRoute);
           },
           child: new Container(
                color: colors["bcolor"],
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
                       new Text(address, style: new TextStyle(color: colors["tcolor"], fontSize: 12.0))
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

//updateDefect(int taskId, int defect_id, bool status)
//Возможно следует переименовать
class MyCheckBox extends StatefulWidget {
  MyCheckBox({Key key, this.cfg, this.defectid, this.status}) : super(key: key);
  final DbSynch cfg;
  final bool status;
  final int defectid;

  @override
  _MyCheckBoxState createState() => new _MyCheckBoxState(cfg: cfg, defectid: defectid, status: status);
}

class _MyCheckBoxState extends State<MyCheckBox> {
  DbSynch cfg;
  bool status;
  int defectid;
  _MyCheckBoxState({this.cfg, this.defectid, this.status});


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
        cfg.updateDefect(cfg.curTask, defectid, value).then((v){setState((){status = value;});});
      }
    );
  }
}


Widget oneDefect(DbSynch cfg, BuildContext context, String name, int status, int defectid) {
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
                       new MyCheckBox(cfg: cfg, defectid: defectid, status: initstatus)
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
      //tasklist.add(new Divider());
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
  int repaircnt;
  int defectcnt;
  String srepaircnt = "";
  String sdefectcnt = "";
  String terminalbreakname="";
  String terminalcode="";
  DateTime dobefore;
  int servstatus;
  int routepriority;
  Map colors;
  Map list;
  var bcolor;
  var tcolor;
  var dvcolor = Colors.brown;
  var btnfontsize = 16.0;

  @override
  void initState() {
    super.initState();
    cfg.getOneTask(cfg.curTask).then((List<Map> list){
      setState(()  {
      for (var r in list) { //сделать без цикла
        repaircnt = r["repaircnt"];
        defectcnt = r["defectcnt"];
        if (repaircnt>=0) {srepaircnt = " ($repaircnt)";}
        if (defectcnt>=0) {sdefectcnt = " ($defectcnt)";}
        terminalbreakname = r["terminalbreakname"];
        terminalcode = r["code"];
        servstatus = r["servstatus"];
        routepriority = r["routepriority"];
        dobefore = DateTime.parse(r["dobefore"]);
        colors = taskColors(servstatus, routepriority);
        tcolor = colors["tcolor"];
        bcolor = colors["bcolor"];
      } });
   }


  );

  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(terminalcode+" "+terminalbreakname)
      ),
      body: new Column(
              children:

              [
                new Container(color: dvcolor, height: 12.0),
                new Container(
                     color: bcolor,
                     height: 48.0,
                     child:

                        new Row(
                            children: [
                              new Expanded(
                                flex: 10,
                                child:
                                  new Container(
                                padding: const EdgeInsets.all(4.0),
                                child: new Text("Срок: ", textAlign: TextAlign.end, style: new TextStyle(color: Colors.blue, fontSize: btnfontsize))
                              )


                              ),
                              new Expanded(
                                flex: 30,
                                child: new Text(fmtSrok(dobefore), style: new TextStyle(color: Colors.black, fontSize: btnfontsize))
                              )
                            ]

                        )
                     ),
                     new Container(color: dvcolor, height: 12.0),

            new Container(
                          color: Colors.white,
                          height: 48.0,
                          child:
               new Row(
               children: [new Expanded(child: new GestureDetector(
                         onTap: () async
                         {

                            await Navigator.of(context).pushNamed(taskDefectsSubpageRoute);
                         },
                         child:
                               new Text("Добавить неисправность"+sdefectcnt, textAlign: TextAlign.center, style: new TextStyle(fontSize: btnfontsize))
                       ))])
            ),
            new Divider(height: 1.0),
            new Container(
                          color: Colors.white,
                          height: 48.0,
                          child:
               new Row(
               children: [new Expanded(child: new GestureDetector(
                         onTap: () async
                         {

                            await Navigator.of(context).pushNamed(taskDefectsSubpageRoute);
                         },
                         child:
                               new Text("Добавить ремонт"+srepaircnt, textAlign: TextAlign.center, style: new TextStyle(fontSize: btnfontsize))
                       ))])
            ),
            new Divider(height: 1.0),
            new Container(
                          color: Colors.white,
                          height: 48.0,
                          child:
               new Row(
               children: [new Expanded(child: new GestureDetector(
                         onTap: () async
                         {

                            await Navigator.of(context).pushNamed(taskDefectsSubpageRoute);
                         },
                         child:
                               new Text("ЗИПы", textAlign: TextAlign.center, style: new TextStyle(fontSize: btnfontsize))
                       ))])
            ),
            new Divider(height: 1.0),
            new Container(
                          color: Colors.white,
                          height: 48.0,
                          child:
               new Row(
               children: [new Expanded(child: new GestureDetector(
                         onTap: () async
                         {

                            await Navigator.of(context).pushNamed(taskDefectsSubpageRoute);
                         },
                         child:
                               new Text("Поставить геометку", textAlign: TextAlign.center, style: new TextStyle(fontSize: btnfontsize))
                       ))])
            ),
               new Container(color: dvcolor, height: 12.0),
               new Container(
                             color: Colors.white,
                             height: 48.0,
                             child:
                  new Row(
                  children: [new Expanded(child: new GestureDetector(
                            onTap: () async
                            {

                               await Navigator.of(context).pushNamed(taskDefectsSubpageRoute);
                            },
                            child:
                                  new Text("Добавить комментарий", textAlign: TextAlign.center, style: new TextStyle(fontSize: btnfontsize))
                          ))])
               ),
               new Container(color: dvcolor, height: 12.0),
               new Container(
                             color: Colors.white,
                             height: 48.0,
                             child:
                  new Row(
                  children: [new Expanded(child: new GestureDetector(
                            onTap: () async
                            {

                               await Navigator.of(context).pushNamed(taskDefectsSubpageRoute);
                            },
                            child:
                                  new Text("[инв.номер]", textAlign: TextAlign.center, style: new TextStyle(fontSize: btnfontsize))
                          ))])
               ),
               new Divider(height: 1.0),
               new Container(
                             color: Colors.white,
                             height: 48.0,
                             child:
                  new Row(
                  children: [new Expanded(child: new GestureDetector(
                            onTap: () async
                            {

                               await Navigator.of(context).pushNamed(taskDefectsSubpageRoute);
                            },
                            child:
                                  new Text("[инфа терминала]", textAlign: TextAlign.center, style: new TextStyle(fontSize: btnfontsize))
                          ))])
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
    cfg.getDefects(cfg.curTask).then((List<Map> list){
      setState((){
        _defects = list;
      });
    });
  }

  @override
  Widget build(BuildContext context) {


    defectslist = [];


    for (var r in _defects) {
      defectslist.add(oneDefect(cfg,context,r["name"],r["status"],r["defect_id"]));
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



////////////////// ЗИПы
