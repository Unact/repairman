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
import 'package:repairman/app/models/user.dart';
import 'package:repairman/app/modules/api.dart';

class DataSync {
  Timer syncTimer;
  String exportSyncErrors;
  String exportLocationErrors;

  get lastSyncTime {
    String time = App.application.data.prefs.getString('lastSyncTime');
    return time != null ? DateTime.parse(time) : null;
  }
  set lastSyncTime(val) => App.application.data.prefs.setString('lastSyncTime', val.toString());

  void startSyncTimer() {
    if (syncTimer == null || !syncTimer.isActive) {
      syncTimer = Timer.periodic(Duration(minutes: 1), _syncTimerCallback);
    }
  }

  void stopSyncTimer() {
    if (syncTimer != null && syncTimer.isActive) {
      syncTimer.cancel();
    }
  }

  void _syncTimerCallback(Timer curTimer) async {
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
  }

  Future<void> exportLocations() async {
    List<Location> locations = await Location.allNew();
    try {
      await App.application.api.post('v2/repairman/locations', body: {
        'locations': locations.map((req) => req.toExportMap()).toList()
      });
      exportLocationErrors = null;
    }  on ApiException catch(e) {
      exportLocationErrors = e.errorMsg;
    }

    await Future.wait(locations.map((location) {
      location.localInserted = false;
      return location.update();
    }));
  }
}
