/*
Class to communicate with the serial port.
 */

import 'dart:ffi';

import 'package:flutter_blue/flutter_blue.dart';
import 'dart:typed_data';

typedef uint8_t = int;

//list of commands with their corresponding values
enum MessageTypes {
  debugMessage(0x80),
  co2Message(0x81),
  extendedMessage(2),
  startupMessage(0x83),
  feedbackMessage(0x94),
  msgRequest0(0x0f),
  msgRequest1(0x0e),
  msgRequest2(0x0c),
  msgRequest3(0x0d);

  const MessageTypes(this.value);
  final int value;
}

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
    uint8_t curr_crc = 0x0000;
    uint8_t sum1 = curr_crc;
    uint8_t sum2 = (curr_crc >> 8);
    int index;
    for(index = 0; index < data.length; index = index+1)
    {
      sum1 = (sum1 + data[index]) % 255;
      sum2 = (sum2 + sum1) % 255;
    }
    return (sum2 << 8) | sum1;
  }
  void receive(List<int> list) {
    Uint8List data = Uint8List.fromList(list);
    print("Received: " + data.toString());
  }
  void send(Uint8List data) {
    print("Sending: " + data.toString());

  }
  void sendMsg(int msgIndex){
    Uint8List message = buildMsg(msgIndex, Uint8List(0));
    send(message);
  }
  Uint8List buildMsg(int msgIndex, Uint8List payload){
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