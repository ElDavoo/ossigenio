
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/*
Class to manage and ask for permissions.
TODO: Better handle failed permissions
 */
class PermissionManager {
  bool _hasPermission = false;
  // List of permissions to get
  static const List<Permission> permissions = [
    Permission.bluetoothScan,
    Permission.bluetoothConnect
  ];
  static const snackBar = SnackBar(content: Text('Please grant permissions'));
// Check if the app has the required permissions
  Future<bool> checkPermissions() async {
    // Check if the app has the required permissions
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    // Check if the app has the required permissions
    if (statuses[Permission.bluetoothScan] == PermissionStatus.granted &&
        statuses[Permission.bluetoothConnect] == PermissionStatus.granted) {
      _hasPermission = true;
    }
    // Show SnackBar
    //ScaffoldMessenger.of(context).showSnackBar(snackBar);
    print("Permission status: $_hasPermission");
    return _hasPermission;
  }
}