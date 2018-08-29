import 'dart:async';

import 'package:flutter/material.dart';

import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/pages/task_page.dart';
import 'package:repairman/app/utils/format.dart';

class TasksPage extends StatefulWidget {
  TasksPage({Key key}) : super(key: key);

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<Task> _tasks = [];
  bool _showOnlyNew = false;

  Future<void> _loadData() async {
    _tasks = (await Task.allWithTerminalInfo()).where((term) => !_showOnlyNew || term.isNew).toList();


    if (mounted) {
      setState((){});
    }
  }

  Widget _taskTile(BuildContext context, Task task) {
    return Container(
      child: GestureDetector(
        onTap: () async {
          task.isNew = false;
          await task.update();
          Terminal terminal = await Terminal.byPpsTerminalId(task.ppsTerminalId);

          Navigator.push(context, MaterialPageRoute(builder: (context) => TaskPage(terminal: terminal, task: task)));
        },
        child: ListTile(
          isThreeLine: true,
          trailing: Checkbox(
            value: task.isNew,
            onChanged: (bool value) async {
              task.isNew = value;
              await task.update();
              await _loadData();
            },
          ),
          title: Text(task.routePriority.toString() + '|' + task.code + ' : ' + task.terminalBreakName),
          subtitle: RichText(
            text: TextSpan(
              children: <TextSpan>[
                TextSpan(text: task.address + '\n', style: TextStyle(color: Colors.grey)),
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
      appBar: AppBar(
        title: Text('Задачи'),
        actions: <Widget>[
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
