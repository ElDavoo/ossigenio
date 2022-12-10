/*
An implementation of the abstract class Message, that defines a CO2 message.
 */
import 'dart:typed_data';

import 'package:flutter_app/Messages/message.dart';

import '../utils/serial.dart';

class DebugMessage extends Message {
  late final int rawData;
  late final int temperature;
  late final int humidity;

  @override
  int get type => MessageTypes.debugMessage;

  @override
  late final Uint8List data;

  // Debug constructor
  DebugMessage.dbgconstr(this.data){
    rawData = 0;
    temperature = 0;
    humidity = 0;
  }

  // Proper constructor
   DebugMessage(this.rawData, this.temperature, this.humidity) {
     data = Uint8List(0);
   }

   // toString
    @override
    String toString() {
      if (data.isEmpty) {
        return "DebugMessage: rawData: $rawData, temperature: $temperature, humidity: $humidity";
      } else {
        return "DebugMessage: rawData: $rawData, temperature: $temperature, humidity: $humidity, data: $data";
      }
    }

    // fromBytes
    DebugMessage.fromBytes(this.data) {
      temperature = data[0];
      humidity = data[1];
      //co2 instead is a 16 bit number
      rawData = data[3] + (data[2] << 8);
    }
}

class DebugMessageRequest extends Message {
  @override
  int get type => MessageTypes.msgRequest0;

  @override
  Uint8List get data => SerialComm.buildMsgg(MessageTypes.msgRequest0);
}