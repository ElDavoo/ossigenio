import 'package:flutter/foundation.dart';
import 'package:flutter_app/Messages/startup_message.dart';

import '../Messages/co2_message.dart';
import '../Messages/debug_message.dart';
import '../Messages/feedback_message.dart';
import '../Messages/message.dart';
import 'log.dart';

/// Questa classe implementa il protocollo di comunicazione seriale.
///
/// Il protocollo seriale viene usato per comunicare col sensore.
/// Nel nostro caso, la seriale viene stabilita su un canale BLE.
/// I dettagli del protocollo sono in /SerialProtocol.md
class SerialComm {
  static const int startOfMessage = 0xAA;
  static const int endOfMessage = 0xFF;

  /// Checksum calculator che ritorna un singolo byte
  // FIXME
  static int checksum(Uint8List data) {
    const int currCrc = 0x0000;
    int sum1 = currCrc;
    int sum2 = (currCrc >> 8);
    int index;

    for (index = 0; index < data.length; index = index + 1) {
      sum1 = (sum1 + data[index]) % 255;
      sum2 = (sum2 + sum1) % 255;
    }

    if (sum1 < 1) {
      sum1 += 255;
    }

    // TODO Capire bene come funziona il checksum
    return sum1 - 2;
  }

  /// Costruisce un messaggio a partire da un buffer di byte.
  static Message? receive(List<int> list) {
    // Convert the list to a list of bytes
    final Uint8List data = Uint8List.fromList(list);

    Log.d("Received: $data");

    if (data.length < 4) {
      Log.d("data.length < 2");
      return null;
    }

    if (data[0] != startOfMessage) {
      Log.d(
          "Invalid start byte: ${data[data.length - 2]} is not $startOfMessage");
      return null;
    }
    if (data[data.length - 2] != endOfMessage) {
      Log.d("Invalid end byte, ${data[data.length - 2]} is not $endOfMessage");
      return null;
    }

    final int calculatedChecksum = checksum(data.sublist(1, data.length - 2));
    final int receivedChecksum = data[data.length - 1];
    if (calculatedChecksum != receivedChecksum) {
      Log.v(
          "Checksum should be $calculatedChecksum but it is $receivedChecksum");
      // TODO Uncomment this when the checksum is fixed
      //return null;
    }

    // Check the message type
    final Uint8List payload = data.sublist(2, data.length - 2);
    final Message? message;
    switch (data[1]) {
      case MessageTypes.debugMessage:
        message = DebugMessage.fromBytes(payload);
        break;
      case MessageTypes.co2Message:
        message = CO2Message.fromBytes(payload);
        break;
      case MessageTypes.extendedMessage:
        Log.v("Extended message received");
        // TODO Implementare il supporto ai messaggi estesi
        return null;
      case MessageTypes.startupMessage:
        message = StartupMessage.fromBytes(payload);
        break;
      case MessageTypes.feedbackMessage:
        message = FeedbackMessage.fromBytes(payload);
        break;
      default:
        Log.v("Unknown message type ${data[1]}");
        return null;
    }

    Log.d(message.toString());

    return message;
  }

  /// Crea un messaggio da inviare
  static Uint8List buildMsg(int msgIndex) {
    return _buildMsg(msgIndex, Uint8List(0));
  }

  static Uint8List _buildMsg(int msgIndex, Uint8List payload) {
    final List<int> message = List.empty(growable: true);

    message.add(startOfMessage);
    message.add(msgIndex);
    message.addAll(payload);
    message.add(endOfMessage);
    message.add(checksum(Uint8List.fromList(message)));

    return Uint8List.fromList(message);
  }
}
