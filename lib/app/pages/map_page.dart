import 'dart:async';
import 'dart:math' show max, min;

import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/pages/terminal_page.dart';


class MapPage extends StatefulWidget {
  final List<Terminal> terminals;
  final List<Task> tasks;

  MapPage({Key key, @required this.terminals, @required this.tasks}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final double _kPointBoundMove = 0.1;

  Widget _buildBody(BuildContext context) {
    List<Placemark> placemarks = widget.terminals.where((terminal) => terminal.hasWork).map((Terminal terminal) {
      String iconPostfix = 'placedoneicon.png';

      if (terminal.hasInc) {
        iconPostfix = 'placeinc.png';
      }

      if (terminal.hasTask && widget.tasks.any((task) => task.isUncompleted && task.ppsTerminalId == terminal.id)) {
        iconPostfix = 'placenotdoneicon.png';
      }

      Point point = Point(latitude: terminal.latitude, longitude: terminal.longitude);
      Placemark placemark = Placemark(
        point: point,
        iconName: 'lib/app/assets/images/$iconPostfix',
        onTap: (Point point) async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => TerminalPage(terminal: terminal)));
        }
      );
      return placemark;
    }).toList();
    List<double> latitudes = placemarks.map((Placemark pl) => pl.point.latitude).toList();
    List<double> longitudes = placemarks.map((Placemark pl) => pl.point.longitude).toList();
    double maxLat = latitudes.reduce(max);
    double minLat = latitudes.reduce(min);
    double maxLon = longitudes.reduce(max);
    double minLon = longitudes.reduce(min);

    return YandexMap(
      onMapCreated: (YandexMapController controller) async {
        await controller.showUserLayer(
          iconName: 'lib/app/assets/images/usericon.png',
          arrowName: 'lib/app/assets/images/usericon.png'
        );
        await Future.wait(placemarks.map((Placemark placemark) => controller.addPlacemark(placemark)));
        await controller.setBounds(
          northEastPoint: Point(latitude: maxLat + _kPointBoundMove, longitude: maxLon + _kPointBoundMove),
          southWestPoint: Point(latitude: minLat - _kPointBoundMove, longitude: minLon - _kPointBoundMove)
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Карта'),
      ),
      body: _buildBody(context)
    );
  }
}
