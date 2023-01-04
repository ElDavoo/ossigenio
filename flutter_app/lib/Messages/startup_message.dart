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
      return "StartupMessage: model: $model, version: $version, battery: $battery";
    } else {
      return "StartupMessage: model: $model, version: $version, battery: $battery, data: $data";
    }
  }

  // fromBytes
  StartupMessage.fromBytes(this.data) {
    //TODO implement
    model = data[0];
    version = data[1];
    battery = data[2];
  }

  Map <String, dynamic> toDict() {
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
  Uint8List get data => SerialComm.buildMsgg(MessageTypes.msgRequest3);
}
