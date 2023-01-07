import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Questa classe rappresenta una seriale bluetooth
class BTUart {
  late final BluetoothCharacteristic rxCharacteristic;
  late final BluetoothCharacteristic txCharacteristic;

  BTUart(this.rxCharacteristic, this.txCharacteristic);
}