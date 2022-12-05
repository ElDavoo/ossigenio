/*
Class to communicate with the serial port.
 */

import 'package:flutter_blue/flutter_blue.dart';
import 'dart:typed_data';

typedef uint8_t = int;

class SerialComm {

  // Store the FlutterBlue instance.
  FlutterBlue flutterBlue = FlutterBlue.instance;


  // Constructor body
  /*SerialComm(this.device, this.service, this.characteristic, this.descriptor){
// Scan for devices
    FlutterBlue flutterBlue = this.flutterBlue;
    flutterBlue.startScan(timeout: const Duration(seconds: 4));
    // Listen for devices
    StreamSubscription scanSubscription = flutterBlue.scanResults.listen((results) {
      // Do something with scan results
      for (ScanResult r in results) {
        print('${r.device.name} found! rssi: ${r.rssi}');
      }
    });
    // Stop scanning
    flutterBlue.stopScan();
    // Connect to the device
    BluetoothDevice device = await BluetoothDevice.fromId("00:00:00:00:00:00");
    await device.connect();
    // Discover services
    List<BluetoothService> services = await device.discoverServices();
    // Find the UART service
    BluetoothService uartService = services.firstWhere((service) => service.uuid.toString() == "6e400001-b5a3-f393-e0a9-e50e24dcca9e");
    // Find the UART TX characteristic
    BluetoothCharacteristic txCharacteristic = uartService.characteristics.firstWhere((characteristic) => characteristic.uuid.toString() == "6e400002-b5a3-f393-e0a9-e50e24dcca9e");
    // Find the UART RX characteristic
    BluetoothCharacteristic rxCharacteristic = uartService.characteristics.firstWhere((characteristic) => characteristic.uuid.toString() == "6e400003-b5a3-f393-e0a9-e50e24dcca9e");
    // Set notify on the RX characteristic
    await rxCharacteristic.setNotifyValue(true);
    // Listen to the RX characteristic
    rxCharacteristic.value.listen((value) {
      // Do something with new value
      print(value);
    });
    // Send data to the TX characteristic
    txCharacteristic.write([0x01, 0x02, 0x03]);
    // Disconnect from device
    await device.disconnect();
  }
  }*/


  // Checksum calculator that returns a single byte
  static int checksum(Uint8List data) {
    uint8_t curr_crc = 0x0000;
    uint8_t sum1 = curr_crc;
    uint8_t sum2 = (curr_crc >> 8);
    int index;
    for(index = 0; index < data.length; index = index+1)
    {
      sum1 = (sum1 + data[index]) % 255;
      sum2 = (sum2 + sum1) % 255;
    }
    return (sum2 << 8) | sum1;
  }
/*
  // Implement the Nordic UART connection over BLE
  static Future<BluetoothDevice> connectToNordicUART() async {
    // Check for permissions
    if (await Permission.location.request().isGranted) {

  }*/
}