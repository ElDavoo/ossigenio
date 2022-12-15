/*
Class that manages the connection to a BLE device.
 */
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/managers/pref_man.dart';
import '../../utils/serial.dart';
import 'package:flutter_blue/flutter_blue.dart';

import '../Messages/message.dart';
import '../utils/log.dart';

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



  // List of allowed OUIs
  static const List<String> allowedOUIs = [
    'EF:41:B7',
    'E6:4A:29',
  ];

  // List of allowed names
  static const List<String> allowedNames = [
    'Adafruit Bluefruit LE',
    'AirQualityMonitor',
  ];

  BluetoothCharacteristic? uartRX;

  static const nordicUARTID = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const nordicUARTRXID = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const nordicUARTTXID = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  BluetoothDevice? device;
  List<MessageWithDirection> messages = [];

  Stream<MessageWithDirection>? messagesStream;

  // Method to scan for BLE devices
  void startBLEScan() async {
    if (_isScanning) {
      return;
    }
    // Clear out the list of devices
    devices.clear();
    // Start scanning
    scanFuture = flutterBlue.startScan();
    // Listen for devices
    /*StreamSubscription scanSubscription =
        flutterBlue.scanResults.listen((results) {
      // Do something with scan results
      for (ScanResult r in results) {
        processResult(r.device);
      }
    });*/
    flutterBlue.scanResults
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
      // Do something with scan results
      for (ScanResult r in results) {
        processResult(r.device);
      }
    });
    Log.v("Scanning...");
  }

  // Method to stop scanning for BLE devices
  void stopBLEScan() async {
    if (!_isScanning) {
      return;
    }
    // Stop scanning
    flutterBlue.stopScan();
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
    notifyListeners();
  }

  Stream<bool> isScanning() {
    return flutterBlue.isScanning;
  }

  // Connect to a BLE device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    // Connect to the device with a timeout of 2 seconds
    try {
      await device.connect().timeout(const Duration(seconds: 3));
    } on TimeoutException {
      Log.v("Timeout!");

      return false;
    } on PlatformException catch (e) {
      if (e.code == 'already_connected') return true;
      return false;
    } on Exception catch (e) {
      Log.v("Error connecting to device: $e");
      return false;
    }

    // Discover services
    List<BluetoothService> services = await device.discoverServices();

    // Check if Nordic UART Service is present
    for (var service in services) {
      if (service.uuid.toString() == nordicUARTID) {
        Log.v("Found Nordic UART Service");

        // Get the characteristics
        List<BluetoothCharacteristic> characteristics = service.characteristics;

        // Check if Nordic UART RX characteristic is present

        for (var characteristic in characteristics) {
          if (characteristic.uuid.toString() == nordicUARTRXID) {
            Log.v("Found Nordic UART RX characteristic");

            // Save the characteristic into the class
            uartRX = characteristic;
          }
        }

        for (var characteristic in characteristics) {
          if (characteristic.uuid.toString() == nordicUARTTXID) {
            Log.v("Found Nordic UART TX characteristic");

            // Subscribe to the TX characteristic
            characteristic.setNotifyValue(true);

            // Map the stream to a Message object
            messagesStream = characteristic.value
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
            this.device = device;
            // Take the device mac address
            // store the device mac address in shared preferences
            Log.v("mac address:${device.id.id}");
            PrefManager().write(
              PrefConstants.deviceMac,
              device.id.id,
            );
            return true;
          }
        }
      }
    }
    return false;
  }

  void disconnect() {
    if (device != null) {
      device!.disconnect();
    }
  }
  void send(Uint8List data) {
    if (uartRX != null) {
      uartRX!.write(data);
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
