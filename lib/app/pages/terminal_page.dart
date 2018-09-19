import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/pages/task_page.dart';
import 'package:repairman/app/utils/format.dart';


class TerminalPage extends StatefulWidget {
  final Terminal terminal;

  TerminalPage({Key key, @required this.terminal}) : super(key: key);

  @override
  _TerminalPageState createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final EdgeInsets listViewItemsPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0);
  final EdgeInsets headingPadding = EdgeInsets.only(top: 12.0);
  final TextStyle headingStyle = TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, height: 24.0/15.0);
  List<Task> _tasks = [];

  Future<void> _loadData() async {
    _tasks = await Task.byPpsTerminalId(widget.terminal.id);

    if (mounted) {
      setState(() {});
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
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaskPage(terminal: widget.terminal, task: task))
        );
      },
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
          child: GestureDetector(
            child: Text(rightStr),
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: rightStr));
              _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text('Скопировано')));
            },
          )
        ),
      ]
    );
  }

  Table _buildTable() {
    return Table(
      columnWidths: <int, TableColumnWidth>{
        0: FixedColumnWidth(88.0)
      },
      children: <TableRow>[
        TableRow(
          children: <Widget>[
            Padding(
              padding: headingPadding,
              child: Text('Терминал', style: headingStyle)
            ),
            SizedBox(),
          ]
        ),
        _buildTableRow('ID', widget.terminal.terminalId.toString()),
        _buildTableRow('Код', widget.terminal.code),
        _buildTableRow('Система', widget.terminal.srcSystemName),
        _buildTableRow('Сигнал', Format.untilStr(widget.terminal.lastActivityTime)),
        _buildTableRow('Платеж', Format.untilStr(widget.terminal.lastPaymentTime)),
        _buildTableRow('Ошибка', widget.terminal.errorText ?? ''),
        _buildTableRow('Адрес', widget.terminal.address),
      ]
    );
  }

  Widget _buildBody(BuildContext context) {
    List<Task> tasks = _tasks ?? [];
    double longitude = widget.terminal.longitude;
    double latitude = widget.terminal.latitude;

    return ListView(
      padding: EdgeInsets.only(left: 8.0, right: 8.0),
      children: <Widget>[
        Container(
          padding: listViewItemsPadding,
          child: _buildTable(),
        ),
        Container(
          padding: listViewItemsPadding,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _showPlacemarkOnMap(longitude, latitude),
            child: Image.network(
              'https://static-maps.yandex.ru/1.x/?ll=$longitude,$latitude&size=320,240&z=18&l=map&pt=$longitude,$latitude,comma'
            )
          ),
        ),
        Container(
          padding: listViewItemsPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: headingPadding,
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
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Терминал ${widget.terminal.code}')
      ),
      body: _buildBody(context)
    );
  }
}
