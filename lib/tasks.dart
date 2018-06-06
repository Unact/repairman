import 'dart:async';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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



Widget oneTask(DbSynch cfg, BuildContext context, DateTime dobefore, int servstatus, int routepriority, int taskId, String code, String address, String terminalbreakname) {
Map colors;

colors = taskColors(servstatus, routepriority);

return new GestureDetector(
           behavior: HitTestBehavior.translucent,
           onTap: () async
           {
              cfg.curTask = taskId;
              cfg.curServstatus = servstatus;
              await Navigator.of(context).pushNamed(taskSubpageRoute);
              cfg.synchDB().then((res){
                if (res!="ok") {
                  showDialog(context: context,
                    builder: (BuildContext context) {
                      return new AlertDialog(
                        title: new Text("Ошибка сохранения базы"),
                        content: new Text("$res"),
                      );
                    }
                  );
                }
              });
           },
           child: new Container(
                color: colors["bcolor"],
                height: 48.0,
                padding: const EdgeInsets.all(4.0),
                child:
                   new Column(
                     children: <Widget>[
                       new Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: <Widget>[
                           new Text(routepriority.toString()+"|"+code+" : "+terminalbreakname),
                           new Text(fmtSrok(dobefore), style: new TextStyle(color: Colors.blue)),
                         ]
                       ),
                       new Text(address, style: new TextStyle(color: colors["tcolor"], fontSize: 10.0))
                     ]
                   )
                )
         );
}
Future<bool> confirmChangeComponent(BuildContext context, int chflag, int preinstflag, String shortName, String serial) async {
String caption;

if (chflag==0)
{
  if (preinstflag==0) {
    caption = "Установить компонент?";
  } else {
    caption = "Снять неисправный компонент?";
  }
} else {
  if (preinstflag==0) {
    caption = "Отменить установку компонента?";
  } else {
    caption = "Отменить снятие компонента?";
  }
}

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return new AlertDialog(
        title: new Text(caption),
        content: new SingleChildScrollView(
          child: new ListBody(
            children: <Widget>[
              new Text(shortName),
              new Text('Серийный номер:'),
              new Text(serial)
            ],
          ),
        ),
        actions: <Widget>[
          new FlatButton(
            child: new Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
          new FlatButton(
            child: new Text('Отмена'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
        ],
      );
    },
  );
}

Widget oneComponent(DbSynch cfg, BuildContext context, String shortName, String serial, int chflag, int preinstflag, int compId, VoidCallback cbSetState) {
String chtext="";
int newstatus;

if (chflag==0) {newstatus=1;} else {newstatus=0;}

if (chflag==1) {
  if (preinstflag==1) {chtext="Снят";} else {chtext="Устан.";}
}

return cfg.syncing==1?  new CircularProgressIndicator() : new GestureDetector(
           behavior: HitTestBehavior.translucent,
           onTap: () async
           {
             confirmChangeComponent(context, chflag, preinstflag, shortName, serial).then((res){
               if (res==true) {
                 cfg.updateComponent(compId, cfg.curTask, preinstflag, newstatus).then((res)
                 {cbSetState();});

               }
             });
              //cfg.curCGroup = 0;
              //await Navigator.of(context).pushNamed(taskSubpageComponentRoute);


           },
           child: new Container(
                height: 48.0,
                child:
                   new Column(
crossAxisAlignment: CrossAxisAlignment.start,
                    children: [


                   new Container(

                     child: new Text(shortName, textAlign: TextAlign.start)),

                   new Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: <Widget>[
                       new Text(serial, textAlign: TextAlign.start),
                       new Text(chtext, textAlign: TextAlign.end, style: new TextStyle(color: Colors.blue))
                     ]
                   ),

                 ]),
                )
         );
}



