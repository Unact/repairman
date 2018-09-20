import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/component.dart';
import 'package:repairman/app/models/component_group.dart';
import 'package:repairman/app/models/defect.dart';
import 'package:repairman/app/models/location.dart';
import 'package:repairman/app/models/repair.dart';
import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/task_defect_link.dart';
import 'package:repairman/app/models/task_repair_link.dart';
import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/models/terminal_component_link.dart';
import 'package:repairman/app/models/terminal_worktime.dart';
import 'package:repairman/app/models/user.dart';
import 'package:repairman/app/modules/api.dart';

enum SyncEvent {
  importCompleted,
  exportCompleted,
  locationExportCompleted
}

class DataSync {
  StreamController<SyncEvent> _streamController = StreamController<SyncEvent>();
  Stream<SyncEvent> stream;
  Timer exportSyncTimer;
  String exportSyncErrors;
  Timer importSyncTimer;
  String importSyncErrors;
  String exportLocationErrors;

  static const Duration kSyncTimerPeriod = Duration(minutes: 1);

  DataSync() {
    stream = _streamController.stream.asBroadcastStream();
  }

  DateTime get lastSyncTime {
    String time = App.application.data.prefs.getString('lastSyncTime');
    return time != null ? DateTime.parse(time) : null;
  }
  set lastSyncTime(val) => App.application.data.prefs.setString('lastSyncTime', val.toString());

  void startSyncTimers() {
    startImportSyncTimer();
    startExportSyncTimer();
  }

  void stopSyncTimers() {
    stopImportSyncTimer();
    stopExportSyncTimer();
  }

  void startImportSyncTimer() {
    importSyncTimer = _startTimer(importSyncTimer, _importSyncTimerCallback);
  }

  void stopImportSyncTimer() {
    _stopTimer(importSyncTimer);
  }

  void _importSyncTimerCallback(Timer curTimer) async {
    if (App.application.config.autoRefresh) {
      try {
        await importData();

        importSyncErrors = null;
      } on ApiException catch(e) {
        importSyncErrors = e.errorMsg;
      }
    }
  }

  void startExportSyncTimer() {
    exportSyncTimer = _startTimer(exportSyncTimer, _exportSyncTimerCallback);
  }

  void stopExportSyncTimer() {
    _stopTimer(exportSyncTimer);
  }

  void _exportSyncTimerCallback(Timer curTimer) async {
    Map<String, dynamic> data = await dataForExport();

    if (data.values.any((val) => val.isNotEmpty)) {
      try {
        await exportData(data);
        exportSyncErrors = null;

        await importData();
      } on ApiException catch(e) {
        exportSyncErrors = e.errorMsg;
      }
    }
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

  Future<void> importData() async {
    Map<String, dynamic> importData = await App.application.api.get('v2/repairman');
    lastSyncTime = DateTime.now();

    await User.import(importData['user']);
    await Component.import(importData['components']);
    await ComponentGroup.import(importData['component_groups']);
    await Defect.import(importData['defects']);
    await Repair.import(importData['repairs']);
    await Task.import(importData['tasks']);
    await TaskDefectLink.import(importData['task_defect_links']);
    await TaskRepairLink.import(importData['task_repair_links']);
    await Terminal.import(importData['terminals']);
    await TerminalComponentLink.import(importData['terminal_component_links']);
    await TerminalWorktime.import(importData['terminal_worktimes']);
    _streamController.add(SyncEvent.importCompleted);
  }

  Future<Map<String, dynamic>> dataForExport() async {
    return {
      'tasks': await Task.export(),
      'terminal_component_links': await TerminalComponentLink.export(),
      'task_defect_links': await TaskDefectLink.export(),
      'task_repair_links': await TaskRepairLink.export(),
    };
  }

  Future<void> exportData(Map<String, dynamic> exportData) async {
    await App.application.api.post('v2/repairman/save', body: exportData);
    lastSyncTime = DateTime.now();
    _streamController.add(SyncEvent.exportCompleted);
  }

  Future<void> exportLocations() async {
    List<Location> locations = await Location.allNew();

    try {
      await Future.wait(locations.map((location) async => await location.markInserted(false)));
      await App.application.api.post('v2/repairman/locations', body: {
        'locations': locations.map((req) => req.toExportMap()).toList()
      });
      exportLocationErrors = null;
    } on ApiException catch(e) {
      exportLocationErrors = e.errorMsg;
      await Future.wait(locations.map((location) async => await location.markInserted(true)));
    }

    _streamController.add(SyncEvent.locationExportCompleted);
  }
}
