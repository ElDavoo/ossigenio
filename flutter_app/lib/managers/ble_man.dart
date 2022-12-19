/*
Class that manages the connection to a BLE device.
 */
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/managers/perm_man.dart';
import 'package:flutter_app/managers/pref_man.dart';
import '../../utils/serial.dart';
import 'package:flutter_blue/flutter_blue.dart';

import '../Messages/message.dart';
import '../utils/device.dart';
import '../utils/log.dart';

class BTUart {
  late BluetoothCharacteristic _rxCharacteristic;
  late BluetoothCharacteristic _txCharacteristic;

  BTUart(this._rxCharacteristic, this._txCharacteristic);
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
  }

  // Instance of flutter_blue
  final FlutterBlue flutterBlue = FlutterBlue.instance;



  // List of devices found
  List<BluetoothDevice> devices = [];

  // Future of scanning
  late Future<void> scanFuture;
  bool _isScanning = false;
  bool _isConnecting = false;



  // List of allowed OUIs
  static const List<String> allowedOUIs = [
    'EF:41:B7',
    'E6:4A:29',
  ];

  // List of allowed names
  static const List<String> allowedNames = [
    'Adafruit Bluefruit LE',
    'AirQualityMonitor',
    'AirQualityMonitorEBV',
  ];

  static const nordicUARTID = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const nordicUARTRXID = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const nordicUARTTXID = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  Device ?device;
  List<MessageWithDirection> messages = [];

  Stream<MessageWithDirection>? messagesStream;

  // Method to scan for BLE devices
  void startBLEScan() async {
    if (_isScanning) {
      return;
    }
    PermissionManager().checkPermissions().then((value) {
      if (value) {
        // Clear out the list of devices
        devices.clear();
        // Start scanning
        scanFuture = flutterBlue.startScan();
        // Listen for devices
        StreamSubscription? scansub;
        scansub = flutterBlue.scanResults
            .map((results) {
          List<ScanResult> list = [];
          for (ScanResult r in results) {
            if (r.device.type != BluetoothDeviceType.le) {
              continue;
            }
            if (!allowedNames.contains(r.device.name)) {
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
        }).where((results) => results.isNotEmpty)
            .listen((results) {
              stopBLEScan();
              scansub?.cancel();
          if (results.length > 1) {
            Log.v("TODO: Handle multiple devices");
            results.sort((a, b) => b.rssi.compareTo(a.rssi));
          }
          connectToDevice(results[0].device).then((value) {
            device = value;
            notifyListeners();
          });
        });
        Log.v("Scanning...");
      }
    });


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

  void processResult(BluetoothDevice device) {
    // If the device is the one registered in the preferences, connect to it
    PrefManager().read(PrefConstants.deviceMac)
        .then((value) => {
          //if (value == device.id.id)
          //connectToDevice(device)
          });

    // Add the device to the list
    devices.add(device);

  }

  Stream<bool> isScanning() {
    return flutterBlue.isScanning;
  }

  // Connect to a BLE device
  Future<Device> connectToDevice(BluetoothDevice device) async {
    stopBLEScan();
    if (_isConnecting) {
      return Future.error("Already connecting");
    }
    _isConnecting = true;
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

  Future<BTUart> getUart(BluetoothDevice device) async {
    BTUart? uart;
    // Discover services
    try {
      await device.discoverServices().then((value) {
        try {
          List<BluetoothCharacteristic> uartCharacteristics = value
              .firstWhere((service) => service.uuid.toString() == nordicUARTID)
              .characteristics;
          BluetoothCharacteristic rxCharacteristic = uartCharacteristics
              .firstWhere((characteristic) =>
          characteristic.uuid.toString() ==
              nordicUARTRXID);
          BluetoothCharacteristic txCharacteristic = uartCharacteristics
              .firstWhere((characteristic) =>
          characteristic.uuid.toString() ==
              nordicUARTTXID);

          uart =  BTUart(rxCharacteristic, txCharacteristic);
          txCharacteristic.setNotifyValue(true);
          messagesStream = txCharacteristic.value
              .map((value) {
            Message? message = SerialComm.receive(value);
            if (message != null) {
              return MessageWithDirection(
                  MessageDirection.received, DateTime.now(), message);
            }
            return null;
          })
              .where((message) => message != null)
              .cast<MessageWithDirection>()
              .asBroadcastStream();
          messagesStream!.listen((message) {
            messages.add(message);
            notifyListeners();
          });

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

  void disconnect() {
    if (device != null) {
      device!.device.disconnect();
    }
  }
  void send(Uint8List data) {
    if (device?.btUart._rxCharacteristic != null) {
      device!.btUart._rxCharacteristic.write(data);
    } else {
      Log.v("UART RX characteristic not found");
    }
  }

  void sendMsg(int msgIndex){
    send(SerialComm.buildMsgg(msgIndex));
  }

  bool processAdv(AdvertisementData advertisementData) {
    // Check if Nordic UART Service is present
    for (var service in advertisementData.serviceUuids) {
      if (service.toString() == nordicUARTID) {
        Log.v("Found Nordic UART Service");
        return true;
      }
    }
    return false;
  }
}
