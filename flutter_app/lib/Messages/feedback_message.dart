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

}

class FeedbackMessageRequest extends Message {
  @override
  int get type => MessageTypes.msgRequest4;

  @override
  Uint8List get data => SerialComm.buildMsgg(MessageTypes.feedbackMessage);
}