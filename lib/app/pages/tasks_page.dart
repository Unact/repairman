import 'dart:async';

import 'package:flutter/material.dart';

import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/pages/map_page.dart';
import 'package:repairman/app/pages/task_page.dart';
import 'package:repairman/app/utils/format.dart';

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
    _tasks = (await Task.all()).where((task) => !_showOnlyNew || task.isSeen).toList();
    _terminals = (await Terminal.all()).
      where((Terminal terminal) => _tasks.any((Task task) => task.ppsTerminalId == terminal.id)).toList();

    if (mounted) {
      setState(() {});
    }
  }

  Widget _taskTile(BuildContext context, Task task) {
    Terminal terminal = _terminals.firstWhere((terminal) => terminal.id == task.ppsTerminalId);

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
            backgroundImage: terminal.mobileOpImg(),
            backgroundColor: Colors.white12
          ),
          trailing: Checkbox(
            value: task.isSeen,
            onChanged: (bool value) async {
              task.isSeen = value;
              await task.update();
              await _loadData();
            },
          ),
          title: Text(
            task.routePriority.toString() + '|' + terminal.code + ' : ' + task.terminalBreakName,
            style: TextStyle(fontSize: 14.0)
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
                MaterialPageRoute(builder: (BuildContext context) => MapPage(terminals: _terminals))
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
