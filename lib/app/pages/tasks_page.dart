import 'dart:async';

import 'package:flutter/material.dart';

import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/utils/format.dart';

class TasksPage extends StatefulWidget {
  TasksPage({
    Key key
  }) : super(key: key);

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<Task> _tasks = [];

  Future<void> _loadData() async {
    _tasks = await Task.allWithTerminalInfo();

    if (mounted) {
      setState((){});
    }
  }

  Widget _taskTile(BuildContext context, Task task) {
    Map<String, Color> colors = task.colors();
      return Container(
        color: colors['bcolor'],
        child: ListTile(
          isThreeLine: true,
          title: Text(task.routePriority.toString() + '|' + task.code + ' : ' + task.terminalBreakName),
          subtitle: RichText(
            text: TextSpan(
              children: <TextSpan>[
                TextSpan(text: task.address + '\n', style: TextStyle(color: colors['tcolor'])),
                TextSpan(text: Format.untilStr(task.dobefore), style: TextStyle(color: Colors.blue))
              ]
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
            backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
            children: tasks.where((task) => !task.servstatus).map((task) => _taskTile(context, task)).toList()
          ),
          ExpansionTile(
            initiallyExpanded: false,
            title: Text('Выполненные'),
            backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
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
        title: Text('Задачи')
      ),
      body: _buildBody(context)
    );
  }
}
