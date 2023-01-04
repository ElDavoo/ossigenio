import 'dart:typed_data';

import 'package:flutter_app/utils/serial.dart';

import '../Messages/message.dart';

enum FeedbackValues { nothing, positive, neutral, negative }

class FeedbackMessage extends Message {
  late final int temperature;
  late final int humidity;
  late final int co2;
  late final FeedbackValues feedback;

  @override
  int get type => MessageTypes.feedbackMessage;

  @override
  Uint8List data = Uint8List(0);

  // Debug constructor
  FeedbackMessage.dbgconstr(this.data) {
    co2 = 0;
    temperature = 0;
    humidity = 0;
  }

  // Proper constructor
  FeedbackMessage(this.co2, this.temperature, this.humidity, this.feedback);

  // toString
  @override
  String toString() {
    if (data.isEmpty) {
      return "FeedBackMsg: co2: $co2, temp: $temperature, hum: $humidity, feedback: ${feedback.toString().split(".")[1]}";
    } else {
      return "FeedBackMsg: co2: $co2, temp: $temperature, hum: $humidity, feedback: ${feedback.toString().split(".")[1]}, data: $data";
    }
  }

  // fromBytes
  FeedbackMessage.fromBytes(this.data) {
    temperature = data[0];
    humidity = data[1];
    //co2 instead is a 16 bit number
    co2 = data[3] + (data[2] << 8);
    feedback = FeedbackValues.values[data[4]];
  }

  Map <String, dynamic> toDict() {
    return {
      "temperature": temperature,
      "humidity": humidity,
      "co2": co2,
      "feedback": feedback.toString().split(".")[1],
    };
  }
}

class FeedbackMessageRequest extends Message {
  @override
  int get type => MessageTypes.msgRequest4;

  @override
  Uint8List get data => SerialComm.buildMsgg(MessageTypes.msgRequest4);
}
