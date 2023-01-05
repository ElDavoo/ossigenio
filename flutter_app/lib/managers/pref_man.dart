/*
Preferences manager that uses the secure storage to store the preferences
 */

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/log.dart';

class PrefConstants {
  static const String deviceMac = "deviceMac";
  static const String email = "email";
  static const String username = "username";
  static const String dataVersion = "dataVersion";
  static const String mqttUsername = "mqttUsername";
  static const String mqttPassword = "mqttPassword";
  static const String cookie = "cookie";
  static int dataVersionValue = 0;
}

class PrefManager {
  static final PrefManager _instance = PrefManager._internal();
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  factory PrefManager() {
    return _instance;
  }

  PrefManager._internal(){
    migrate();
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  void write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<void> delete(String key) async {
    // Set the value to null first
    await _storage.write(key: key, value: null);
    // Then delete the key
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  void saveAccountData(String username, String email) {
    write(PrefConstants.username, username);
    // no need to encrypt the password, we are in encrypted storage
    // TODO save token instead of password
    write(PrefConstants.email, email);
  }

  void saveMqttData(String username, String password) {
    write(PrefConstants.mqttUsername, username);
    // no need to encrypt the password, we are in encrypted storage
    write(PrefConstants.mqttPassword, password);
  }

  Future<bool> areMqttDataSaved() async {
    if (await read(PrefConstants.mqttUsername) != null &&
        await read(PrefConstants.mqttPassword) != null) {
      return true;
    }
    return false;
  }

  // Migrates the preferences from the old storage to the new one.
  Future<void> migrate() async {
    // Read the old  storage version
    String ?oldVersions = await read(PrefConstants.dataVersion);
    if (oldVersions == null) {
      // No old version, nothing to migrate
      return;
    }
    int currentVersion = int.parse(oldVersions);
    switch (currentVersion) {
      case 0:
        // example: rename a key
      default:
        Log.v("Migrate: unknown version $currentVersion");
    }
  }
}
