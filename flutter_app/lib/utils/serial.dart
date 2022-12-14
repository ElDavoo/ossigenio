/*
Class to communicate with the serial port.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter_blue/flutter_blue.dart';

import '../Messages/co2_message.dart';
import '../Messages/debug_message.dart';
import '../Messages/feedback_message.dart';
import '../Messages/message.dart';
import 'log.dart';

typedef uint8_t = int;


class SerialComm {

  // The start of a message is 0xAA.
  static const int startOfMessage = 0xAA;
  // The end of a message is 0xFFFF
  static const int endOfMessage = 0xFF;

  // Checksum calculator that returns a single byte
  // FIXME
  static int checksum(Uint8List data) {
    uint8_t currCrc = 0x0000;
    uint8_t sum1 = currCrc;
    uint8_t sum2 = (currCrc >> 8);
    int index;
    for(index = 0; index < data.length; index = index+1)
    {
      sum1 = (sum1 + data[index]) % 255;
      sum2 = (sum2 + sum1) % 255;
    }
    return (sum2 << 8) | sum1;
  }

  static Message? receive(List<int> list) {
    Uint8List data = Uint8List.fromList(list);
    if (data.length < 4) {
      Log.l("data.length < 2");
      return null;
    }
    Log.l("Received: $data");

    // Check if the message is valid
    if (data[0] != startOfMessage) {
      Log.l("Invalid start byte: ${data[data.length-2]} is not $startOfMessage");
      return null;
    }
    // Check if the almost last byte is the end of message
    if (data[data.length - 2] != endOfMessage) {
      Log.l("Invalid end byte, ${data[data.length - 2]} is not $endOfMessage");
      return null;
    }
    // Check checksum
    int calculatedChecksum = checksum(data.sublist(1, data.length - 2));
    int receivedChecksum = data[data.length - 1];
    if (calculatedChecksum != receivedChecksum) {
      Log.l("Checksum should be $calculatedChecksum but it is $receivedChecksum");
      //TODO calculate better checksum on bluefruit side
      //return null;
    }
      // Check the message type
      Uint8List payload = data.sublist(2, data.length - 2);
      switch (data[1]) {
        case MessageTypes.debugMessage:
            Log.l("Debug message received");
          return DebugMessage.dbgconstr(data);
        case MessageTypes.co2Message:
            Log.l("CO2 message received");
          Message message = CO2Message.fromBytes(payload);
          Log.l('$message');
          return message;
        case MessageTypes.extendedMessage:
          Log.l("Extended message received");
          // TODO
          return null;
        case MessageTypes.feedbackMessage:
          Log.l("Feedback message received");
          Message message = FeedbackMessage.fromBytes(payload);
          Log.l('$message');
          return message;
        default:
          Log.l("Unknown message type");

          return null;
      }

  }



  static Uint8List buildMsgg(int msgIndex){
   return buildMsg(msgIndex, Uint8List(0));
  }


  static Uint8List buildMsg(int msgIndex, Uint8List payload){
    List<int> message = List.empty(growable: true);
    // Add the start of message byte
    message.add(startOfMessage);
    // Add the message type
    message.add(msgIndex);
    // Add the payload
    message.addAll(payload);
    // Add the end string
    message.add(endOfMessage);
    // Add the checksum
    message.add(checksum(Uint8List.fromList(message)));
    return Uint8List.fromList(message);
  }

}