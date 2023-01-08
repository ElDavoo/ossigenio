import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/managers/perm_man.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../utils/serial.dart';
import '../utils/btuart.dart';
import '../utils/constants.dart';
import '../utils/device.dart';
import '../utils/log.dart';
import '../utils/mac.dart';

class BLEManager extends ChangeNotifier {
  static final BLEManager _instance = BLEManager._internal();

  factory BLEManager() {
    return _instance;
  }

  /// Istanza di flutter_blue_plus
  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;

  /// Indica se si sta cercando un dispositivo
  bool _isScanning = false;

  /// Uno stream di potenziali sensori
  final StreamController<ScanResult> _scanstream =
      StreamController<ScanResult>();

  /// Il dispositivo a cui siamo connessi
  ValueNotifier<Device?> dvc = ValueNotifier<Device?>(null);

  BLEManager._internal() {
    Log.d("Initializing");
    _flutterBlue.isScanning.listen((isScanning) {
      _isScanning = isScanning;
    });
    // Quando troviamo un risultato, proviamo a connetterci
    _scanstream.stream.listen((event) {
      Log.d("Scan result received, trying to connect...");
      connectToDevice(event).catchError((e) {
        Log.l("Errore durante la connessione: $e");
        event.device.disconnect();
        startBLEScan();
      });
    });
    Log.d("Inizializzato");
    startBLEScan();
  }

  /// Inizia la scansione dei dispositivi.
  ///
  /// Questo metodo inizia a cercare dispositivi a cui connettersi.
  /// Quando lo trova, lo aggiunge allo stream [_scanstream].
  Future<void> startBLEScan() async {
    if (_isScanning) {
      await _flutterBlue.stopScan();
    }

    Log.d("Scansione");

    final bool hasPermissions = await PermissionManager().checkPermissions();

    if (!hasPermissions) {
      return Future.error("Permessi non concessi");
    }

    _flutterBlue.startScan();

    List<ScanResult> btdevice = await _flutterBlue.scanResults
        .map((results) {
          List<ScanResult> list = [];

          for (ScanResult r in results) {
            // Filtra dispositivi che prendono poco
            if (r.rssi < -80) {
              continue;
            }

            // Filtra dispositivi che non hanno il BLE
            if (r.device.type != BluetoothDeviceType.le &&
                r.device.type != BluetoothDeviceType.dual) {
              continue;
            }

            // Filtra dispositivi che non hanno il nome giusto
            if (!C.bt.allowedNames.contains(r.device.name)) {
              continue;
            }

            // Controlla gli advertisementData
            final MacAddress? mac = processAdv(r.advertisementData);
            if (mac == null) {
              continue;
            }

            // Filter devices
            list.add(r);
          }
          return list;
        })
        .where((results) => results.isNotEmpty)
        .first;

    _flutterBlue.stopScan();

    // Nel caso molto raro in cui c'è più di un sensore,
    // prendiamo quello che prende di più
    btdevice.sort((a, b) => b.rssi.compareTo(a.rssi));
    _scanstream.add(btdevice.first);

    return;
  }

  /// Ferma immediatamente la scansione dei dispositivi.
  void stopBLEScan() async {
    if (!_isScanning) {
      return;
    }
    // Stop scanning
    await _flutterBlue.stopScan();
    Log.d("Scansione fermata");
  }

  /// Prova a connettersi a un dispositivo.
  ///
  /// Questo metodo cerca di connettersi al dispositivo.
  /// Lo aggiunge allo stream [devicestream] se la connessione è andata a buon fine.
  Future<void> connectToDevice(ScanResult result) async {
    stopBLEScan();

    try {
      await result.device.connect().timeout(const Duration(seconds: 3));
    } on TimeoutException {
      // Questo accade anche quando si disconnette un dispositivo.
      // Quando si ricomincia la scansione, il dispositivo disconnesso
      // viene rilevato un'altra volta.
      Log.d("Timeout!");
      rethrow;
    } on PlatformException catch (e) {
      // Se per qualche ragione siamo già connessi al dispositivo,
      // costruire il Device e aggiungerlo allo stream.

      if (e.code == 'already_connected') {
        dvc.value = Device(result, await BTUart.fromDevice(result.device));
        return;
      }

      rethrow;
    } on Exception catch (e) {
      Log.l("Errore durante la connessione: $e");
      rethrow;
    }

    dvc.value = Device(result, await BTUart.fromDevice(result.device));
    return;
  }



  /// Si disconnette dal dispositivo.
  void disconnect(Device device) {
    device.device.disconnect();
    dvc.value = null;
    startBLEScan();
  }

  /// Invia dati grezzi a un dispositivo.
  static void send(Device device, Uint8List data) {
    if (device.state == BluetoothDeviceState.connected) {
      device.btUart.rxCharacteristic.write(data).catchError((error) {
        Log.v("Error sending data: $error");
      });
    } else {
      Log.v("Device not connected");
    }
  }

  /// Invia un messaggio a un dispositivo.
  static void sendMsg(Device device, int msgIndex) {
    send(device, SerialComm.buildMsg(msgIndex));
  }

  /// Restituisce il mac address del dispositivo, o null.
  ///
  /// Questo metodo controlla se l'advertisementData,
  /// mandato dal dispositivo nei pacchetti di advertising,
  /// contiene i dati giusti e specifici per distinguere
  /// i nostri dispositivi da quelli di altri.
  static MacAddress? processAdv(AdvertisementData advertisementData) {
    if (advertisementData.manufacturerData.isEmpty) {
      return null;
    }

    // Controlla se il manufacturer data key è quello giusto
    if (!advertisementData.manufacturerData.containsKey(C.bt.manufacturerId)) {
      return null;
    }

    final Uint8List macList = Uint8List.fromList(
        advertisementData.manufacturerData[C.bt.manufacturerId]!);

    try {
      return MacAddress(macList);
    } catch (e) {
      return null;
    }
  }

  /// Legge l'RSSI del dispositivo ogni 2 secondi.
  ///
  /// Restituisce uno [Stream] che emette un [int] ogni 2 secondi.
  static Stream<int> rssiStream(Device device) async* {
    for (;;) {
      yield await device.device.readRssi();
      await Future.delayed(const Duration(seconds: 2));
    }
  }
}
