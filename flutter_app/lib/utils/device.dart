/*
This class represents a device.
 */
import 'package:flutter_blue/flutter_blue.dart';

import '../Messages/co2_message.dart';
import '../Messages/message.dart';
import '../managers/ble_man.dart';
import '../managers/mqtt_man.dart';
import 'log.dart';

class Device {

  BLEManager bleManager;
  BluetoothDevice device;
  late MqttManager mqttManager;
  //constructor that take blemanager and device and initializes a mqttmanager
  Device(this.bleManager, this.device) {
    mqttManager = MqttManager();
    // listen to the stream and publish the messages
    bleManager.messagesStream?.listen((message) {
      // TODO also take other messages
      Log.l("Message received");
      if (message.direction == MessageDirection.received) {
        if (message.message is CO2Message) {
          mqttManager.publish(message.message);
        }
      }
    });
  }


}