Widget oneCGroup(DbSynch cfg, BuildContext context, String name, int freeremains, int inscnt, int remcnt, int preinstcnt, String cGroupXid) {
String spreinstcnt="";
String scnt="";
if (preinstcnt>0) {spreinstcnt = preinstcnt.toString();}
if (freeremains>0) {scnt+="Остаток: ${freeremains-inscnt}  ";}
if (inscnt>0) {scnt+="Установлено: $inscnt  ";}
if (remcnt>0) {scnt+="Неиспр.: $remcnt  ";}

return new GestureDetector(
           behavior: HitTestBehavior.translucent,
           onTap: () async
           {
              cfg.curCGroup = cGroupXid;
              await Navigator.of(context).pushNamed(taskSubpageComponentRoute);
           },
           child: new Container(
                padding: const EdgeInsets.all(4.0),
                height: 48.0,
                child:
                   new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                   new Expanded(flex: 100, child:
                   new Column(
                     children: <Widget>[
                       new Row(children: [new Text(name, textAlign: TextAlign.start)]),
                       new Row(children: [new Text(scnt, textAlign: TextAlign.start, style: new TextStyle(color: Colors.blue))])
                     ],
                   )),

                   new Expanded(
                   flex:5,
                   child: new Text(spreinstcnt, style: new TextStyle(fontSize: 20.0, color: Colors.blue)))

                   ]),
                )
         );
}



Widget oneDefect(DbSynch cfg, BuildContext context, String name, int status, int defectid, VoidCallback cbSetState) {
bool initstatus = false;
bool newstatus = true;
if (status == 1) {initstatus = true; newstatus = false;}


return new GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async
          {
            if (cfg.syncing!=1) {cfg.updateDefect(cfg.curTask, defectid, newstatus).then((v){cbSetState();});}
          },
          child:
              new Container(
                height: 48.0,
                padding: const EdgeInsets.all(4.0),
                child:
                   new Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: <Widget>[
                       new Expanded(child: new Text(name, overflow: TextOverflow.fade , style: new TextStyle(fontSize: 14.0))),
                      cfg.syncing==1?  new CircularProgressIndicator() :
                      new Checkbox(
                         value: initstatus,
                         onChanged: (bool value) {
                           //При клике на сам чекбокс гестур не реагирует
                           cfg.updateDefect(cfg.curTask, defectid, newstatus).then((v){cbSetState();});
                        }
                       )
                     ]
                   ),
                ));
}



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


  @override
  void initState() {
    super.initState();
    cfg.getCGroups(cfg.curTask).then((v){
      setState((){});
    });
  }

  @override
  Widget build(BuildContext context) {
    cgrouplist = [];
    for (var r in cfg.cgroups) {

      cgrouplist.add(oneCGroup(cfg, context,r["name"],r["freeremains"],r["inscnt"],r["remcnt"],r["preinstcnt"],r["xid"]));
      cgrouplist.add(new Divider(height: 1.0));

    }


    return new Scaffold(
      appBar: new AppBar(
        title: new Text("ЗИПы")
      ),
      body: new ListView(
      shrinkWrap: true,
      children: cgrouplist,
    )
    );
  }

}



class ComponentPage extends StatefulWidget {
  ComponentPage({Key key, this.cfg}) : super(key: key);
  final DbSynch cfg;
  @override
  _ComponentPageState createState() => new _ComponentPageState(cfg: cfg);
}


class _ComponentPageState extends State<ComponentPage> {

  _ComponentPageState({this.cfg});
  DbSynch cfg;
  List<Widget> complist;
  List<Map> _comps=[];


