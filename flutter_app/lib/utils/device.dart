/*
This class represents a device.
 */
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/Messages/debug_message.dart';
import 'package:flutter_app/utils/serial.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../Messages/message.dart';
import '../Messages/startup_message.dart';
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

  late MacAddress serialNumber;

  late bool isHeating = true;

  late Timer timer;

  //constructor that take blemanager and device and initializes a mqttmanager
  Device(ScanResult result, this.btUart) {
    serialNumber = BLEManager.processAdv(result.advertisementData)!;
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
        MqttManager(mac: serialNumber).publish(message.message);
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
        timer.cancel();
        BLEManager().disconnect(this);
      }
    });
    messagesStream.where((event) => event.direction == MessageDirection.received)
        .where((event) => event.message is DebugMessage)
        .map((event) => event.message)
        .cast<DebugMessage>()
        .listen((event) {
          if (isHeating) {
            isHeating = (event.rawData - event.temperature).abs() <= 3;
            if (!isHeating) {
              timer.cancel();
              timer = Timer.periodic(const Duration(seconds: 60), (_) => periodicallyRequest);
            }
          }
          Log.l("Diff: ${(event.rawData - event.temperature).abs()}");
    });
    bool isConnected() {
      return state == BluetoothDeviceState.connected;
    }
    // Send a startup message request
    BLEManager.sendMsg(this, MessageTypes.msgRequest0);
    Future.delayed(const Duration(milliseconds: 100)).then((value) => BLEManager.sendMsg(this, MessageTypes.msgRequest1));
    Future.delayed(const Duration(milliseconds: 300)).then((value) => BLEManager.sendMsg(this, MessageTypes.msgRequest3));
    Future.delayed(const Duration(milliseconds: 3600)).then((value) => BLEManager.sendMsg(this, MessageTypes.msgRequest0));

    timer = Timer.periodic(const Duration(seconds: 30), (_) => periodicallyRequest());
  }
  void periodicallyRequest(){
    Log.l("Asking for data");
      BLEManager.sendMsg(this, MessageTypes.msgRequest0);
      Future.delayed(const Duration(milliseconds: 500)).then((value) => BLEManager.sendMsg(this, MessageTypes.msgRequest3));
  }
}
