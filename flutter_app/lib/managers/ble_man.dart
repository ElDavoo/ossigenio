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

  BLEManager._internal();

  // Instance of flutter_blue
  FlutterBlue flutterBlue = FlutterBlue.instance;

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
  ];

  BluetoothCharacteristic? uartRX;

  static const nordicUARTID = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const nordicUARTRXID = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const nordicUARTTXID = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  BluetoothDevice? device;
  List<MessageWithDirection> messages = [];

  Stream<MessageWithDirection>? messagesStream;

  //Singleton class
  // Method to scan for BLE devices
  void startBLEScan() async {
    if (_isScanning) {
      return;
    }
    _isScanning = true;
    // Start scanning
    // Clear out the list of devices
    devices.clear();
    scanFuture = flutterBlue.startScan();
    // Listen for devices
    StreamSubscription scanSubscription =
        flutterBlue.scanResults.listen((results) {
      // Do something with scan results
      for (ScanResult r in results) {
        processResult(r.device);
      }
    });
    Log.l("Scanning...");
  }

  // Method to stop scanning for BLE devices
  void stopBLEScan() async {
    if (!_isScanning) {
      return;
    }
    // Stop scanning
    flutterBlue.stopScan();
    Log.l("Scanning stopped");

    _isScanning = false;
  }

  void processResult(BluetoothDevice device) {
    // Filter out devices that are already in the list
    if (devices.contains(device)) {
      return;
    }
    // Only filter BLE devices
    if (device.type != BluetoothDeviceType.le) {
      // Add the device to the list
      return;
    }
    //Only devices with allowed OUIs
    /*if (!allowedOUIs.contains(device.id.id.substring(0, 8))) {
      return;
    }*/
    // Only devices with allowed names
    if (!allowedNames.contains(device.name)) {
      return;
    }
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

  List<BluetoothDevice> getDevices() {
    return devices;
  }

  List<String> getDevicesToString() {
    List<String> devicesString = [];
    for (BluetoothDevice device in devices) {
      devicesString.add(device.toString());
    }
    return devicesString;
  }

  // Connect to a BLE device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    // Connect to the device with a timeout of 2 seconds
    try {
      await device.connect().timeout(const Duration(seconds: 3));
    } on TimeoutException {
      Log.l("Timeout!");

      return false;
    } on PlatformException catch (e) {
      if (e.code == 'already_connected') return true;
      return false;
    } on Exception catch (e) {
      Log.l("Error connecting to device: $e");
      return false;
    }

    // Discover services
    List<BluetoothService> services = await device.discoverServices();

    // Check if Nordic UART Service is present
    for (var service in services) {
      if (service.uuid.toString() == nordicUARTID) {
        Log.l("Found Nordic UART Service");

        // Get the characteristics
        List<BluetoothCharacteristic> characteristics = service.characteristics;

        // Check if Nordic UART RX characteristic is present

        for (var characteristic in characteristics) {
          if (characteristic.uuid.toString() == nordicUARTRXID) {
            Log.l("Found Nordic UART RX characteristic");

            // Save the characteristic into the class
            uartRX = characteristic;
          }
        }

        for (var characteristic in characteristics) {
          if (characteristic.uuid.toString() == nordicUARTTXID) {
            Log.l("Found Nordic UART TX characteristic");

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
            Log.l("mac address:${device.id.id}");
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
}
