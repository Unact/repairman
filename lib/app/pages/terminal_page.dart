import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/utils/format.dart';

class TerminalPage extends StatefulWidget {
  final Terminal ppsTerminal;

  TerminalPage({Key key, @required this.ppsTerminal}) : super(key: key);

  @override
  _TerminalPageState createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final EdgeInsets mainPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0);
  final TextStyle headingStyle = TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, height: 24.0/15.0);
  final TextStyle defaultStyle = TextStyle(fontSize: 8.0, fontWeight: FontWeight.bold, height: 24.0/15.0);
  List<Task> _tasks = [];

  Future<void> _loadData() async {
    _tasks = await Task.byPpsTerminalId(widget.ppsTerminal.id);

    if (mounted) {
      setState((){});
    }
  }

  void _showPlacemarkOnMap(double longitude, double latitude) async {
    String url = 'https://maps.yandex.ru/?pt=$longitude,$latitude&ll=$longitude,$latitude&z=18&l=map';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildTaskRow(Task task) {
    return GestureDetector(
      onTap: () => print('asd'),
      child: Row(
        children: <Widget>[
          Container(
            width: 84.0,
            child: Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Text('${task.routePriority.toString()}-${task.terminalBreakName}',
                style: TextStyle(color: Colors.blue), textAlign: TextAlign.end
              )
            )
          ),
          Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 4.0, left: 24.0),
            child: Text(Format.untilStr(task.dobefore))
          ),
          Divider()
        ]
      )
    );
  }

  TableRow _buildTableRow(String leftStr, String rightStr) {
    return TableRow(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 8.0, bottom: 4.0, right: 8.0),
          child: Text(leftStr, style: TextStyle(color: Colors.blue), textAlign: TextAlign.end)
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
          child: Text(rightStr)
        ),
      ]
    );
  }

  Table _buildTable() {
    return Table(
      columnWidths: <int, TableColumnWidth>{
        0: FixedColumnWidth(80.0)
      },
      children: <TableRow>[
        TableRow(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 12.0, bottom: 4.0),
              child: Text('Терминал', style: headingStyle)
            ),
            SizedBox(),
          ]
        ),
        _buildTableRow('ID', widget.ppsTerminal.terminalId.toString()),
        _buildTableRow('Код', widget.ppsTerminal.code),
        _buildTableRow('Система', widget.ppsTerminal.srcSystemName),
        _buildTableRow('Сигнал', Format.untilStr(widget.ppsTerminal.lastActivityTime)),
        _buildTableRow('Платеж', Format.untilStr(widget.ppsTerminal.lastPaymentTime)),
        _buildTableRow('Ошибка', widget.ppsTerminal.errorText ?? ''),
        _buildTableRow('Адрес', widget.ppsTerminal.address),
      ]
    );
  }

  Widget _buildBody(BuildContext context) {
    List<Task> tasks = _tasks ?? [];
    double longitude = widget.ppsTerminal.longitude;
    double latitude = widget.ppsTerminal.latitude;

    return ListView(
      padding: EdgeInsets.only(left: 8.0, right: 8.0),
      children: <Widget>[
        Container(
          padding: mainPadding,
          child: _buildTable(),
        ),
        Container(
          padding: mainPadding,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _showPlacemarkOnMap(longitude, latitude),
            child: Image.network(
              'https://static-maps.yandex.ru/1.x/?ll=$longitude,$latitude&size=320,240&z=18&l=map&pt=$longitude,$latitude,comma'
            )
          ),
        ),
        Container(
          padding: mainPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 12.0, bottom: 4.0),
                child: Text('Задачи', style: headingStyle)
              )
            ]..addAll(tasks.map((Task task) => _buildTaskRow(task)))
          )
        )
      ]
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
        title: Text('Терминал ${widget.ppsTerminal.code}')
      ),
      body: _buildBody(context)
    );
  }
}
