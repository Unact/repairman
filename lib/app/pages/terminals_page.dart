import 'dart:async';

import 'package:flutter/material.dart';

import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/utils/format.dart';

class TerminalsPage extends StatefulWidget {
  TerminalsPage({
    Key key
  }) : super(key: key);

  @override
  _TerminalsPageState createState() => _TerminalsPageState();
}

class _TerminalsPageState extends State<TerminalsPage> {
  List<Terminal> _terminals = [];

  Future<void> _loadData() async {
    _terminals = await Terminal.all();
    _terminals.sort((terminal1, terminal2) => terminal1.terminalId.compareTo(terminal2.terminalId));

    if (mounted) {
      setState((){});
    }
  }

  Widget _terminalTile(BuildContext context, Terminal terminal) {
    return ListTile(
      isThreeLine: true,
      title: Text(terminal.terminalId.toString() + ' | ' + terminal.code),
      subtitle: RichText(
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(text: terminal.address + '\n', style: TextStyle(color: Colors.grey)),
            TextSpan(text: Format.untilStr(terminal.lastActivityTime), style: TextStyle(color: Colors.blue))
          ]
        )
      )
    );
  }

  Widget _buildBody(BuildContext context) {
    List<Terminal> terminals = _terminals ?? [];

    return Container(
      padding: EdgeInsets.only(left: 8.0, right: 8.0),
      child: ListView(
        children: terminals.map((terminal) => _terminalTile(context, terminal)).toList()
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
        title: Text('Терминалы')
      ),
      body: _buildBody(context)
    );
  }
}
