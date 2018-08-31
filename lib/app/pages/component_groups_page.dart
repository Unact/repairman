import 'dart:async';

import 'package:flutter/material.dart';

import 'package:repairman/app/models/component_group.dart';
import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/pages/component_group_page.dart';

class ComponentGroupsPage extends StatefulWidget {
  final Task task;

  ComponentGroupsPage({Key key, @required this.task}) : super(key: key);

  @override
  _ComponentGroupsPageState createState() => _ComponentGroupsPageState();
}

class _ComponentGroupsPageState extends State<ComponentGroupsPage> {
  List<ComponentGroup> _componentGroups = [];

  Future<void> _loadData() async {
    _componentGroups = await ComponentGroup.allFree(widget.task.id);

    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildBody(BuildContext context) {
    List<ComponentGroup> compnentGroups = _componentGroups ?? [];

    return Container(
      padding: EdgeInsets.only(left: 8.0, right: 8.0, top: 16.0),
      child: ListView(
        children: compnentGroups.map((ComponentGroup componentGroup) {
          return ListTile(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ComponentGroupPage(task: widget.task, componentGroup: componentGroup),
                  fullscreenDialog: true
                )
              );
              await _loadData();
            },
            title: Text(componentGroup.name),
            subtitle: _buildComponentGroupSubtitle(componentGroup)
          );
        }).toList()
      )
    );
  }

  Widget _buildComponentGroupSubtitle(ComponentGroup componentGroup) {
    return RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.blue, fontSize: 12.0),
        children: <TextSpan>[
          componentGroup.freecnt == 0 ? TextSpan() : TextSpan(text: 'Остаток: ${componentGroup.freecnt}\n'),
          componentGroup.inscnt == 0 ? TextSpan() : TextSpan(text: 'Установлено: ${componentGroup.inscnt}\n')
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
        title: Text('ЗИПы'),
      ),
      body: _buildBody(context)
    );
  }
}
