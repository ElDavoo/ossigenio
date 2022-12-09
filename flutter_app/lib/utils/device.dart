/*
This class represents a device.
 */
import 'package:flutter_blue/flutter_blue.dart';

import '../managers/ble_man.dart';

class Device {

  BLEManager bleManager;
  BluetoothDevice device;
  Device(this.bleManager, this.device);

}