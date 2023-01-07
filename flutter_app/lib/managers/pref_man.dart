import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/constants.dart';
import '../utils/log.dart';

/// Manager che salva e carica dati dallo storage sicuro
class PrefManager {

  static final PrefManager _instance = PrefManager._internal();
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  factory PrefManager() {
    return _instance;
  }

  PrefManager._internal() {
    _migrate();
  }

  /// Legge un valore dallo storage
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Scrive un valore nello storage
  void write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Cancella un valore dallo storage
  Future<void> delete(String key) async {
    // Lo impostiamo a null prima e poi lo cancelliamo
    await _storage.write(key: key, value: null);
    await _storage.delete(key: key);
  }

  /// Salva username e email nello storage
  void saveAccountData(String username, String email) {
    write(C.pref.username, username);
    write(C.pref.email, email);
  }

  /// Salva le credenziali MQTT nello storage
  void saveMqttData(String username, String password) {
    write(C.pref.mqttUsername, username);
    write(C.pref.mqttPassword, password);
  }

  /// Controlla se le credenziali MQTT sono salvate
  Future<bool> areMqttDataSaved() async {
    if (await read(C.pref.mqttUsername) != null &&
        await read(C.pref.mqttPassword) != null) {
      return true;
    }
    return false;
  }

  /// Migra i dati dal vecchio storage al nuovo
  ///
  /// Questo metodo viene chiamato all'inizializzazione
  /// del manager. Vengono effettuate le migrazioni.
  Future<void> _migrate() async {
    // Legge la vecchia versione
    final String? oldVersions = await read(C.pref.dataVersion);
    if (oldVersions == null) {
      // Siamo al primo avvio, non c'è nulla da migrare
      return;
    }
    final int currentVersion = int.parse(oldVersions);
    switch (currentVersion) {
      case 0:
        break;
      default:
        Log.l("Migrate: unknown version $currentVersion");
    }
  }
}
