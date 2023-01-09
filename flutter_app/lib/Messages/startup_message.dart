import 'dart:typed_data';

import 'package:flutter_app/Messages/message.dart';

/// Implementazione della classe astratta [Message] che definisce un
/// messaggio di startup
class StartupMessage extends Message {
  /// Modello del sensore
  late final int model;

  /// Versione del firmware
  late final int version;

  /// Livello batteria in percentuale
  late final int battery;

  /// Il numero seriale del sensore
  late final int serial;

  @override
  int get type => MessageTypes.startupMessage;

  @override
  String toString() {
    return "StartupMessage: model: $model, version: $version, battery: $battery, serial: $serial";
  }

  StartupMessage.fromBytes(Uint8List data) {
    if (data.length != 7) {
      throw Exception("Lunghezza del messaggio non corretta");
    }
    model = data[0];
    version = data[1];
    // The serial number is here and it's 4 bytes long
    serial = data[5] + (data[4] << 8) + (data[3] << 16) + (data[2] << 24);
    battery = data[6];
  }

  Map<String, int> toDict() {
    return {
      "model": model,
      "version": version,
      "battery": battery,
    };
  }
}

class StartupMessageRequest extends Message {
  @override
  int get type => MessageTypes.msgRequest3;
}
