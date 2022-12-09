/*
An implementation of the abstract class Message, that defines a CO2 message.
 */
import 'package:flutter_app/Messages/message.dart';

class DebugMessage extends Message {
  late final int rawData;
  late final int temperature;
  late final int humidity;

  @override
  int get type => MessageTypes.debugMessage;

}