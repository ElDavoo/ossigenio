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
  static const msgRequest0 = 0x0f;
  static const msgRequest1 = 0x0e;
  static const msgRequest2 = 0x0d;
  static const msgRequest3 = 0x0c;
  static const msgRequest4 = 0x0b;
}

abstract class Message {
  int get type;
  //only for debug
  Uint8List get data;
}
