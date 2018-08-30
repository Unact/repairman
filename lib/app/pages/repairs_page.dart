import 'dart:async';

import 'package:flutter/material.dart';

import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/models/repair.dart';
import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/task_repair_link.dart';

class RepairsPage extends StatefulWidget {
  final Task task;

  RepairsPage({Key key, @required this.task}) : super(key: key);

  @override
  _RepairsPageState createState() => _RepairsPageState();
}

class _RepairsPageState extends State<RepairsPage> {
  List<Repair> _repairs = [];
  List<TaskRepairLink> _taskRepairs = [];

  Future<void> _loadData() async {
    _repairs = await Repair.all();
    _repairs.sort((rep1, rep2) => rep1.name.compareTo(rep2.name));
    _taskRepairs = await TaskRepairLink.byTaskId(widget.task.id);

    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildBody(BuildContext context) {
    List<Repair> repairs = _repairs ?? [];

    return Container(
      padding: EdgeInsets.only(left: 8.0, right: 8.0),
      child: ListView(
        children: repairs.map((Repair repair) {
          Function taskRepLinkSearch = (taskRep) => taskRep.repairId == repair.id;

          return ListTile(
            onTap: () {},
            title: Text(repair.name),
            trailing: Checkbox(
              value: _taskRepairs.any((taskRep) => taskRepLinkSearch(taskRep) && !taskRep.localDeleted),
              onChanged: (bool value) async {
                await DatabaseModel.createOrDeleteFromList(
                  _taskRepairs,
                  taskRepLinkSearch,
                  TaskRepairLink({'task_id': widget.task.id, 'repair_id': repair.id}),
                  value
                );

                setState(() {});
              }
            ),
          );
        }).toList()
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
        title: Text('Ремонты'),
      ),
      body: _buildBody(context)
    );
  }
}
