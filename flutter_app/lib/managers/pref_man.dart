/*
Preferences manager that uses the secure storage to store the preferences
 */

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PrefConstants{
  static const String deviceMac = "deviceMac";
}


class PrefManager {
  static final PrefManager _instance = PrefManager._internal();
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  factory PrefManager() {
    return _instance;
  }

  PrefManager._internal();

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  void write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

}

