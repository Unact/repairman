import 'dart:async';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/terminal.dart';
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
  final EdgeInsets listViewItemsPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0);
  final EdgeInsets listPanelPadding = EdgeInsets.only(left: 16.0);
  final EdgeInsets headingPadding = EdgeInsets.only(top: 12.0);
  final EdgeInsets baseColumnPadding = EdgeInsets.only(top: 8.0, bottom: 4.0);
  final EdgeInsets firstColumnPadding = EdgeInsets.only(top: 8.0, bottom: 4.0, right: 8.0);
  final TextStyle headingStyle = TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, height: 24.0/15.0);
  final TextStyle defaultTextStyle = TextStyle(fontSize: 14.0, color: Colors.black);
  final TextStyle firstColumnTextStyle = TextStyle(color: Colors.blue);

  void _scanBarcode() async {
    try {
      String barcode = await BarcodeScanner.scan();
      widget.task.invNum = barcode;
      await widget.task.update();
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
              child: Text('Коммент.', style: firstColumnTextStyle, textAlign: TextAlign.end)
            ),
            Padding(
              padding: baseColumnPadding,
              child: TextFormField(
                initialValue: widget.task.info,
                style: defaultTextStyle,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(),
                ),
                onFieldSubmitted: (String value) async {
                  widget.task.info = value;
                  await widget.task.update();
                  setState((){});
                }
              ),
            ),
          ]
        ),
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
          title: Text('Неисправности', style: defaultTextStyle),
          contentPadding: listPanelPadding,
          onTap: () {

          }
        ),
        ListTile(
          dense: true,
          title: Text('Ремонты', style: defaultTextStyle),
          contentPadding: listPanelPadding,
          onTap: () {

          }
        ),
        ListTile(
          dense: true,
          title: Text('ЗИПы', style: defaultTextStyle),
          contentPadding: listPanelPadding,
          onTap: () {

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
    if (!widget.task.servstatus) {
      return Container();
    } else {
      if (widget.task.executionmarkTs != null) {
        return ListTile(
          dense: true,
          title: Text('Отметить выполнение', style: defaultTextStyle),
          contentPadding: listPanelPadding,
          onTap: () {

          }
        );
      } else {
        return ListTile(
          dense: true,
          title: Text('Поставить геометку', style: defaultTextStyle),
          contentPadding: listPanelPadding,
          onTap: () {

          }
        );
      }
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Задача')
      ),
      body: _buildBody(context)
    );
  }
}
