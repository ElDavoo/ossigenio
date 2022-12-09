/*
An implementation of the abstract class Message, that defines a CO2 message.
 */
import 'dart:typed_data';

import 'package:flutter_app/Messages/message.dart';

class StartupMessage extends Message {
  late final int model;
  late final int version;
  late final int battery;

  @override
  late final Uint8List data;

  @override
  int get type => MessageTypes.startupMessage;

}