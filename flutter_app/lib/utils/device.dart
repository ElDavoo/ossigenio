/*
This class represents a device.
 */
import 'package:flutter/foundation.dart';
import 'package:flutter_app/utils/serial.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../Messages/message.dart';
import '../managers/ble_man.dart';
import '../managers/mqtt_man.dart';
import 'log.dart';


class Device extends ChangeNotifier {

  late BTUart btUart;

  BluetoothDevice device;

  // Get the device state
  late Stream<BluetoothDeviceState> _stateStream;
  BluetoothDeviceState state = BluetoothDeviceState.connected;

  List<MessageWithDirection> messages = [];

  late Stream<MessageWithDirection> messagesStream;

  //constructor that take blemanager and device and initializes a mqttmanager
  Device(this.device, this.btUart) {
    Log.v("Initializing Device: ${device.name} - ${device.id}");
    messagesStream = btUart.txCharacteristic.value
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
    messagesStream.listen((message) {
      messages.add(message);
      notifyListeners();
    });
    // listen to the stream and publish the messages
    messagesStream.listen((message) {
      Log.v("Message received");
      if (message.direction == MessageDirection.received) {
        MqttManager().publish(message.message);
      }
    });
    // make state a broadcast stream
    _stateStream = device.state.asBroadcastStream();
    // listen to the state stream and update the state
    _stateStream.listen((event) {
      state = event;
    });
    bool isConnected() {
      return this.state == BluetoothDeviceState.connected;
    }
  }
}
