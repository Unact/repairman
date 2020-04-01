import 'dart:async';

import 'package:flutter/material.dart';

import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/pages/map_page.dart';
import 'package:repairman/app/pages/task_page.dart';
import 'package:repairman/app/utils/format.dart';
import 'package:repairman/app/utils/ui_colors.dart';

class TasksPage extends StatefulWidget {
  TasksPage({Key key}) : super(key: key);

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Task> _tasks = [];
  List<Terminal> _terminals = [];
  bool _showOnlyNew = false;

  Future<void> _loadData() async {
    _tasks = (await Task.allSorted()).where((task) => !_showOnlyNew || task.isSeen).toList();
    _terminals = await Terminal.all();

    if (mounted) {
      setState(() {});
    }
  }

  Widget _taskTile(BuildContext context, Task task) {
    Terminal terminal = _terminals.firstWhere((term) => term.id == task.ppsTerminalId, orElse: () => Terminal());
    Color taskColor = task.isGreenUncompletedRoute ?
      UIColors.greenTask :
      (task.isYellowUncompletedRoute ?
        UIColors.yellowTask :
        (task.isRedUncompletedRoute ? UIColors.redTask : UIColors.normalTask));

    if (terminal.id == null) return Container();

    return Container(
      child: GestureDetector(
        onTap: () async {
          task.isSeen = false;
          await task.update();

          Navigator.push(context, MaterialPageRoute(builder: (context) => TaskPage(terminal: terminal, task: task)));
        },
        child: ListTile(
          isThreeLine: false,
          leading: CircleAvatar(
            child: Text(task.routePriority.toString()),
            backgroundColor: taskColor
          ),
          trailing: Checkbox(
            value: task.isSeen,
            onChanged: (bool value) async {
              task.isSeen = value;
              await task.update();
              await _loadData();
            },
          ),
          title: Container(
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  maxRadius: 6.0,
                  backgroundImage: terminal.mobileOpImg(),
                  backgroundColor: Colors.white12
                ),
                SizedBox(width: 6.0),
                Flexible(
                  child: Text(terminal.code + ' : ' + task.terminalBreakName,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(fontSize: 14.0)
                  )
                )
              ]
            )
          ),
          subtitle: RichText(
            text: TextSpan(
              children: <TextSpan>[
                TextSpan(text: terminal.address + '\n', style: TextStyle(color: Colors.grey, fontSize: 12.0)),
                TextSpan(text: Format.untilStr(task.dobefore), style: TextStyle(color: Colors.blue))
              ]
            )
          )
        )
      )
    );
  }

  Widget _buildBody(BuildContext context) {
    List<Task> tasks = _tasks ?? [];

    if (_terminals.isEmpty) return Container();

    return Container(
      padding: EdgeInsets.only(left: 8.0, right: 8.0),
      child: ListView(
        children: <Widget>[
          ExpansionTile(
            initiallyExpanded: true,
            title: Text('Невыполненные'),
            children: tasks.where((task) => !task.servstatus).map((task) => _taskTile(context, task)).toList()
          ),
          ExpansionTile(
            initiallyExpanded: false,
            title: Text('Выполненные'),
            children: tasks.where((task) => task.servstatus).map((task) => _taskTile(context, task)).toList()
          )
        ]
      )
    );
  }

  @override
  void initState() {

    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Задачи'),
        actions: <Widget>[
          IconButton(
            color: Colors.white,
            icon: Icon(Icons.map),
            onPressed: () {
              if (_terminals.isEmpty) {
                _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text('Нет терминалов')));
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(builder: (BuildContext context) => MapPage(terminals: _terminals, tasks: _tasks,))
              );
            }
          ),
          PopupMenuButton<bool>(
            padding: EdgeInsets.zero,
            onSelected: (bool value) async {
              _showOnlyNew = !value;
              await _loadData();
            },
            itemBuilder: (BuildContext context) => <PopupMenuItem<bool>>[
              CheckedPopupMenuItem<bool>(
                value: _showOnlyNew,
                checked: _showOnlyNew,
                child: Text('Только новые')
              )
            ]
          )
        ]
      ),
      body: _buildBody(context)
    );
  }
}
