import 'dart:typed_data';

import 'package:flutter_app/utils/serial.dart';

import '../Messages/message.dart';

enum FeedbackValues { nothing, positive, neutral, negative}

class FeedbackMessage extends Message {
  late final int rawData;
  late final int temperature;
  late final int humidity;
  late final FeedbackValues feedback;

  @override
  int get type => MessageTypes.feedbackMessage;

  @override
  late final Uint8List data;

  // Debug constructor
  FeedbackMessage.dbgconstr(this.data){
    rawData = 0;
    temperature = 0;
    humidity = 0;
  }

  // Proper constructor
  FeedbackMessage(this.rawData, this.temperature, this.humidity) {
    data = Uint8List(0);
  }

  // toString
  @override
  String toString() {
    if (data.isEmpty) {
      return "DebugMessage: rawData: $rawData, temperature: $temperature, humidity: $humidity, feedback: $feedback";
    } else {
      return "DebugMessage: rawData: $rawData, temperature: $temperature, humidity: $humidity, feedback: $feedback, data: $data";
    }
  }

  // fromBytes
  FeedbackMessage.fromBytes(this.data) {
    //TODO implement
    rawData = data[0];
    temperature = data[1];
    humidity = data[2];
  }

}

class FeedbackMessageRequest extends Message {
  @override
  int get type => MessageTypes.msgRequest4;

  @override
  Uint8List get data => SerialComm.buildMsgg(MessageTypes.msgRequest4);
}