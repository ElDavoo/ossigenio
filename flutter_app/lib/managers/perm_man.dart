
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/log.dart';

/*
Class to manage and ask for permissions.
TODO: Better handle failed permissions
 */
class PermissionManager {
  bool _hasPermission = false;
  // List of permissions to get
  static const List<Permission> permissions = [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,

  ];
  static const snackBarOk = SnackBar(content: Text('Permessi OK!'));
  static const snackBarFail = SnackBar(content: Text('Please grant permissions'));

// Check if the app has the required permissions
  Future<bool> checkPermissions() async {
    // Check if the app has the required permissions
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    // Check if the app has the required permissions
    _hasPermission = statuses.values.every((status) => status.isGranted);
    // Show SnackBar
    //ScaffoldMessenger.of(context).showSnackBar(snackBar);

      Log.l("Permission status: $_hasPermission");

    return _hasPermission;
  }
}