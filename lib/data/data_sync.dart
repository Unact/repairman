import 'dart:async';

import 'package:sqflite/sqflite.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/component.dart';
import 'package:repairman/app/models/component_group.dart';
import 'package:repairman/app/models/defect.dart';
import 'package:repairman/app/models/geo_point.dart';
import 'package:repairman/app/models/repair.dart';
import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/task_defect_link.dart';
import 'package:repairman/app/models/task_repair_link.dart';
import 'package:repairman/app/models/terminal_component_link.dart';
import 'package:repairman/app/models/terminal_image.dart';
import 'package:repairman/app/models/terminal_image_temp.dart';
import 'package:repairman/app/models/terminal_worktime.dart';
import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/models/user.dart';
import 'package:repairman/app/modules/api.dart';

enum SyncEvent {
  syncStarted,
  syncCompleted,
  imageSyncStarted,
  imageSyncCompleted,
  geoPointsSyncStarted,
  geoPointsSyncCompleted
}

class DataSync {
  StreamController<SyncEvent> _streamController = StreamController<SyncEvent>();
  Stream<SyncEvent> stream;
  Timer syncTimer;
  String syncErrors;
  String syncImagesErrors;
  String syncGeoPointsErrors;
  bool _isSyncing = false;
  bool _isSyncingGeoPoints = false;
  bool _isSyncingImages = false;

  static const Duration kSyncTimerPeriod = Duration(minutes: 10);

  DataSync() {
    stream = _streamController.stream.asBroadcastStream();
  }

  DateTime getLastDataSyncTime() {
    String time = App.application.data.prefs.getString('lastDataSyncTime');
    return time != null ? DateTime.parse(time) : null;
  }

  Future<void> setLastDataSyncTime(DateTime val) async {
    await App.application.data.prefs.setString('lastDataSyncTime', val.toString());
  }

  void startSyncTimer() {
    syncTimer = _startTimer(syncTimer, _syncTimerCallback);
  }

  void stopSyncTimer() {
    _stopTimer(syncTimer);
  }

  void _syncTimerCallback(Timer curTimer) async {
    try {
      await syncAll();
    } on ApiException {}
  }

  Timer _startTimer(Timer timer, Function callback) {
    if (timer == null || !timer.isActive) {
      timer = Timer.periodic(kSyncTimerPeriod, callback);
    }

    return timer;
  }

  void _stopTimer(Timer timer) {
    if (timer != null && timer.isActive) {
      timer.cancel();
    }
  }

  Future<void> syncAll() async {
    await syncData();
    await syncImageData();
    await syncLocations();
  }

  Future<void> syncImageData() async {
    if (_isSyncingImages) return;

    try {
      _streamController.add(SyncEvent.imageSyncStarted);
      _isSyncingImages = true;

      await Future.forEach((await TerminalImageTemp.all()), (element) => element.saveToRemote());

      syncImagesErrors = null;
    } on ApiException catch(e) {
      syncImagesErrors = e.errorMsg;
      rethrow;
    } finally {
      _isSyncingImages = false;
      _streamController.add(SyncEvent.syncCompleted);
    }
  }

  Future<void> syncData() async {
    if (_isSyncing) return;

    try {
      _streamController.add(SyncEvent.syncStarted);
      _isSyncing = true;
      bool needImport = App.application.config.autoRefresh;
      Map<String, dynamic> exportData = await _dataForExport();

      if (exportData.values.any((val) => val.isNotEmpty)) {
        await _exportData(exportData);
        needImport = true;
      }

      if (needImport) {
        await _importData();
      }

      syncErrors = null;
    } on ApiException catch(e) {
      syncErrors = e.errorMsg;
      rethrow;
    } finally {
      await setLastDataSyncTime(DateTime.now());
      _isSyncing = false;
      _streamController.add(SyncEvent.syncCompleted);
    }
  }

  Future<void> _importData() async {
    await User.currentUser.loadDataFromRemote();

    Map<String, dynamic> importData = await Api.get('v1/repairman');

    Batch batch = App.application.data.db.batch();
    await Component.import(importData['components'], batch);
    await ComponentGroup.import(importData['component_groups'], batch);
    await Defect.import(importData['defects'], batch);
    await Repair.import(importData['repairs'], batch);
    await Terminal.import(importData['terminals'], batch);
    await TerminalComponentLink.import(importData['terminal_component_links'], batch);
    await TerminalImage.import(importData['terminal_images'], batch);
    await TerminalWorktime.import(importData['terminal_worktimes'], batch);
    await Task.import(importData['tasks'], batch);
    await TaskDefectLink.import(importData['task_defect_links'], batch);
    await TaskRepairLink.import(importData['task_repair_links'], batch);
    await batch.commit();
  }

  Future<Map<String, dynamic>> _dataForExport() async {
    return {
      'tasks': await Task.export(),
      'terminal_component_links': await TerminalComponentLink.export(),
      'task_defect_links': await TaskDefectLink.export(),
      'task_repair_links': await TaskRepairLink.export(),
    };
  }

  Future<void> _exportData(Map<String, dynamic> exportData) async {
    await Api.post('v1/repairman/save', data: exportData);
  }

  Future<void> syncLocations() async {
    if (_isSyncingGeoPoints) return;

    try {
      _streamController.add(SyncEvent.geoPointsSyncStarted);
      _isSyncingGeoPoints = true;
      await _syncLocations();
    } finally {
      _isSyncingGeoPoints = false;
    }

    _streamController.add(SyncEvent.geoPointsSyncCompleted);
  }

  Future<void> _syncLocations() async {
    List<GeoPoint> geoPoints = await GeoPoint.allNew();

    if (geoPoints.isEmpty) return;

    try {
      await Api.post('v1/repairman/locations', data: {
        'locations': geoPoints.map((req) => req.toExportMap()).toList()
      });

      syncGeoPointsErrors = null;
      await Future.wait(geoPoints.map((geoPoint) async => await geoPoint.markInserted(false)));
    } on ApiException catch(e) {
      syncGeoPointsErrors = e.errorMsg;
      await Future.wait(geoPoints.map((geoPoint) async => await geoPoint.markInserted(true)));
    }
  }

  Future<void> clearData() async {
    await Component.deleteAll();
    await ComponentGroup.deleteAll();
    await Defect.deleteAll();
    await Repair.deleteAll();
    await Terminal.deleteAll();
    await TerminalComponentLink.deleteAll();
    await TerminalImage.deleteAll();
    await TerminalImageTemp.deleteAll();
    await TerminalWorktime.deleteAll();
    await Task.deleteAll();
    await TaskDefectLink.deleteAll();
    await TaskRepairLink.deleteAll();
    await setLastDataSyncTime(null);
  }
}
