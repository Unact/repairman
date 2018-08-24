import 'dart:async';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/component.dart';
import 'package:repairman/app/models/component_group.dart';
import 'package:repairman/app/models/defect.dart';
import 'package:repairman/app/models/location.dart';
import 'package:repairman/app/models/repair.dart';
import 'package:repairman/app/models/task.dart';
import 'package:repairman/app/models/task_component.dart';
import 'package:repairman/app/models/task_defect_link.dart';
import 'package:repairman/app/models/task_repair_link.dart';
import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/models/terminal_component_link.dart';
import 'package:repairman/app/models/user.dart';

class DataSync {
  get lastSyncTime {
    String time = App.application.data.prefs.getString('lastSyncTime');
    return time != null ? DateTime.parse(time) : null;
  }
  set lastSyncTime(val) => App.application.data.prefs.setString('lastSyncTime', val.toString());

  Future<void> importData() async {
    Map<String, dynamic> importData = await App.application.api.get('v1/repairman');
    lastSyncTime = DateTime.now();

    await User.import(importData['user']);
    await Component.import(importData['components']);
    await ComponentGroup.import(importData['component_groups']);
    await Defect.import(importData['defects']);
    await Repair.import(importData['repairs']);
    await Task.import(importData['tasks']);
    await TaskComponent.import(importData['task_components']);
    await TaskDefectLink.import(importData['task_defect_link']);
    await TaskRepairLink.import(importData['task_repair_link']);
    await Terminal.import(importData['terminals']);
    await TerminalComponentLink.import(importData['terminal_component_link']);
  }

  Future<void> exportData() async {
    Map<String, dynamic> exportData = {};
    await App.application.api.post('v1/repairman/save', body: exportData);

    lastSyncTime = DateTime.now();
  }

  Future<void> exportLocations() async {
    List<Location> locations = await Location.allNew();
    await App.application.api.post('v1/repairman/locations', body: {
      'locations': locations
    });

    await Future.wait(locations.map((location) {
      location.isNew = false;
      return location.update();
    }));
  }
}
