import 'package:flutter/material.dart';
import 'db_synch.dart';


class AuthPage extends StatefulWidget {
  AuthPage({Key key, this.cfg}) : super(key: key);
  final DbSynch cfg;
  @override
  _AuthPageState createState() => new _AuthPageState(cfg: cfg);
}

class _AuthPageState extends State<AuthPage> {
  _AuthPageState({this.cfg});
  DbSynch cfg;
  bool sendingClose = false;
  bool sendingInit = false;
  bool sendingConnect = false;
  bool sendingPwd = false;
  bool loading = false;

  final TextEditingController _ctlLogin = new TextEditingController();
  final TextEditingController _ctlPwd = new TextEditingController();
  final TextEditingController _ctlSrv = new TextEditingController();
  int _srvVisible = 0;


  @override
  void initState() {
    super.initState();
      _ctlLogin.text = cfg.login;
      _ctlPwd.text = cfg.password;
      _ctlSrv.text = cfg.server;
      _ctlLogin.addListener(() {
        cfg.updateLogin(_ctlLogin.text);
      });
      _ctlPwd.addListener(() {
        cfg.updatePwd(_ctlPwd.text);
      });
      _ctlSrv.addListener(() {
        cfg.updateSrv(_ctlSrv.text);
      });

  }


  @override
  Widget build(BuildContext context) {

    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Настройки")
      ),
      body: new Container(
      padding: const EdgeInsets.all(8.0),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          new GestureDetector(
            onTap: () {
              setState(() { _srvVisible++; });
            },
            child: new Text('Телефон или e-mail или имя'),
          ),
          new TextField(
            controller: _ctlLogin,
            decoration: new InputDecoration(
              hintText: 'Введите телефон или e-mail или имя',
            ),
          ),
          new Text('Пароль'),
          new TextField(
            controller: _ctlPwd,
            keyboardType: TextInputType.number,
            decoration: new InputDecoration(
              hintText: 'Введите пароль',
            ),
          ),
          new Container(
            padding: const EdgeInsets.all(8.0),
            child: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [ sendingConnect? new CircularProgressIndicator() : new RaisedButton(
                      color: Colors.blue,
                      onPressed: () {
                        setState(()=>sendingConnect=true);
                        cfg.makeConnection().then((String s) {
                          var alert;
                          setState(()=>sendingConnect=false);
                          if (s != null) {
                            alert = new AlertDialog(
                              title: new Text("Ошибка подключения"),
                              content: new Text("$s"),
                            );
                          }
                          else {
                            print(cfg.token);
                            alert = new AlertDialog(
                              title: new Text("Подключение"),
                              content: new Text("Успешно"),
                              actions: <Widget>[
                                new FlatButton(
                                  child: new Text('OK'),
                                  onPressed: (){
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                  }
                                )
                              ],
                            );
                          }
                          showDialog(context: context, child: alert);
                        });
                      },
                      child: new Text('Подключиться', style: new TextStyle(color: Colors.white)),
            ),
            sendingPwd? new CircularProgressIndicator() : new RaisedButton(
              color: Colors.blue,
              onPressed: () {
                setState(()=>sendingPwd=true);
                cfg.resetPassword().then((String s) {
                  var alert;
                  setState(()=>sendingPwd=false);
                  if (s != null) {
                    alert = new AlertDialog(
                      title: new Text("Ошибка сброса пароля"),
                      content: new Text("$s"),
                    );
                  }
                  else {
                    alert = new AlertDialog(
                      title: new Text("Получение пароля"),
                      content: new Text("Успешно"),
                    );
                  }
                  showDialog(context: context, child: alert);
                });
              },
              child: new Text('Получить пароль', style: new TextStyle(color: Colors.white)),
            )
          ]
        )),
          ((_srvVisible > 5)?(new TextField(controller: _ctlSrv)):(new Container())),
        ]
      )));
  }

}
