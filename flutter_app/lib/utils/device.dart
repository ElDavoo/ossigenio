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

// A class that represents a mac address.
// a mac address is a Uint8List of length 6.
// The constructor should check the length and throw an exception if it is not 6.
class MacAddress {
  final Uint8List mac;
  late Uint8List oui;
  late Uint8List nic;

  MacAddress(this.mac) {
    if (mac.length != 6) {
      throw Exception('Mac address must be 6 bytes long');
    }
    oui = mac.sublist(0, 3);
    nic = mac.sublist(3, 6);
    bool ok = false;
    for (Uint8List oui in BTConst().allowedOUIs) {
      if (listEquals(this.oui, oui)) {
        ok = true;
        break;
      }
    }
    if (!ok) {
      throw Exception('Mac address is not of allowed vendors');
    }
  }

  @override
  String toString() {
    //Just return the mac address as a string, without symbols
    return mac.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  }

  int toInt() {
    //Convert the mac address to an integer
    return mac.fold(0, (previousValue, element) => (previousValue << 8) + element);
  }
}

class Device extends ChangeNotifier {

  late BTUart btUart;

  late BluetoothDevice device;

  // Get the device state
  late Stream<BluetoothDeviceState> _stateStream;
  BluetoothDeviceState state = BluetoothDeviceState.connected;

  List<MessageWithDirection> messages = [];

  late Stream<MessageWithDirection> messagesStream;

  late MacAddress _serialNumber;

  //constructor that take blemanager and device and initializes a mqttmanager
  Device(ScanResult result, this.btUart) {
    _serialNumber = BLEManager.processAdv(result.advertisementData)!;
    device = result.device;
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
        MqttManager(mac: _serialNumber).publish(message.message);
      }
    });
    // make state a broadcast stream
    _stateStream = device.state.asBroadcastStream();
    // listen to the state stream and update the state
    _stateStream.listen((event) {
      state = event;
      // If we are disconnected, tell BLEManager
      if (state == BluetoothDeviceState.disconnected) {
        device.disconnect();
        BLEManager().disconnect(this);
      }
    });
    bool isConnected() {
      return state == BluetoothDeviceState.connected;
    }
  }
}
