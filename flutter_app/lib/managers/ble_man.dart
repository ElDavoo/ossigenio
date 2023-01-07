import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/managers/perm_man.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../utils/serial.dart';
import '../utils/constants.dart';
import '../utils/device.dart';
import '../utils/log.dart';
import '../utils/mac.dart';



class BTUart {
  late BluetoothCharacteristic rxCharacteristic;
  late BluetoothCharacteristic txCharacteristic;

  BTUart(this.rxCharacteristic, this.txCharacteristic);
}

class BLEManager extends ChangeNotifier {
  static final BLEManager _instance = BLEManager._internal();

  factory BLEManager() {
    return _instance;
  }

  BLEManager._internal() {
    Log.v("BLEManager initializing...");
    flutterBlue.isScanning.listen((isScanning) {
      _isScanning = isScanning;
    });
    flutterBlue.state.listen((event) {});
    // When we receive a scan result, we try to connect to it
    scanstream.stream.listen((event) {
      Log.v("Scan result received, trying to connect...");
      connectToDevice(event).catchError((e) {
        Log.l("Error connecting to device: $e");
        event.device.disconnect();
        disconnectstream.add(null);
      });
    });
    // When we receive a disconnection event, we start scanning again
    disconnectstream.stream.listen((event) {
      dvc = null;
      Log.v("Disconnected from device, starting scan again");
      startBLEScan();
    });
    // Add a disconnession event to kickstart the scan
    // disconnectstream.add(null);

    Log.v("BLEManager initialized");
  }

  // Instance of flutter_blue
  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  // State of BT radio
  Stream<BluetoothState> get state => flutterBlue.state;

  bool _isScanning = false;

  // Stream of device connected
  StreamController<Device> devicestream = StreamController<Device>.broadcast();

  // Stream of disconnection events
  StreamController<void> disconnectstream = StreamController<void>.broadcast();

  // Stream of ScanResults (devices found)
  StreamController<ScanResult> scanstream =
      StreamController<ScanResult>.broadcast();

  // Last device connected
  Device? dvc;

  // Method to scan for BLE devices
  void startBLEScan() async {
    if (_isScanning) {
      // Wait for the scan to finish
      await flutterBlue.stopScan();
    }
    bool hasPermissions = await PermissionManager().checkPermissions();
    if (hasPermissions) {
      // Start scanning
      flutterBlue.startScan();
      // Listen for devices
      List<ScanResult> btdevice = await flutterBlue.scanResults
          .map((results) {
            List<ScanResult> list = [];
            for (ScanResult r in results) {
              // Filter weak devices
              if (r.rssi < -80) {
                continue;
              }
              if (r.device.type != BluetoothDeviceType.le &&
                  r.device.type != BluetoothDeviceType.dual) {
                continue;
              }
              if (!C.bt.allowedNames.contains(r.device.name)) {
                continue;
              }
              MacAddress? mac = processAdv(r.advertisementData);
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
      // Stop scanning
      flutterBlue.stopScan();
      // Sort by rssi
      btdevice.sort((a, b) => b.rssi.compareTo(a.rssi));
      // Add the first device to the stream and return
      scanstream.add(btdevice.first);
      return;
    } else {
      Log.v("Permissions not granted");
      return Future.error('Permissions not granted');
    }
  }

  // Method to stop scanning for BLE devices
  void stopBLEScan() async {
    if (!_isScanning) {
      return;
    }
    // Stop scanning
    await flutterBlue.stopScan();
    Log.v("Scanning stopped");
  }

  // Connect to a BLE device
  Future<void> connectToDevice(ScanResult result) async {
    stopBLEScan();
    // Connect to the device with a timeout of 3 seconds
    try {
      await result.device.connect().timeout(const Duration(seconds: 3));
    } on TimeoutException {
      Log.v("Timeout!");
      rethrow;
    } on PlatformException catch (e) {
      if (e.code == 'already_connected') {
        dvc = Device(result, await getUart(result.device));
        devicestream.add(dvc!);
        return;
      }
      rethrow;
    } on Exception catch (e) {
      Log.v("Error connecting to device: $e");
      rethrow;
    }
    dvc = Device(result, await getUart(result.device));
    devicestream.add(dvc!);
    return;

    // Discover services
    //throw UnimplementedError();
  }

  static Future<BTUart> getUart(BluetoothDevice device) async {
    BTUart? uart;
    // Discover services
    try {
      await device.discoverServices().then((value) {
        try {
          List<BluetoothCharacteristic> uartCharacteristics = value
              .firstWhere(
                  (service) => service.uuid.toString() == C.bt.nordicUARTID)
              .characteristics;
          BluetoothCharacteristic rxCharacteristic =
              uartCharacteristics.firstWhere((characteristic) =>
                  characteristic.uuid.toString() == C.bt.nordicUARTRXID);
          BluetoothCharacteristic txCharacteristic =
              uartCharacteristics.firstWhere((characteristic) =>
                  characteristic.uuid.toString() == C.bt.nordicUARTTXID);

          uart = BTUart(rxCharacteristic, txCharacteristic);
          txCharacteristic.setNotifyValue(true);

          return uart;
        } catch (e) {
          Log.v("Error discovering services: $e");
          rethrow;
        }
      }).catchError((error) {
        Log.v("Error discovering services: $error");
        throw error;
      });
    } catch (e) {
      Log.v("Error connecting to device: $e");
      rethrow;
    }
    // ????????
    if (uart == null) {
      Log.v("Error discovering services");
      throw Exception("Error discovering services");
    } else {
      return uart!;
    }
  }

  void disconnect(Device device) {
    device.device.disconnect();
    dvc = null;
    disconnectstream.add(null);
  }

  static void send(Device device, Uint8List data) {
    if (device.state == BluetoothDeviceState.connected) {
      device.btUart.rxCharacteristic.write(data).catchError((error) {
        Log.v("Error sending data: $error");
      });
    } else {
      Log.v("Device not connected");
    }
  }

  static void sendMsg(Device device, int msgIndex) {
    send(device, SerialComm.buildMsgg(msgIndex));
  }

  static MacAddress? processAdv(AdvertisementData advertisementData) {
    // Check if manufacturer data is present
    if (advertisementData.manufacturerData.isEmpty) {
      return null;
    }
    // Check if manufacturer ID is 0xF075 ( the key of the map)
    if (!advertisementData.manufacturerData
        .containsKey(C.bt.manufacturerId)) {
      return null;
    }
    // The manufacturer data is the mac address of length 6
    if (advertisementData.manufacturerData[C.bt.manufacturerId]!.length !=
        6) {
      return null;
    }
    Uint8List mac = Uint8List.fromList(
        advertisementData.manufacturerData[C.bt.manufacturerId]!);
    Uint8List oui = mac.sublist(0, 3);
    // Check if mac is of allowed vendors
    for (Uint8List allowedOui in C.bt.allowedOUIs) {
      if (listEquals(oui, allowedOui)) {
        return MacAddress(mac);
      }
    }

    return null;
  }

  static Stream<int> rssiStream(Device device) async* {
    for (;;) {
      yield await device.device.readRssi();
      await Future.delayed(const Duration(seconds: 2));
    }
  }
}
