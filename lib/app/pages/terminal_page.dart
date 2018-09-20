import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/models/terminal_worktime.dart';
import 'package:repairman/app/pages/task_page.dart';
import 'package:repairman/app/utils/format.dart';

class TerminalPage extends StatefulWidget {
  final Terminal terminal;

  TerminalPage({Key key, @required this.terminal}) : super(key: key);

  @override
  _TerminalPageState createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final EdgeInsets listViewItemsPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0);
  final EdgeInsets headingPadding = EdgeInsets.only(top: 12.0);
  final TextStyle headingStyle = TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, height: 24.0/15.0);
  List<Task> _tasks = [];
  List<TerminalWorktime> _terminalWorktimes = [];

  Future<void> _loadData() async {
    _tasks = await Task.byPpsTerminalId(widget.terminal.id);
    _terminalWorktimes = await TerminalWorktime.byPpsTerminalId(widget.terminal.id);

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

  Widget _buildDayRow(String dayName, int beginTime, int endTime, bool dayEx) {
    String displayStr;

    if ((beginTime == null && endTime == null) || dayEx) {
      displayStr = 'Исключен';
    } else {
      displayStr = Format.timeStr(beginTime ?? 0) + ' - ' + Format.timeStr(endTime ?? 60*24-1);
    }

    return Row(
      children: <Widget>[
        Container(
          width: 112.0,
          child: Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Text(
              dayName,
              style: TextStyle(color: Colors.blue), textAlign: TextAlign.end
            )
          )
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.0, bottom: 4.0, left: 24.0),
          child: Text(
            displayStr,
            style: TextStyle(color: Colors.black)
          )
        ),
        Divider()
      ]
    );
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
          child: Text(rightStr)
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
        _buildTableRow('Оператор', widget.terminal.mobileop),
        _buildTableRow('Сигнал', Format.untilStr(widget.terminal.lastActivityTime)),
        _buildTableRow('Платеж', Format.untilStr(widget.terminal.lastPaymentTime)),
        _buildTableRow('Ошибка', widget.terminal.errorText ?? ''),
        _buildTableRow('Адрес', widget.terminal.address),
      ]
    );
  }

  Widget _buildTaskColumn() {
    List<Task> tasks = _tasks ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: headingPadding,
          child: Text('Задачи', style: headingStyle)
        )
      ]..addAll(tasks.map((Task task) => _buildTaskRow(task)))
    );
  }

  Widget _buildScheduleColumn() {
    Terminal terminal = widget.terminal;

    List<Widget> dayList = _terminalWorktimes.map((TerminalWorktime worktime) {
      return _buildDayRow(
        Format.dayOfWeek(worktime.weekday),
        worktime.timeBegin,
        worktime.timeEnd,
        worktime.exclude
      );
    }).toList();

    Widget excludeText = Padding(
      padding: EdgeInsets.only(top: 8.0, bottom: 4.0, left: 8.0),
      child: Text('Исключен из маршрута')
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: headingPadding,
          child: Text('Расписание', style: headingStyle)
        ),
      ]..addAll(terminal.exclude ? [excludeText] : dayList)
    );
  }

  Widget _buildClosedDaysColumn() {
    Terminal terminal = widget.terminal;
    if (terminal.closedDaysBegin == null) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: headingPadding,
          child: Text('Простой', style: headingStyle)
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.0, bottom: 4.0, left: 8.0),
          child: Text(
            'С ${Format.defaultWithTime(terminal.closedDaysBegin)} по ${Format.defaultWithTime(terminal.closedDaysEnd)}',
          )
        ),
      ]
    );
  }

  _buildListViewItem(Widget child) {
    return Container(
      padding: listViewItemsPadding,
      child: child
    );
  }

  Widget _buildBody(BuildContext context) {
    Terminal terminal = widget.terminal;
    double longitude = terminal.longitude;
    double latitude = terminal.latitude;

    return ListView(
      padding: EdgeInsets.only(left: 8.0, right: 8.0, bottom: 64.0),
      children: <Widget>[
        _buildListViewItem(_buildTable()),
        _buildListViewItem(
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _showPlacemarkOnMap(longitude, latitude),
            child: Image.network(
              'https://static-maps.yandex.ru/1.x/?ll=$longitude,$latitude&size=320,240&z=18&l=map&pt=$longitude,$latitude,comma'
            )
          )
        ),
        _buildListViewItem(_buildScheduleColumn()),
        _buildListViewItem(_buildClosedDaysColumn()),
        _buildListViewItem(_buildTaskColumn()),
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
        title: Text('Терминал ${widget.terminal.code}')
      ),
      body: _buildBody(context)
    );
  }
}
