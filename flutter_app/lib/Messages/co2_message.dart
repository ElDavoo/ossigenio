/*
An implementation of the abstract class Message, that defines a CO2 message.
 */
import 'dart:typed_data';

import 'package:flutter_app/Messages/message.dart';

import '../utils/serial.dart';

class CO2Message extends Message {
  late final int co2;
  late final int temperature;
  late final int humidity;

  @override
  late final Uint8List data;

  @override
  int get type => MessageTypes.co2Message;

  // Debug constructor
  CO2Message.dbgconstr(this.data){
    co2 = 0;
    temperature = 0;
    humidity = 0;
  }

  // Proper constructor
  CO2Message(this.co2, this.temperature, this.humidity) {
    data = Uint8List(0);
  }

  // toString
  @override
  String toString() {
    if (data.isEmpty) {
      return "DebugMessage: rawData: $co2, temperature: $temperature, humidity: $humidity";
    } else {
      return "DebugMessage: rawData: $co2, temperature: $temperature, humidity: $humidity, data: $data";
    }
  }

  // fromBytes
  CO2Message.fromBytes(this.data) {
    //TODO implement
    co2 = data[0];
    temperature = data[1];
    humidity = data[2];
  }

}

class CO2MessageRequest extends Message {
  @override
  int get type => MessageTypes.msgRequest1;

  @override
  Uint8List get data => SerialComm.buildMsgg(MessageTypes.msgRequest1);
}