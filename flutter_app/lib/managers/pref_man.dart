/*
Preferences manager that uses the secure storage to store the preferences
 */

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/constants.dart';
import '../utils/log.dart';



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
    write(C.pref.username, username);
    // no need to encrypt the password, we are in encrypted storage
    // TODO save token instead of password
    write(C.pref.email, email);
  }

  void saveMqttData(String username, String password) {
    write(C.pref.mqttUsername, username);
    // no need to encrypt the password, we are in encrypted storage
    write(C.pref.mqttPassword, password);
  }

  Future<bool> areMqttDataSaved() async {
    if (await read(C.pref.mqttUsername) != null &&
        await read(C.pref.mqttPassword) != null) {
      return true;
    }
    return false;
  }

  // Migrates the preferences from the old storage to the new one.
  Future<void> migrate() async {
    // Read the old  storage version
    String ?oldVersions = await read(C.pref.dataVersion);
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
