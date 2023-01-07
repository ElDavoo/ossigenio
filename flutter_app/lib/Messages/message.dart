import 'dart:typed_data';

/// Lista dei tipi di messaggi
class MessageTypes {
  /// Messaggio di debug
  static const int debugMessage = 0x80;

  /// Messaggio con temperatura, umidità e CO2
  static const int co2Message = 0x81;

  /// Messaggio con tutti i dati disponibili, inutilizzato
  static const int extendedMessage = 0x82;

  /// Messaggio con modello, revisione e livello di batteria
  static const int startupMessage = 0x83;

  /// Messaggio con temperatura, umidità, CO2 e feedback
  static const int feedbackMessage = 0x84;

  /// Richiesta per un messaggio di tipo [debugMessage]
  static const int msgRequest0 = 0x1f;

  /// Richiesta per un messaggio di tipo [co2Message]
  static const int msgRequest1 = 0x1e;

  /// Richiesta per un messaggio di tipo [extendedMessage]
  static const int msgRequest2 = 0x1d;

  /// Richiesta per un messaggio di tipo [startupMessage]
  static const int msgRequest3 = 0x1c;

  /// Richiesta per attivazione modalità debug
  static const int msgRequest4 = 0x1b;
}

/// Classe astratta che definisce un messaggio
/// col quale si comunica con il sensore
abstract class Message {
  int get type;

  /// Costruttore da una lista di byte
  Message.fromBytes(Uint8List data);

  // Costruttore generico
  const Message();
}

/// I messaggi possono essere ricevuti o inviati
enum MessageDirection { received, sent }

/// Classe che encapsula un messaggio con la sua direzione e il timestamp
class MessageWithDirection {
  /// La direzione del messaggio
  final MessageDirection direction;

  /// Il momento in cui il messaggio è stato registrato
  final DateTime timestamp;

  /// Il messaggio
  final Message message;

  const MessageWithDirection(this.direction, this.timestamp, this.message);

  @override
  String toString() {
    String dir = direction == MessageDirection.received ? "R" : "S";
    // Timestamp in formato HH:MM:SS
    String time = timestamp.toString().substring(11, 19);
    return "$dir $time ${message.toString()}";
  }
}
