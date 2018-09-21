import 'dart:math' show max, min;

import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/pages/terminal_page.dart';

class MapPage extends StatefulWidget {
  final List<Terminal> terminals;

  MapPage({Key key, @required this.terminals}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final double _kPointBoundMove = 0.1;
  final GlobalKey<YandexMapViewState> _mapKey = GlobalKey<YandexMapViewState>();

  Widget _buildBody(BuildContext context) {
    List<Placemark> placemarks = widget.terminals.map((Terminal terminal) {
      Point point = Point(latitude: terminal.latitude, longitude: terminal.longitude);
      Placemark placemark = Placemark(
        point: point,
        iconName: 'lib/app/assets/images/placeicon.png',
        onTap: (lat, lon) async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => TerminalPage(terminal: terminal)));
          await _mapKey.currentState?.refresh();
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

    return YandexMapView(
      key: _mapKey,
      afterMapRefresh: () async {
        YandexMap yandexMap = _mapKey.currentState.yandexMap;

        await yandexMap.showUserLayer(iconName: 'lib/app/assets/images/usericon.png');
        await yandexMap.removePlacemarks();
        await yandexMap.addPlacemarks(placemarks);
        await yandexMap.setBounds(
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
