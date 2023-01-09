import 'package:flutter/services.dart';
import 'package:flutter_app/utils/constants.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/log.dart';

/// Classe per chiedere i permessi.
/// TODO: Better handle failed permissions
class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();

  factory PermissionManager() {
    return _instance;
  }

  PermissionManager._internal();

  static bool _hasPermission = false;

  /// Controlla se l'app ha i permessi necessari
  Future<bool> checkPermissions() async {
    Map<Permission, PermissionStatus> statuses;
    try {
      statuses = await C.perm.permissions.request();
    } on PlatformException {
      return false;
    }
    _hasPermission = statuses.values.every((status) => status.isGranted);

    Log.d("Permission status: $_hasPermission");

    if (!_hasPermission) {
      Log.l("Permessi non concessi, concedili manualmente");
      return false;
    }

    return _hasPermission;
  }
}
