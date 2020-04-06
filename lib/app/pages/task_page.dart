import 'dart:async';
import 'dart:convert';
import 'dart:io';


import 'package:barcode_scan/barcode_scan.dart';
import 'package:great_circle_distance/great_circle_distance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/task_defect_link.dart';
import 'package:repairman/app/models/task_repair_link.dart';
import 'package:repairman/app/models/terminal_image_temp.dart';
import 'package:repairman/app/models/terminal_image.dart';
import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/models/terminal_component_link.dart';
import 'package:repairman/app/models/user.dart';
import 'package:repairman/app/modules/api.dart';
import 'package:repairman/app/pages/component_groups_page.dart';
import 'package:repairman/app/pages/defects_page.dart';
import 'package:repairman/app/pages/repairs_page.dart';
import 'package:repairman/app/pages/terminal_page.dart';
import 'package:repairman/app/utils/format.dart';
import 'package:repairman/data/data_sync.dart';

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
  StreamSubscription<SyncEvent> syncStreamSubscription;
  int _taskRepairCnt = 0;
  int _taskDefectCnt = 0;
  int _taskComponentCnt = 0;
  bool _actionsEnabled = true;
  List<TerminalImage> _terminalImages = [];
  List<TerminalImageTemp> _terminalImagesTemp = [];
  List<DateTime> _imagesCts = [];

  Future<void> _loadData() async {
    Function searchFn = (rec) => !rec.localDeleted;
    _taskRepairCnt = (await TaskRepairLink.byTaskId(widget.task.id)).where(searchFn).length;
    _taskDefectCnt = (await TaskDefectLink.byTaskId(widget.task.id)).where(searchFn).length;
    _taskComponentCnt = (await TerminalComponentLink.byTaskId(widget.task.id)).where(searchFn).length;
    _terminalImages = await TerminalImage.byPpsTerminalId(widget.task.ppsTerminalId);
    _terminalImagesTemp = await TerminalImageTemp.byPpsTerminalId(widget.task.ppsTerminalId);

    _imagesCts = _terminalImages.map((e) => e.cts).toList() + _terminalImagesTemp.map((e) => e.localTs).toList();
    _imagesCts.sort((a, b) => a.isBefore(b) ? 1 : -1);

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
          child: GestureDetector(
            child: Text(rightStr),
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: rightStr));
              _showSnackBar('Скопировано');
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
                enabled: _actionsEnabled,
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
        )
      ]..addAll(_buildActionTiles())
    );
  }

  List<Widget> _buildActionTiles() {
    return !_actionsEnabled ? [Center(heightFactor: 2.0, child: CircularProgressIndicator())] : [
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
      ListTile(
        dense: true,
        title: Text('Добавить фотографию (${_imagesCts.length})', style: defaultTextStyle),
        contentPadding: listPanelPadding,
        onTap: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Padding(padding: EdgeInsets.all(5.0), child: Center(child: CircularProgressIndicator()));
            }
          );

          File tempfile = await ImagePicker.pickImage(source: ImageSource.camera);

          if (tempfile == null) {
            Navigator.pop(context);
            return;
          }

          Directory directory = await getApplicationDocumentsDirectory();
          File file = await tempfile.copy('${directory.path}/${tempfile.path.split('/').last}');
          TerminalImageTemp image = TerminalImageTemp(
            ppsTerminalId: widget.task.ppsTerminalId,
            filepath: file.path
          );
          await image.markAndInsert();
          await _loadData();
          Navigator.pop(context);
          _showSnackBar('Фотография успешно сохранена');
        }
      ),
      ListTile(
        dense: true,
        title: Text('Сохранить фотографии (${_terminalImagesTemp.length})', style: defaultTextStyle),
        contentPadding: listPanelPadding,
        onTap: _terminalImagesTemp.isEmpty ? null : () async {
          try {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return Padding(padding: EdgeInsets.all(5.0), child: Center(child: CircularProgressIndicator()));
              }
            );

            await App.application.data.dataSync.syncImageData();
            await _loadData();
            Navigator.pop(context);
            _showSnackBar('Фотографии успешно сохранены');
          } on ApiException catch(e) {
            Navigator.pop(context);
            _showSnackBar(e.errorMsg);
          }
        }
      ),
      _buildGeoTile()
    ];
  }

  void _showSnackBar(String errorMsg) {
    _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(errorMsg)));
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
    User user = User.currentUser;
    double distance = GreatCircleDistance.fromDegrees(
      latitude1: widget.terminal.latitude,
      longitude1: widget.terminal.longitude,
      latitude2: user.curLatitude,
      longitude2: user.curLongitude
    ).haversineDistance();

    if (_imagesCts.isEmpty || DateTime.now().difference(_imagesCts.first).inDays > 30) {
      _showSnackBar('Необходимо сфотографировать терминал');
      return;
    }

    if (distance > 500) {
      _showSnackBar('До терминала ${distance.floor()} м (больше чем 500м)');
      return;
    }

    widget.task.executionmarkTs = DateTime.now();
    widget.task.markLatitude = user.curLatitude;
    widget.task.markLongitude = user.curLongitude;
    widget.task.markAndUpdate();
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
    syncStreamSubscription = App.application.data.dataSync.stream.listen((SyncEvent syncEvent) {
      switch(syncEvent) {
        case(SyncEvent.syncStarted):
          _actionsEnabled = false;
          setState(() {});
          break;
        case(SyncEvent.syncCompleted):
          _actionsEnabled = true;
          setState(() {});
          break;
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();

    syncStreamSubscription.cancel();
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
