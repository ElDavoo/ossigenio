import 'dart:typed_data';

import '../Messages/message.dart';

/// I possibili feedback che il sensore può inviare
enum FeedbackValues { nothing, positive, neutral, negative }

/// Implementazione della classe astratta [Message] che definisce un
/// messaggio di feedback
class FeedbackMessage extends Message {
  /// La temperatura in gradi Celsius
  late final int temperature;

  /// L'umidità in percentuale
  late final int humidity;

  /// La concentrazione di CO2 in ppm
  late final int co2;

  /// Il feedback che il sensore ha inviato
  late final FeedbackValues feedback;

  @override
  int get type => MessageTypes.feedbackMessage;

  @override
  String toString() {
    return "FeedBackMsg: co2: $co2, temp: $temperature, hum: $humidity, feedback: ${feedback.toString().split(".")[1]}";
  }

  FeedbackMessage.fromBytes(Uint8List data) {
    if (data.length != 5) {
      throw Exception("Lunghezza del messaggio non corretta");
    }
    temperature = data[0];
    humidity = data[1];
    // La concentrazione di CO2 è un numero a 16 bit
    co2 = data[3] + (data[2] << 8);
    feedback = FeedbackValues.values[data[4]];
  }

  Map<String, dynamic> toDict() {
    return {
      "temperature": temperature,
      "humidity": humidity,
      "co2": co2,
      "feedback": feedback.toString().split(".")[1],
    };
  }
}

class FeedbackMessageRequest extends Message {
  @override
  int get type => MessageTypes.msgRequest4;
}
