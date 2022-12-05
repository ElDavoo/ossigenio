/*
Class that manages the connection to a BLE device.
 */
import 'dart:async';
import 'package:flutter_blue/flutter_blue.dart';
import 'main.dart';

class BLEManager {
  // Instance of flutter_blue
  FlutterBlue flutterBlue = FlutterBlue.instance;
  // List of devices found
  List<BluetoothDevice> devices = [];
  // Future of scanning
  late Future<void> scanFuture;
  bool _isScanning = false;

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
    StreamSubscription scanSubscription = flutterBlue.scanResults.listen((results) {
      // Do something with scan results
      for (ScanResult r in results) {
        filterOrAdd(r.device);
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
  void filterOrAdd(BluetoothDevice device) {
    // Filter out devices that are already in the list
    if (devices.contains(device)) {
      return;
    }
    print("Found device: ${device.toString()}");
    // Add the device to the list
    devices.add(device);
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
}