import 'dart:async';

import 'package:flutter/material.dart';

import 'package:repairman/app/models/database_model.dart';
import 'package:repairman/app/models/component.dart';
import 'package:repairman/app/models/component_group.dart';
import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/terminal_component_link.dart';

class ComponentGroupPage extends StatefulWidget {
  final Task task;
  final ComponentGroup componentGroup;

  ComponentGroupPage({Key key, @required this.task, @required this.componentGroup}) : super(key: key);

  @override
  _ComponentGroupPageState createState() => _ComponentGroupPageState();
}

class _ComponentGroupPageState extends State<ComponentGroupPage> {
  List<Component> _components = [];
  List<TerminalComponentLink> _terminalComponents = [];

  Future<void> _loadData() async {
    _components = await Component.byComponentGroup(widget.componentGroup.id);
    _components.sort((rep1, rep2) => rep1.name.compareTo(rep2.name));
    _terminalComponents = await TerminalComponentLink.forTaskComponentGroup(widget.task.id, widget.componentGroup.id);

    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> _showConfirmDialog(Component comp) {
    bool installComp = !_terminalComponents.any((termComp) => comp.id == termComp.compId && !termComp.localDeleted);
    String confirmText = installComp ? 'Установить' : 'Снять';

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$confirmText деталь?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(comp.name),
                Text('Серийный номер: ${comp.serial}'),
              ]
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(confirmText),
              onPressed: () => Navigator.of(context).pop(true)
            ),
            FlatButton(
              child: Text('Отмена'),
              onPressed: () => Navigator.of(context).pop(false)
            )
          ]
        );
      },
    );
  }

  Widget _buildCompTile(Component comp) {
    bool isLocalDeleted = _terminalComponents.any(
      (termComp) => termComp.compId == comp.id && termComp.localDeleted
    );

    return ListTile(
      onTap: () async {
        if (await _showConfirmDialog(comp)) {
          await DatabaseModel.createOrDeleteFromList(
            _terminalComponents,
            (termComp) => termComp.compId == comp.id,
            TerminalComponentLink(taskId: widget.task.id, compId: comp.id, componentGroupId: comp.componentGroupId)
          );
          await _loadData();

          setState(() {});
        }
      },
      title: Text(comp.name),
      subtitle: Text('Серийный номер: ${comp.serial}', style: TextStyle(color: Colors.blue, fontSize: 12.0),),
      trailing: Text(isLocalDeleted ? 'Снят' : '', style: TextStyle(color: Colors.blue, fontSize: 14.0))
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 8.0, right: 8.0, top: 16.0),
      child: ListView(
        children: <Widget>[
          (_installedComponents().isNotEmpty) ? Text('Установлены') : Container()
        ]..addAll(
          _installedComponents()
        )..add(
          (_availableComponents().isNotEmpty) ? Text('Остаток') : Container()
        )..addAll(
          _availableComponents()
        )
      )
    );
  }

  List<Widget> _installedComponents() {
    return _terminalComponents.
      where((termComp) => !termComp.localDeleted).
      map((TerminalComponentLink termComp) {
        Component comp = _components.firstWhere((comp) => comp.id == termComp.compId);

        return _buildCompTile(comp);
      }).toList();
  }

  List<Widget> _availableComponents() {
    return _components.
      where((comp) =>
        _terminalComponents.any((termComp) => termComp.compId == comp.id && termComp.localDeleted) ||
        comp.isFree).
      map((Component comp) {
        return _buildCompTile(comp);
      }).toList();
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
        title: Text(widget.componentGroup.name),
      ),
      body: _buildBody(context)
    );
  }
}
