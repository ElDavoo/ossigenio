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

  BLEManager._internal(){
    flutterBlue.isScanning.listen((isScanning) {
      _isScanning = isScanning;
    });
    flutterBlue.state.listen((event) {
      _state = event;
    });
  }

  // Instance of flutter_blue
  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  // State of BT radio
  Stream<BluetoothState> get state => flutterBlue.state;
  BluetoothState _state = BluetoothState.unknown;

  bool _isScanning = false;


  // Method to scan for BLE devices
  Future<Device> startBLEScan() async {
    Device? device;
    if (_isScanning) {
      return Future.error('Already scanning');
    }
    bool hasPermissions = await PermissionManager().checkPermissions();
    if (hasPermissions) {

      // Start scanning
      flutterBlue.startScan();
      // Listen for devices
      StreamSubscription? scansub;
      List<ScanResult> btdevice = await flutterBlue.scanResults.map((results) {
        List<ScanResult> list = [];
        for (ScanResult r in results) {
          if (r.device.type != BluetoothDeviceType.le) {
            continue;
          }
          if (!BTConst.allowedNames.contains(r.device.name)) {
            continue;
          }
          //TODO
          if (!processAdv(r.advertisementData)) {
            continue;
          }
          // Filter weak devices
          if (r.rssi < -80) {
            continue;
          }
          // Filter devices
          list.add(r);
        }
        return list;
      }).where((results) => results.isNotEmpty).first;
      // Stop scanning
      flutterBlue.stopScan();
      // Sort by rssi
      btdevice.sort((a, b) => b.rssi.compareTo(a.rssi));
      // Connect to the first device
      return await connectToDevice(btdevice.first.device);

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
  Future<Device> connectToDevice(BluetoothDevice device) async {
    stopBLEScan();
    // Connect to the device with a timeout of 3 seconds
    try {
      await device.connect().timeout(const Duration(seconds: 3));
    } on TimeoutException {
      Log.v("Timeout!");
      rethrow;
    } on PlatformException catch (e) {
      if (e.code == 'already_connected') return Device(device, await getUart(device));
      rethrow;
    } on Exception catch (e) {
      Log.v("Error connecting to device: $e");
      rethrow;
    }

    return Device(device, await getUart(device));

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
              .firstWhere((service) => service.uuid.toString() == BTConst.nordicUARTID)
              .characteristics;
          BluetoothCharacteristic rxCharacteristic = uartCharacteristics
              .firstWhere((characteristic) =>
          characteristic.uuid.toString() ==
              BTConst.nordicUARTRXID);
          BluetoothCharacteristic txCharacteristic = uartCharacteristics
              .firstWhere((characteristic) =>
          characteristic.uuid.toString() ==
              BTConst.nordicUARTTXID);

          uart =  BTUart(rxCharacteristic, txCharacteristic);
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

  static Future disconnect(Device device) {
    return device.device.disconnect();
  }

  static void send(Device device, Uint8List data) {
    if (device.state == BluetoothDeviceState.connected) {
      device.btUart.txCharacteristic.write(data);
    } else {
      Log.v("Device not connected");
    }
  }

  static void sendMsg(Device device, int msgIndex){
    send(device, SerialComm.buildMsgg(msgIndex));
  }

  static bool processAdv(AdvertisementData advertisementData) {
    // Check if Nordic UART Service is present
    for (var service in advertisementData.serviceUuids) {
      if (service.toString() == BTConst.nordicUARTID) {
        Log.v("Found Nordic UART Service");
        return true;
      }
    }
    return false;
  }


  static Stream<int> rssiStream(Device device) async* {
    for (;;) {
      yield await device.device.readRssi();
      await Future.delayed(const Duration(seconds: 1));
    }

  }
}


