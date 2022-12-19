/*
This abstract class defines a Message, that must have a MessageType.
 */

//list of commands with their corresponding values
import 'dart:typed_data';

class MessageTypes {
  static const debugMessage = 0x80;
  static const co2Message = 0x81;
  static const extendedMessage = 0x82;
  static const startupMessage = 0x83;
  static const feedbackMessage = 0x94;
  static const msgRequest0 = 0x1f;
  static const msgRequest1 = 0x1e;
  static const msgRequest2 = 0x1d;
  static const msgRequest3 = 0x1c;
  static const msgRequest4 = 0x1b;
}

abstract class Message {
  int get type;

  //only for debug
  Uint8List get data;

  // fromBytes constructor
  Message.fromBytes(Uint8List data);

  // generic constructor
  Message();
}

enum MessageDirection { received, sent }

class MessageWithDirection {
  final MessageDirection direction;

  //timestamp
  final DateTime timestamp;
  final Message message;

  MessageWithDirection(this.direction, this.timestamp, this.message);

  //override tostring
  @override
  String toString() {
    String dir = direction == MessageDirection.received ? "R" : "S";
    //timestamp as HH:MM:SS
    String time = timestamp.toString().substring(11, 19);
    return "$dir $time ${message.toString()}";
  }
}
