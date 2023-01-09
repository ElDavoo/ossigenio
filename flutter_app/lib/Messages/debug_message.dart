import 'dart:typed_data';

import 'package:flutter_app/Messages/message.dart';

class DebugMessage extends Message {
  /// Valore grezzo del sensore
  late final int rawData;

  /// Temperatura in gradi Celsius
  late final int temperature;

  /// Umidità in percentuale
  late final int humidity;

  @override
  int get type => MessageTypes.debugMessage;

  // toString
  @override
  String toString() {
    return "DebugMessage: rawData: $rawData, temperature: $temperature, humidity: $humidity";
  }

  // fromBytes
  DebugMessage.fromBytes(Uint8List data) {
    if (data.length != 4) {
      throw Exception("Lunghezza del messaggio non corretta");
    }
    temperature = data[0];
    humidity = data[1];
    // La concentrazione di CO2 è un numero a 16 bit
    rawData = data[3] + (data[2] << 8);
  }

  Map<String, int> toDict() {
    return {
      "rawData": rawData,
      "temperature": temperature,
      "humidity": humidity,
    };
  }
}

class DebugMessageRequest extends Message {
  @override
  int get type => MessageTypes.msgRequest0;
}
