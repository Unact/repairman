import 'dart:async';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:great_circle_distance/great_circle_distance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/task_defect_link.dart';
import 'package:repairman/app/models/task_repair_link.dart';
import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/models/terminal_component_link.dart';
import 'package:repairman/app/models/user.dart';
import 'package:repairman/app/pages/component_groups_page.dart';
import 'package:repairman/app/pages/defects_page.dart';
import 'package:repairman/app/pages/repairs_page.dart';
import 'package:repairman/app/pages/terminal_page.dart';
import 'package:repairman/app/utils/format.dart';

class TaskPage extends StatefulWidget {
  final Task task;
  final Terminal terminal;

  TaskPage({Key key, @required this.task, @required this.terminal}) : super(key: key);

  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final EdgeInsets listViewItemsPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0);
  final EdgeInsets listPanelPadding = EdgeInsets.only(left: 16.0);
  final EdgeInsets headingPadding = EdgeInsets.only(top: 12.0);
  final EdgeInsets baseColumnPadding = EdgeInsets.only(top: 8.0, bottom: 4.0);
  final EdgeInsets firstColumnPadding = EdgeInsets.only(top: 8.0, bottom: 4.0, right: 8.0);
  final TextStyle headingStyle = TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, height: 24.0/15.0);
  final TextStyle defaultTextStyle = TextStyle(fontSize: 14.0, color: Colors.black);
  final TextStyle firstColumnTextStyle = TextStyle(color: Colors.blue);
  int _taskRepairCnt = 0;
  int _taskDefectCnt = 0;
  int _taskComponentCnt = 0;

  Future<void> _loadData() async {
    Function searchFn = (rec) => !rec.localDeleted;
    _taskRepairCnt = (await TaskRepairLink.byTaskId(widget.task.id)).where(searchFn).length;
    _taskDefectCnt = (await TaskDefectLink.byTaskId(widget.task.id)).where(searchFn).length;
    _taskComponentCnt = (await TerminalComponentLink.byTaskId(widget.task.id)).where(searchFn).length;

    if (mounted) {
      setState(() {});
    }
  }

  void _scanBarcode() async {
    try {
      String barcode = await BarcodeScanner.scan();
      widget.task.invNum = barcode;
      await widget.task.markAndUpdate();
      setState(() {});
    } on PlatformException catch (e) {
      String errorMsg = 'Не известная ошибка: $e';

      if (e.code == BarcodeScanner.CameraAccessDenied) {
        errorMsg = 'Необходимо дать доступ к использованию камеры';
      }

      showDialog(context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Ошибка инв. номера'),
            content: Text(errorMsg),
          );
        }
      );
    }
  }

  TableRow _buildTableRow(String leftStr, String rightStr) {
    return TableRow(
      children: <Widget>[
        Padding(
          padding: firstColumnPadding,
          child: Text(leftStr, style: firstColumnTextStyle, textAlign: TextAlign.end)
        ),
        Padding(
          padding: baseColumnPadding,
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
              child: Text('Инфо', style: headingStyle)
            ),
            SizedBox(),
          ]
        ),
        _buildTableRow('Статус', widget.task.servstatus ? 'Выполнен' : 'Не выполнен'),
        _buildTableRow('Поломка', widget.task.terminalBreakName),
        _buildTableRow('Срок', Format.untilStr(widget.task.dobefore)),
        _buildTableRow('Код', widget.terminal.code),
        _buildTableRow('Платеж', Format.untilStr(widget.terminal.lastPaymentTime)),
        _buildTableRow('Геометка', Format.untilStr(widget.task.executionmarkTs)),
        TableRow(
          children: <Widget>[
            Padding(
              padding: firstColumnPadding,
              child: Text('Инв. номер', style: firstColumnTextStyle, textAlign: TextAlign.end)
            ),
            Padding(
              padding: baseColumnPadding,
              child: GestureDetector(
                onTap: _scanBarcode,
                child: Text(widget.task.invNum ?? '')
              )
            ),
          ]
        ),
        TableRow(
          children: <Widget>[
            Padding(
              padding: firstColumnPadding,
              child: Text('Коммент.', style: firstColumnTextStyle, textAlign: TextAlign.end)
            ),
            Padding(
              padding: baseColumnPadding,
              child: TextFormField(
                maxLines: 4,
                keyboardType: TextInputType.text,
                initialValue: widget.task.info,
                style: defaultTextStyle,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(),
                ),
                onFieldSubmitted: (String value) async {
                  widget.task.info = value;
                  await widget.task.markAndUpdate();
                  setState(() {});
                }
              ),
            ),
          ]
        )
      ]
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: headingPadding,
          child: Text('Действия', style: headingStyle)
        ),
        ListTile(
          dense: true,
          title: Text('Неисправности ($_taskDefectCnt)', style: defaultTextStyle),
          contentPadding: listPanelPadding,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DefectsPage(task: widget.task), fullscreenDialog: true)
            );
            await _loadData();
          }
        ),
        ListTile(
          dense: true,
          title: Text('Ремонты ($_taskRepairCnt)', style: defaultTextStyle),
          contentPadding: listPanelPadding,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RepairsPage(task: widget.task), fullscreenDialog: true)
            );
            await _loadData();
          }
        ),
        ListTile(
          dense: true,
          title: Text('ЗИПы ($_taskComponentCnt)', style: defaultTextStyle),
          contentPadding: listPanelPadding,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ComponentGroupsPage(task: widget.task), fullscreenDialog: true)
            );
            await _loadData();
          }
        ),
        ListTile(
          dense: true,
          title: Text('Терминал', style: defaultTextStyle),
          contentPadding: listPanelPadding,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TerminalPage(terminal: widget.terminal))
            );
          }
        ),
        _buildGeoTile()
      ]
    );
  }

  Widget _buildGeoTile() {
    if (widget.task.servstatus) {
      return Container();
    } else {
      if (widget.task.executionmarkTs != null) {
        return ListTile(
          dense: true,
          title: Text('Отметить выполнение', style: defaultTextStyle),
          contentPadding: listPanelPadding,
          onTap: () async {
            widget.task.servstatus = true;
            widget.task.markAndUpdate();
            await _loadData();
          }
        );
      } else {
        return ListTile(
          dense: true,
          title: Text('Поставить геометку', style: defaultTextStyle),
          contentPadding: listPanelPadding,
          onTap: () async {
            _setExecutionMark();
            await _loadData();
          }
        );
      }
    }
  }

  Future<void> _setExecutionMark() async {
    User user = User.currentUser();
    double distance = GreatCircleDistance.fromDegrees(
      latitude1: widget.terminal.latitude,
      longitude1: widget.terminal.longitude,
      latitude2: user.curLatitude,
      longitude2: user.curLongitude
    ).haversineDistance();

    if (distance > 500) {
      _scaffoldKey.currentState?.showSnackBar(SnackBar(
        content: Text('До терминала ${distance.floor()} м (больше чем 500м)')
      ));
    } else {
      widget.task.executionmarkTs = DateTime.now();
      widget.task.markLatitude = user.curLatitude;
      widget.task.markLongitude = user.curLongitude;
      widget.task.markAndUpdate();
    }
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(left: 8.0, right: 8.0),
      children: <Widget>[
        Container(
          padding: listViewItemsPadding,
          child: _buildTable(),
        ),
        Container(
          padding: listViewItemsPadding,
          child: _buildActions()
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
        title: Text('Задача')
      ),
      body: _buildBody(context)
    );
  }
}
