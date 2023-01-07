/*
An implementation of the abstract class Message, that defines a CO2 message.
 */
import 'dart:typed_data';

import 'package:flutter_app/Messages/message.dart';

import '../utils/serial.dart';

class CO2Message extends Message {
  late final int temperature;
  late final int humidity;
  late final int co2;

  @override
  Uint8List data = Uint8List(0);

  @override
  int get type => MessageTypes.co2Message;

  // Debug constructor
  CO2Message.dbgconstr(this.data) {
    co2 = 0;
    temperature = 0;
    humidity = 0;
  }

  // Proper constructor
  CO2Message(this.temperature, this.humidity, this.co2) {
    data = Uint8List(0);
  }

  // toString
  @override
  String toString() {
    if (data.isEmpty) {
      return "CO2Message: co2: $co2, temp: $temperature, hum: $humidity";
    } else {
      return "CO2Message: co2: $co2, temp: $temperature, hum: $humidity, data: $data";
    }
  }

  // fromBytes
  CO2Message.fromBytes(Uint8List data) {
    temperature = data[0];
    humidity = data[1];
    //co2 instead is a 16 bit number
    co2 = data[3] + (data[2] << 8);
  }

  Map<String, dynamic> toDict() {
    return {
      "temperature": temperature,
      "humidity": humidity,
      "co2": co2,
    };
  }
}

class CO2MessageRequest extends Message {
  @override
  int get type => MessageTypes.msgRequest1;

  @override
  Uint8List get data => SerialComm.buildMsgg(MessageTypes.msgRequest1);
}
