import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'constants.dart';

/// Questa classe rappresenta una seriale bluetooth
class BTUart {
  late final BluetoothCharacteristic rxCharacteristic;
  late final BluetoothCharacteristic txCharacteristic;

  BTUart(this.rxCharacteristic, this.txCharacteristic);

  /// Ottiene un BTUart da un dispositivo
  static Future<BTUart> fromDevice(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    List<BluetoothCharacteristic> uartCharacteristics = services
        .firstWhere((service) => service.uuid.toString() == C.bt.nordicUARTID)
        .characteristics;
    BluetoothCharacteristic rxCharacteristic = uartCharacteristics.firstWhere(
        (characteristic) =>
            characteristic.uuid.toString() == C.bt.nordicUARTRXID);
    BluetoothCharacteristic txCharacteristic = uartCharacteristics.firstWhere(
        (characteristic) =>
            characteristic.uuid.toString() == C.bt.nordicUARTTXID);
    txCharacteristic.setNotifyValue(true);
    return BTUart(rxCharacteristic, txCharacteristic);
  }
}