  doReload() {
    cfg.getComponent(cfg.curTask, cfg.curCGroup).then((List<Map> list){
      setState((){
        _comps = list;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    doReload();
  }

  @override
  Widget build(BuildContext context) {
    int preinstflag;
    var cbfunc = doReload;
    complist = [];
    preinstflag=-1;
    for (var r in _comps) {
      if ((preinstflag!=r["preinstflag"])&&(r["preinstflag"]==1)) {
        preinstflag=1;
        complist.add(new Container(
                height: 20.0,
                child: new Text("Изначально установленные"),
                color: Colors.grey.shade300,
              ),);
      }
      if ((preinstflag!=r["preinstflag"])&&(r["preinstflag"]==0)) {
        preinstflag=0;
        complist.add(new Container(
                height: 20.0,
                child: new Text("Ремфонд"),
                color: Colors.grey.shade300,
              ),);
      }

      complist.add(oneComponent(cfg,context,r["short_name"],r["serial"],r["chflag"],r["preinstflag"],r["comp_id"],cbfunc));
      complist.add(new Divider(height: 1.0));

    }


    return new Scaffold(
      appBar: new AppBar(
        title: new Text("ЗИПы")
      ),
      body: new ListView(
      shrinkWrap: true,
      children: complist,
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


  @override
  void initState() {
    super.initState();
    cfg.getTasks().then((v){
      setState((){
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


    for (var r in cfg.tasks) {
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

      tasklist.add(oneTask(cfg,context,safeParseDate(r["dobefore"]),r["servstatus"],r["routepriority"],r["id"],code,address,r["terminalbreakname"]));
      tasklist.add(new Divider(height: 1.0));
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
  String srepaircnt;
  String sdefectcnt;
  String szipcnt;
  String terminalbreakname="";
  String terminalcode="";
  String invNum="";
  int terminalId = 0;
  DateTime dobefore;
  int routepriority;
  Map colors;
  Map list;
  var bcolor;
  var tcolor;
  var dvcolor = Colors.transparent;
  var btnfontsize = 16.0;
  double _latitude = 55.754226;
  double _longitude = 37.617582;
  DateTime lastactivitytime = new DateTime(1999, 1, 1);
  bool _hasGeoTs = false;

  //changeRepairCnt(int diff) {setState((){repaircnt = repaircnt + diff;});}
  //changeDefectCnt(int diff) {setState((){defectcnt = defectcnt + diff;});}
  //changeZipCnt(int diff) {setState((){zipcnt = zipcnt + diff;});}

  @override
  void initState() {
    super.initState();
    cfg.getOneTask(cfg.curTask).then((List<Map> list){
      setState(()  {
      for (var r in list) { //сделать без цикла
        cfg.repaircnt = r["repaircnt"];
        cfg.defectcnt = r["defectcnt"];
        cfg.zipcnt = r["zipcnt"];
        terminalbreakname = r["terminalbreakname"];
        terminalcode = r["code"];
        routepriority = r["routepriority"];
        invNum = r["inv_num"];
        lastactivitytime = safeParseDate(r["lastactivitytime"]);
        terminalId = r["terminal_id"];
        dobefore = safeParseDate(r["dobefore"]);
        colors = taskColors(cfg.curServstatus, routepriority);
        tcolor = colors["tcolor"];
        bcolor = colors["bcolor"];
        _latitude=r["latitude"];
        _longitude=r["longitude"];
        cfg.curComment = r["comm"];
        _hasGeoTs = (r["has_geo_ts"]==1);
      } });
   }


  );

  }


  @override
  Widget build(BuildContext context) {
    Widget addCommBtn;
    Widget executionButton;
    print("Открыта задача: ${cfg.curTask}");

    if (cfg.repaircnt>0) {srepaircnt = " (${cfg.repaircnt})";} else {srepaircnt="";}
    if (cfg.defectcnt>0) {sdefectcnt = " (${cfg.defectcnt})";} else {sdefectcnt="";}
    if (cfg.zipcnt>0) {szipcnt = " (${cfg.zipcnt})";} else {szipcnt="";}

    if (cfg.curComment == "")
    {
    addCommBtn = cfg.syncing==1?  new CircularProgressIndicator() : new GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () async
              {

                 await Navigator.of(context).pushNamed(taskSubpageRouteComment);
              },
              child:
              new Container(
                            padding: const EdgeInsets.all(4.0),
                            color: Colors.white,
                            height: 48.0,
                            child:
                            new Row(
                            children: [new Expanded(
                                      child:
                new Text("Добавить комментарий", textAlign: TextAlign.center,  style: new TextStyle(color: Colors.blue, fontSize: btnfontsize))
              )]))
            );

    } else {

      addCommBtn = cfg.syncing==1?  new CircularProgressIndicator() : new GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () async
                {

                   await Navigator.of(context).pushNamed(taskSubpageRouteComment);
                },
                child:

                      new Container(
                                    padding: const EdgeInsets.all(4.0),
                                    color: Colors.white,
                                    height: 48.0,
                                    child:
                                    new Row(
                                    children: [new Expanded(
                                              child:
                        new Text(cfg.curComment, textAlign: TextAlign.left, style: new TextStyle(fontSize: btnfontsize))
                  )]))

              );

    }

    if (cfg.curServstatus==1) {
      executionButton = new GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () async
                            {

                            },
                            child:
                  new Container(
                                color: Colors.white,
                                height: 48.0,
                                child:
                     new Row(
                     children: [new Expanded(
                               child:
                                     new Text("Выполнено", textAlign: TextAlign.center, style: new TextStyle(color: Colors.green, fontSize: btnfontsize))
                             )])
                  ));
    } else if (!_hasGeoTs) {
      executionButton =  cfg.syncing==1?  new CircularProgressIndicator() :
                         new GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () async
                            {
                               cfg.updateExecutionMark(context, _latitude,_longitude).then((v){setState((){_hasGeoTs=v;});});
                            },
                            child:
                  new Container(
                                color: Colors.white,
                                height: 48.0,
                                child:
                     new Row(
                     children: [new Expanded(
                               child:
                                     new Text("Поставить геометку", textAlign: TextAlign.center, style: new TextStyle(color: Colors.blue, fontSize: btnfontsize))
                             )])
                  ));
    } else {
      executionButton = cfg.syncing==1?  new CircularProgressIndicator() :
                        new GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () async
                            {
                              cfg.updateServstatus().then((v){setState((){});});
                            },
                            child:
                  new Container(
                                color: Colors.white,
                                height: 48.0,
                                child:
                     new Row(
                     children: [new Expanded(
                               child:
                                     new Text("Отметить выполнение", textAlign: TextAlign.center, style: new TextStyle(color: Colors.blue, fontSize: btnfontsize))
                             )])
                  ));
    }



    print(_latitude);
    print(_longitude);

    return new Scaffold(
      appBar: new AppBar(
        title: new Text(terminalcode+" "+terminalbreakname)
      ),
      body: new ListView(
      shrinkWrap: true,
      children: [new Column(
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

            new GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () async
               {
                await Navigator.of(context).pushNamed(taskDefectsSubpageRoute);
                },
            child:
            new Container(
                          color: Colors.white,
                          height: 48.0,
                          child:
               new Row(
               children: [new Expanded(
                         child:
                               new Text("Добавить неисправность"+sdefectcnt, textAlign: TextAlign.center, style: new TextStyle(fontSize: btnfontsize))
                       )])
            )),
            new Divider(height: 1.0),

            new GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () async
              {

                 await Navigator.of(context).pushNamed(taskRepairsSubpageRoute);
              },
            child: new Container(
                          color: Colors.white,
                          height: 48.0,
                          child:
               new Row(
               children: [new Expanded(
                         child:
                               new Text("Добавить ремонт"+srepaircnt, textAlign: TextAlign.center, style: new TextStyle(fontSize: btnfontsize))
                       )])
            )),
            new Divider(height: 1.0),
            new GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () async
              {

                 await Navigator.of(context).pushNamed(taskSubpageCgroupRoute);
              },
            child: new Container(
                          color: Colors.white,
                          height: 48.0,
                          child:
               new Row(
               children: [new Expanded(
                         child:
                               new Text("ЗИПы"+szipcnt, textAlign: TextAlign.center, style: new TextStyle(fontSize: btnfontsize))
                       )])
            )),
            new Divider(height: 1.0),
            executionButton,
            new Container(color: dvcolor, height: 12.0),
            addCommBtn,
            new Container(color: dvcolor, height: 12.0),
            new GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () async {
                try {
                  String barcode = await BarcodeScanner.scan();
                  await cfg.updateInvNum(barcode);
                  setState(() => this.invNum = barcode);
                } on PlatformException catch (e) {
                  String errorMsg = 'Не известная ошибка: $e';

                  if (e.code == BarcodeScanner.CameraAccessDenied) {
                    errorMsg = 'Необходимо дать доступ к использованию камеры';
                  }

                  showDialog(context: context,
                    builder: (BuildContext context) {
                      return new AlertDialog(
                        title: new Text('Ошибка инв. номера'),
                        content: new Text(errorMsg),
                      );
                    }
                  );
                } catch (e) {
                  showDialog(context: context,
                    builder: (BuildContext context) {
                      return new AlertDialog(
                        title: new Text('Ошибка инв. номера'),
                        content: new Text('Не известная ошибка: $e'),
                      );
                    }
                  );
                }
              },
              child:
              new Container(
                  color: Colors.white,
                  height: 48.0,
                  padding: const EdgeInsets.all(4.0),
                  child: new Row(
                    children: [
                      new Expanded(child: new Text("Инв.номер: $invNum"))
                    ],
                  )
              ),
            ),
            new Divider(height: 1.0),
            new Container(
              color: Colors.white,
              height: 48.0,
              padding: const EdgeInsets.all(4.0),
              child: new GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () async
                        {
                          cfg.dbTerminalId = terminalId;
                          await Navigator.of(context).pushNamed(terminalPageRoute);
                        },
                child: new Row(
                    children: [
                      new Expanded(child: new Text("$terminalcode")),
                      new Expanded(child: new Text(fmtSrok(lastactivitytime), textAlign: TextAlign.end))
                    ]
                )
              )
            ),
            new Container(color: dvcolor, height: 12.0),
            new Image.network('https://static-maps.yandex.ru/1.x/?ll=$_longitude,$_latitude&size=250,200&z=15&l=map&pt=$_longitude,$_latitude,pm2gnm', fit: BoxFit.cover),
            ]
          )])
        );

  }


}


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

  doReload() {
    cfg.getDefects(cfg.curTask).then((List<Map> list){
      setState((){
        _defects = list;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    doReload();
  }

  @override
  Widget build(BuildContext context) {
    var cbfunc = doReload;
    defectslist = [];

    for (var r in _defects) {
      defectslist.add(oneDefect(cfg,context,r["name"],r["status"],r["defect_id"],cbfunc));
      defectslist.add(new Divider(height: 1.0));
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



//Страница "Комментарий"
class TaskCommentSubpage extends StatefulWidget {
  TaskCommentSubpage({Key key, this.cfg}) : super(key: key);
  final DbSynch cfg;
  @override
  _TaskCommentSubpageState createState() => new _TaskCommentSubpageState(cfg: cfg);
}

class _TaskCommentSubpageState extends State<TaskCommentSubpage> {
  _TaskCommentSubpageState({this.cfg});
  DbSynch cfg;

  final TextEditingController _ctlComment = new TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctlComment.text = cfg.curComment;
    _ctlComment.addListener(() {
      cfg.updateComment(_ctlComment.text);
    });
  }

  @override
  Widget build(BuildContext context) {








    return new Scaffold(
      appBar: new AppBar(
        title: new Text("")
      ),
      body: new TextField(
                 controller: _ctlComment
                ),
    );

  }


}




////// РЕПЕЙРЫ


Widget oneRepair(DbSynch cfg, BuildContext context, String name, int status, int repairid, VoidCallback cbSetState) {
bool initstatus = false;
bool newstatus = true;
if (status == 1) {initstatus = true; newstatus = false;}


return new GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async
          {
            //Как-то мне не нравится, что в ответ на интерактивное действие мы ждем отработки БД, но как еще?..
            if (cfg.syncing!=1) {cfg.updateRepair(cfg.curTask, repairid, newstatus).then((v){cbSetState();});}
          },
          child:
              new Container(
                height: 48.0,
                padding: const EdgeInsets.all(4.0),
                child:
                   new Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: <Widget>[
                       new Expanded(child: new Text(name, overflow: TextOverflow.fade , style: new TextStyle(fontSize: 14.0))),
                      cfg.syncing==1?  new CircularProgressIndicator() :
                      new Checkbox(
                         value: initstatus,
                         onChanged: (bool value) {
                           //При клике на сам чекбокс гестур не реагирует
                           cfg.updateRepair(cfg.curTask, repairid, newstatus).then((v){cbSetState();});
                        }
                       )
                     ]
                   ),
                ));


}


class TaskRepairsSubpage extends StatefulWidget {
  TaskRepairsSubpage({Key key, this.cfg}) : super(key: key);
  final DbSynch cfg;
  @override
  _TaskRepairsSubpageState createState() => new _TaskRepairsSubpageState(cfg: cfg);
}

class _TaskRepairsSubpageState extends State<TaskRepairsSubpage> {
  _TaskRepairsSubpageState({this.cfg});
  DbSynch cfg;
  List<Widget> repairslist;
  List<Map> _repairs=[];

  doReload() {
    cfg.getRepairs(cfg.curTask).then((List<Map> list){
      setState((){
        _repairs = list;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    doReload();
  }

  @override
  Widget build(BuildContext context) {
    var cbfunc = doReload;
    repairslist = [];

    for (var r in _repairs) {
      repairslist.add(oneRepair(cfg,context,r["name"],r["status"],r["repair_id"],cbfunc));
      repairslist.add(new Divider(height: 1.0));
    }

    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Репейры")
      ),
      body: new ListView(
      shrinkWrap: true,
      children: repairslist,
    )
    );

  }


}
