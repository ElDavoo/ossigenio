/*
An implementation of the abstract class Message, that defines a CO2 message.
 */
import 'dart:typed_data';

import 'package:flutter_app/Messages/message.dart';

import '../utils/serial.dart';

class StartupMessage extends Message {
  late final int model;
  late final int version;
  late final int battery;
  late final int serial;

  @override
  late final Uint8List data;

  @override
  int get type => MessageTypes.startupMessage;

  // Debug constructor
  StartupMessage.dbgconstr(this.data) {
    model = 0;
    version = 0;
    battery = 0;
  }

  // Proper constructor
  StartupMessage(this.model, this.version, this.battery) {
    data = Uint8List(0);
  }

  // toString
  @override
  String toString() {
    if (data.isEmpty) {
      return "StartupMessage: model: $model, version: $version, battery: $battery, serial: $serial";
    } else {
      return "StartupMessage: model: $model, version: $version, battery: $battery, serial: $serial, data: $data";
    }
  }

  // fromBytes
  StartupMessage.fromBytes(this.data) {
    //TODO implement
    model = data[0];
    version = data[1];
    // The serial number is here now, it's 4 bytes long
    serial = data[5] + (data[4] << 8) + (data[3] << 16) + (data[2] << 24);
    battery = data[6];
  }

  Map<String, dynamic> toDict() {
    return {
      "model": model,
      "version": version,
      "battery": battery,
    };
  }
}

class StartupMessageRequest extends Message {
  @override
  int get type => MessageTypes.msgRequest3;

  @override
  Uint8List get data => SerialComm.buildMsg(MessageTypes.msgRequest3);
}
