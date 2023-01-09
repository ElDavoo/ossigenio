import 'dart:typed_data';

import 'package:flutter_app/Messages/message.dart';

import '../utils/serial.dart';

/// Implementazione della classe astratta [Message] che definisce un
/// messaggio di tipo CO2
class CO2Message extends Message {
  /// Temperatura in gradi Celsius
  late final int temperature;

  /// Umidità in percentuale
  late final int humidity;

  /// Concentrazione di CO2 in ppm
  late final int co2;

  @override
  int get type => MessageTypes.co2Message;

  // toString
  @override
  String toString() {
    return "CO2Message: co2: $co2, temp: $temperature, hum: $humidity";
  }

  // fromBytes
  CO2Message.fromBytes(Uint8List data) {
    if (data.length != 4) {
      throw Exception("Lunghezza del messaggio non corretta");
    }
    temperature = data[0];
    humidity = data[1];
    // La concentrazione di CO2 è un numero a 16 bit
    co2 = data[3] + (data[2] << 8);
  }

  Map<String, int> toDict() {
    return {
      "temperature": temperature,
      "humidity": humidity,
      "co2": co2,
    };
  }
}

class CO2MessageRequest extends Message {
  @override
  int get type => MessageTypes.msgRequest1;

  Uint8List get data => SerialComm.buildMsg(MessageTypes.msgRequest1);
}
