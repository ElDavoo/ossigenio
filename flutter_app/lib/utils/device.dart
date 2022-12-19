/*
This class represents a device.
 */
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../Messages/message.dart';
import '../managers/ble_man.dart';
import '../managers/mqtt_man.dart';
import 'log.dart';

class Device {
  late BTUart btUart;

  BluetoothDevice device;
  late MqttManager mqttManager;

  //constructor that take blemanager and device and initializes a mqttmanager
  Device(this.device, this.btUart) {
    Log.v("Initializing Device: ${device.name} - ${device.id}");
    mqttManager = MqttManager();
    mqttManager.connect('', '');
    // listen to the stream and publish the messages
    BLEManager().messagesStream?.listen((message) {
      Log.v("Message received");
      if (message.direction == MessageDirection.received) {
        mqttManager.publish(message.message);
      }
    });
  }
}
