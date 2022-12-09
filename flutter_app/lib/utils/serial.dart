/*
Class to communicate with the serial port.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter_blue/flutter_blue.dart';

import '../Messages/co2_message.dart';
import '../Messages/debug_message.dart';
import '../Messages/message.dart';
import 'log.dart';

typedef uint8_t = int;


class SerialComm {

  // Store the FlutterBlue instance.
  FlutterBlue flutterBlue = FlutterBlue.instance;
  // The start of a message is 0xAA.
  static const int startOfMessage = 0xAA;
  // The end of a message is 0xFFFF
  static const int endOfMessage = 0xFFFF;
  late BluetoothCharacteristic uartRX;

  SerialComm(BluetoothCharacteristic bluetoothCharacteristic){
    // Set the characteristic to the one passed in.
    uartRX = bluetoothCharacteristic;
  }


  // Checksum calculator that returns a single byte
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

  Message? receive(List<int> list) {
    Uint8List data = Uint8List.fromList(list);
      print("Received: $data");

    // Check if the message is valid
    if (data[0] == startOfMessage) {
        Log.l("Start of message is valid");
      // Check the message type
      switch (data[1]) {
        case MessageTypes.debugMessage:
            Log.l("Debug message received");
          return DebugMessage.dbgconstr(data);
        case MessageTypes.co2Message:
            Log.l("CO2 message received");
          return CO2Message.dbgconstr(data);
        case MessageTypes.extendedMessage:
          Log.l("Extended message received");
          // TODO
          return null;
        default:
          Log.l("Unknown message type");

          return null;
      }
    } else {
      // The message is invalid
      Log.l("Invalid message received: $data is not $startOfMessage");
      return null;

    }
  }

  void send(Uint8List data) {
    Log.l("Sending: $data");
    uartRX.write(data);
  }

  void sendMsg(int msgIndex){
    send(buildMsgg(msgIndex));
  }

  static Uint8List buildMsgg(int msgIndex){
   return buildMsg(msgIndex, Uint8List(0));
  }


  static Uint8List buildMsg(int msgIndex, Uint8List payload){
    Uint8List message = Uint8List(0);
    // Add the start of message byte
    message.add(startOfMessage);
    // Add the message type
    message.add(msgIndex);
    // Add the payload
    message.addAll(payload);
    // Add the end string
    message.add(endOfMessage);
    // Add the checksum
    message.add(checksum(message));
    return message;
  }

}