import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'package:repairman/app/models/user.dart';
import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/terminal_image.dart';
import 'package:repairman/app/models/terminal_worktime.dart';
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
  final GlobalKey _appBarKey = GlobalKey();
  final EdgeInsets listViewItemsPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0);
  final EdgeInsets headingPadding = EdgeInsets.only(top: 12.0);
  final TextStyle headingStyle = TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, height: 24.0/15.0);
  List<Task> _tasks = [];
  List<TerminalWorktime> _terminalWorktimes = [];
  List<TerminalImage> _terminalImages = [];
  Placemark _placemark;

  Future<void> _loadData() async {
    Terminal terminal = widget.terminal;
    _placemark = Placemark(
      point: Point(longitude: terminal.longitude, latitude: terminal.latitude),
      iconName: 'lib/app/assets/images/placeicon.png',
      onTap: (double lat, double lon) async {
        String str = '${terminal.latitude},${terminal.longitude}';

        Clipboard.setData(ClipboardData(text: str));
        _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text('Скопированы координаты точки')));
      }
    );
    _terminalImages = await TerminalImage.byPpsTerminalId(terminal.id);
    _terminalWorktimes = await TerminalWorktime.byPpsTerminalId(terminal.id);
    _tasks = await Task.byPpsTerminalId(terminal.id);

    if (mounted) {
      setState(() {});
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
        _buildTableRow('Оператор', widget.terminal.mobileop),
        _buildTableRow('Сигнал', Format.untilStr(widget.terminal.lastActivityTime)),
        _buildTableRow('Платеж', Format.untilStr(widget.terminal.lastPaymentTime)),
        _buildTableRow('Ошибка', widget.terminal.errorText ?? ''),
        _buildTableRow('Адрес', widget.terminal.address),
        _buildTableRow('Инк.', widget.terminal.hasInc ? 'Да' : 'Нет'),
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

  Widget _buildImageColumn() {
    List<TerminalImage> terminalImages = _terminalImages ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: headingPadding,
          child: Text('Фотографии', style: headingStyle)
        )
      ]..addAll(
        terminalImages.map(
          (TerminalImage image) => Center(
            child: Container(
              padding: listViewItemsPadding,
              child: CachedNetworkImage(
                width: 256,
                height: 256,
                imageUrl: image.mediumUrl,
                placeholder: (context, url) => Container(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              )
            )
          )
        )
      )
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
    return ListView(
      padding: EdgeInsets.only(left: 8.0, right: 8.0, bottom: 64.0),
      children: <Widget>[
        _buildListViewItem(_buildTable()),
        _buildListViewItem(
          SizedBox(
            width: 160.0,
            height: 240.0,
            child: YandexMap(
              onMapCreated: (YandexMapController controller) async {
                await controller.addPlacemark(_placemark);
                await controller.move(point: _placemark.point, zoom: 17.0);
              }
            )
          )
        ),
        _buildListViewItem(_buildScheduleColumn()),
        _buildListViewItem(_buildClosedDaysColumn()),
        _buildListViewItem(_buildTaskColumn()),
        _buildListViewItem(_buildImageColumn()),
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
        key: _appBarKey,
        title: Text('Терминал ${widget.terminal.code}')
      ),
      body: _buildBody(context)
    );
  }
}
