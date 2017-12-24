import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';

//следует получше понеймить роуты
const String taskPageRoute = "/tasks";
const String terminalsPageRoute = "/terminals";
const String taskSubpageRoute = "/tasks/one";


class DbSynch {
  Database db;
  String login;
  String password;
  String clientId;
  String server;
  String token;
  int dbClientId=0;
  String clientName="";
  int closed=0;

  //int cur_task; //Непонятно насколько адекватный способ организации рутинга

  Future<Database> initDB() async {
    String dir = (await getApplicationDocumentsDirectory()).path;
    String path = "$dir/repairman_db.db";
    print ("$path");
    bool isUpgrage;
    do {
      isUpgrage = false;
      // open the database
      db = await openDatabase(path, version: 1,
        onCreate: (Database d, int version) async {
          await d.execute("""
            CREATE TABLE info(
              id INTEGER PRIMARY KEY,
              name TEXT,
              value TEXT,
              ts DATETIME DEFAULT CURRENT_TIMESTAMP
            )"""
          );

          await d.execute("""
            CREATE TABLE task(
              id INTEGER PRIMARY KEY,
              servstatus INTEGER,
              dobefore DATETIME,
              terminal INTEGER,
              terminalbreakname TEXT,
              routepriority INTEGER,
              terminalxid TEXT,
              ts DATETIME DEFAULT CURRENT_TIMESTAMP
            )"""
          );

          await d.execute("""
            CREATE TABLE terminal(
              id INTEGER PRIMARY KEY,
              xid TEXT,
              code TEXT,
              address TEXT,
              lastactivitytime DATETIME,
              lastpaymenttime DATETIME,
              errortext TEXT,
              src_system_name TEXT,
              latitude DECIMAL,
              longitude DECIMAL,
              mobileop TEXT
            )"""
          );


          await d.insert("info", {"name":"server", "value":"http://localhost:3000/api/v1/"});
          await d.insert("info", {"name":"client_id", "value":"repairman"});
          await d.insert("info", {"name":"login"});
          await d.insert("info", {"name":"password"});
          await d.insert("info", {"name":"token"});
        },
        onUpgrade: (Database database, int oldVersion, int newVersion) async {
          isUpgrage = true;
        },
        onDowngrade: (Database database, int oldVersion, int version) async {
          isUpgrage = true;
        },
      );
      if (isUpgrage) {
        db.close;
        await deleteDatabase(path);
      }
    } while (isUpgrage);

    List<Map> list = await db.rawQuery("""
      select (select value from info where name = 'login') login,
             (select value from info where name = 'password') password,
             (select value from info where name = 'client_id') client_id,
             (select value from info where name = 'server') server,
             (select value from info where name = 'token') token
    """);
    login = list[0]['login'];
    password = list[0]['password'];
    clientId = list[0]['client_id'];
    server = list[0]['server'];
    token = list[0]['token'];
    await makeConnection();
    return db;
  }


  Future<Null> updateLogin(String s) async {
    login = s.trim();
    await db.execute("UPDATE info SET value = '$login' WHERE name = 'login'");
  }

  Future<Null> updatePwd(String s) async {
    password = s.trim();
    await db.execute("UPDATE info SET value = '$password' WHERE name = 'password'");
  }

  Future<Null> updateSrv(String s) async {
    server = s.trim();
    await db.execute("UPDATE info SET value = '$server' WHERE name = 'server'");
  }


  Future<String> makeConnection() async {
    var httpClient = createHttpClient();
    String url = server + "authenticate";
    var response;

    try {
      response = await httpClient.post(url,
        headers: {"Authorization": "RApi login=$login,client_id=$clientId,password=$password"}
      );
    } catch(exception) {
      return 'Сервер $server недоступен!\n$exception';
    }
    Map data;
    try {
      data = JSON.decode(response.body);
    } catch(exception) {
      return 'Ответ сервера: ${response.body}\n$exception';
    }
    token = data["token"];
    await db.execute("UPDATE info SET value = '$token' WHERE name = 'token'");
    return data["error"];
  }

  Future<String> resetPassword() async {
    var httpClient = createHttpClient();
    String url = server + "reset_password";
    var response;
    try {
      response = await httpClient.post(url,
        headers: {"Authorization": "RApi login=$login,client_id=$clientId"}
      );
    } catch(exception) {
      return 'Сервер $server недоступен!\n$exception';
    }
    Map data;
    try {
      data = JSON.decode(response.body);
    } catch(exception) {
      return 'Ответ сервера: ${response.body}\n$exception';
    }
    return data["error"];
  }


Future<String> fillDB() async {
  String s;
  int i = 0;
  var data;
  var response;

  do {
    if (token==null) {
      s = (await makeConnection());
      if (s != null) {
        return s;
      }
    }
    var httpClient = createHttpClient();
    String url = server + "repairman";
    try {
      print("url = $url i = $i");
      print("RApi client_id=$clientId,token=$token");
      response = await httpClient.get(url,
        headers: {"Authorization": "RApi client_id=$clientId,token=$token"}
      );
    } catch(exception) {
      return 'Сервер $server недоступен!\n$exception';
    }


    data = JSON.decode(response.body);
//Пока без этого, но ошибку обработать будет нужно
/*
    try {
      data = JSON.decode(response.body);
      if (data["error"] != null) {
        if (i == 1) {
          return data["error"];
        }
        token = null;
        i++;
      } if(data["closed"] == null) {
        return 'Ответ сервера: ${response.body}';
      }
    } catch(exception) {
      return 'Ответ сервера: ${response.body}\n$exception';
    }
  */
  } while (i == 1);


  await db.execute("DELETE FROM task");
  await db.execute("DELETE FROM terminal");

  for (var tasks in data["tasks"]) {
    await db.execute("""
      INSERT INTO task (servstatus, dobefore, terminalbreakname, routepriority, terminalxid)
      VALUES(${tasks["servstatus"]},
             '${tasks["dobefore"]}',
             '${tasks["terminal_break_name"]}',
             '${tasks["route_priority"]}',
             '${tasks["terminal_xid"]}')
    """);
  }

  for (var terminals in data["terminals"]) {
    await db.execute("""
      INSERT INTO terminal (id, xid, code, address, lastactivitytime, lastpaymenttime, errortext, src_system_name, latitude, longitude, mobileop)
      VALUES(${terminals["id"]},
             '${terminals["xid"]}',
             '${terminals["code"]}',
             '${terminals["address"]}',
             '${terminals["lastactivitytime"]}',
             '${terminals["lastpaymenttime"]}',
             '${terminals["errortext"]}',
             '${terminals["src_system_name"]}',
             ${terminals["latitude"]},
             ${terminals["longitude"]},
             '${terminals["mobileop"]}')
    """);
  }


  return null;

}

Future<List<Map>> getTasks() async {
  List<Map> list;
  list = await db.rawQuery("""
    select
      task.servstatus,
      task.dobefore,
      task.terminalbreakname,
      task.routepriority,
      terminal.code,
      terminal.address
   from task
        left outer join terminal on terminal.xid = task.terminalxid
   order by servstatus, routepriority DESC, dobefore
  """);
  //Еще нужна сортировка по tt.code
  //Нужна ли какая-то проверка на случай если таск есть а терминала нет?
  return list;
}

Future<List<Map>> getTerminals() async {
  List<Map> list;
  list = await db.rawQuery("""
    select
           id,
           code,
           address,
           lastactivitytime,
           lastpaymenttime,
           errortext,
           src_system_name,
           latitude,
           longitude,
           mobileop
      from terminal
    where errortext is not null
  """);
//Нет сортировки, какая-то нужна
  return list;
}


}
