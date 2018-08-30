import 'dart:async';

import 'package:flutter/material.dart';

import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/models/defect.dart';
import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/task_defect_link.dart';

class DefectsPage extends StatefulWidget {
  final Task task;

  DefectsPage({Key key, @required this.task}) : super(key: key);

  @override
  _DefectsPageState createState() => _DefectsPageState();
}

class _DefectsPageState extends State<DefectsPage> {
  List<Defect> _defects = [];
  List<TaskDefectLink> _taskDefects = [];

  Future<void> _loadData() async {
    _defects = await Defect.all();
    _defects.sort((rep1, rep2) => rep1.name.compareTo(rep2.name));
    _taskDefects = await TaskDefectLink.byTaskId(widget.task.id);

    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildBody(BuildContext context) {
    List<Defect> defects = _defects ?? [];

    return Container(
      padding: EdgeInsets.only(left: 8.0, right: 8.0),
      child: ListView(
        children: defects.map((Defect defect) {
          Function taskDefLinkSearch = (taskDef) => taskDef.defectId == defect.id;

          return ListTile(
            onTap: () {},
            title: Text(defect.name),
            trailing: Checkbox(
              value: _taskDefects.any((taskDef) => taskDefLinkSearch(taskDef) && !taskDef.localDeleted),
              onChanged: (bool value) async {
                await DatabaseModel.createOrDeleteFromList(
                  _taskDefects,
                  taskDefLinkSearch,
                  TaskDefectLink({'task_id': widget.task.id, 'defect_id': defect.id}),
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
        title: Text('Неисправности'),
      ),
      body: _buildBody(context)
    );
  }
}
