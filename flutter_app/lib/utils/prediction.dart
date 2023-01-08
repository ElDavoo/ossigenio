/// Una predizione è una coppia timestamp - valore
class Prediction {
  final DateTime timestamp;
  final int co2;

  Prediction(this.timestamp, this.co2);

  // fromJson constructor
  Prediction.fromJson(Map<String, dynamic> json)
      : timestamp = DateTime.parse(json['timestamp']),
        co2 = json['co2'];
}
