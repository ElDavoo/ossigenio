/*
Class that manages the connection to a BLE device.
 */
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/managers/perm_man.dart';
import '../../utils/serial.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../utils/device.dart';
import '../utils/log.dart';

class BTConst {
  // List of allowed names
  static const List<String> allowedNames = [
    'Adafruit Bluefruit LE',
    'AirQualityMonitor',
    'AirQualityMonitorEBV',
  ];

  static const nordicUARTID = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const nordicUARTRXID = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const nordicUARTTXID = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  // List of allowed OUIs
  List<Uint8List> allowedOUIs = [
    Uint8List.fromList([0xEF, 0x41, 0xB7]),
    Uint8List.fromList([0xE6, 0x4A, 0x29]),
    Uint8List.fromList([0xC4, 0x4F, 0x33]),
  ];

  static int manufacturerId = 0xF175;
}

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
    flutterBlue.state.listen((event) {
      _state = event;
    });
    // When we receive a scan result, we try to connect to it
    scanstream.stream.listen((event) {
      _scanResult = event;
      Log.v("Scan result received, trying to connect...");
      connectToDevice(event);
    });
    // When we receive a disconnection event, we start scanning again
    disconnectstream.stream.listen((event) {
      _scanResult = null;
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
  BluetoothState _state = BluetoothState.unknown;

  bool _isScanning = false;

  // Stream of device connected
  StreamController<Device> devicestream = StreamController<Device>.broadcast();
  // Stream of disconnection events
  StreamController<void> disconnectstream = StreamController<void>.broadcast();
  // Stream of ScanResults (devices found)
  StreamController<ScanResult> scanstream = StreamController<ScanResult>.broadcast();
  // Last device connected
  Device? dvc;
  // Last scan result
  ScanResult? _scanResult;

  // Method to scan for BLE devices
  void startBLEScan() async {
    Device? device;
    if (_isScanning) {
      // Wait for the scan to finish
      await flutterBlue.stopScan();
    }
    bool hasPermissions = await PermissionManager().checkPermissions();
    if (hasPermissions) {
      // Start scanning
      flutterBlue.startScan();
      // Listen for devices
      StreamSubscription? scansub;
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
              if (!BTConst.allowedNames.contains(r.device.name)) {
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

      Log.v("Scanning...");
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
  void connectToDevice(ScanResult result) async {
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
                  (service) => service.uuid.toString() == BTConst.nordicUARTID)
              .characteristics;
          BluetoothCharacteristic rxCharacteristic =
              uartCharacteristics.firstWhere((characteristic) =>
                  characteristic.uuid.toString() == BTConst.nordicUARTRXID);
          BluetoothCharacteristic txCharacteristic =
              uartCharacteristics.firstWhere((characteristic) =>
                  characteristic.uuid.toString() == BTConst.nordicUARTTXID);

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
    _scanResult = null;
    disconnectstream.add(null);
  }

  static void send(Device device, Uint8List data) {
    if (device.state == BluetoothDeviceState.connected) {
      device.btUart.rxCharacteristic.write(data);
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
    if (!advertisementData.manufacturerData.containsKey(BTConst.manufacturerId)) {
      return null;
    }
    // The manufacturer data is the mac address of length 6
    if (advertisementData.manufacturerData[BTConst.manufacturerId]!.length != 6) {
      return null;
    }
    Uint8List mac = Uint8List.fromList(advertisementData.manufacturerData[BTConst.manufacturerId]!);
    Uint8List oui = mac.sublist(0, 3);
    // Check if mac is of allowed vendors
    for (Uint8List allowedOui in BTConst().allowedOUIs) {
      if (listEquals(oui, allowedOui)) {
        return MacAddress(mac);
      }
    }

    return null;
  }

  static Stream<int> rssiStream(Device device) async* {
    for (;;) {
      yield await device.device.readRssi();
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
