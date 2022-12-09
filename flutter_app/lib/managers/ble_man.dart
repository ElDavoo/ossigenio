/*
Class that manages the connection to a BLE device.
 */
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../utils/serial.dart';
import 'package:flutter_blue/flutter_blue.dart';

class BLEManager extends ChangeNotifier {
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
  ];

  // List of allowed names
  static const List<String> allowedNames = [
    'Adafruit Bluefruit LE',
  ];

  BluetoothCharacteristic? uartRX;

  static const nordicUARTID = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const nordicUARTRXID = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const nordicUARTTXID = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';
  SerialComm? serial;

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
    StreamSubscription scanSubscription = flutterBlue.scanResults.listen((
        results) {
      // Do something with scan results
      for (ScanResult r in results) {
        processResult(r.device);
      }
    });
    print("Scanning...");
  }

  // Method to stop scanning for BLE devices
  void stopBLEScan() async {
    if (!_isScanning) {
      return;
    }
    // Stop scanning
    flutterBlue.stopScan();
    print("Scanning stopped");
    _isScanning = false;
  }

  void processResult(BluetoothDevice device) {
    // Filter out devices that are already in the list
    if (devices.contains(device)) {
      return;
    }
    // Only filter BLE devices
    /*if (device.type != BluetoothDeviceType.le) {
      // Add the device to the list
      return;
    }
    //Only devices with allowed OUIs
    if (!allowedOUIs.contains(device.id.id.substring(0, 8))) {
      return;
    }
    // Only devices with allowed names
    if (!allowedNames.contains(device.name)) {
      return;
    }*/
    print("Found device: ${device.toString()}");
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

  // Gets the list as a ListView
  ListView getDevicesAsListView() {
    List<String> devicesString = getDevicesToString();
    return ListView.builder(
      itemCount: devicesString.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(devicesString[index]),
          onTap: () {
            print("Tapped ${devicesString[index]}");
            // Connect to the device
            //connectToDevice(devices[index]);
          },
        );
      },
    );
  }

  // Connect to a BLE device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    // Connect to the device with a timeout of 2 seconds
    try {
    await device.connect().timeout(const Duration(seconds: 2));
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print("Timeout!");
      }
      return false;
    } on Exception catch (e) {
      if (kDebugMode) {
        print("Error connecting to device: $e");
      }
      return false;
    }

    // Discover services
    List<BluetoothService> services = await device.discoverServices();

    // Check if Nordic UART Service is present
    for (var service in services) {
      if (service.uuid.toString() == nordicUARTID) {
        if (kDebugMode) {
          print("Found Nordic UART Service");
        }

        // Get the characteristics
        List<BluetoothCharacteristic> characteristics = service.characteristics;

        // Check if Nordic UART RX characteristic is present

        for (var characteristic in characteristics) {
          if (characteristic.uuid.toString() == nordicUARTRXID) {
            if (kDebugMode) {
              print("Found Nordic UART RX characteristic");
            }

            // Save the characteristic into the class
            uartRX = characteristic;
            serial = SerialComm(uartRX!);
          }
        }
        if (serial == null) {
          return false;
        }


        for (var characteristic in characteristics) {
          if (characteristic.uuid.toString() == nordicUARTTXID) {
            if (kDebugMode) {
              print("Found Nordic UART TX characteristic");
            }

            // Subscribe to the TX characteristic
            characteristic.setNotifyValue(true);

            // Listen to the TX characteristic
            characteristic.value.listen((value) {
              // Do something with the value
              serial!.receive(value);
            });
            return true;
          }
        }
      }
    }
    return false;
  }
}