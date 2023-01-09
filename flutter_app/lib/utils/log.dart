import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Classe di Log, per stampare messaggi di debug.
class Log {
  static final Log _instance = Log._internal();

  factory Log() {
    return _instance;
  }

  Log._internal();

  /// Stream di stringhe a cui vengono aggiunti i messaggi di log.
  static final StreamController<String> _snackStream =
      StreamController<String>.broadcast();

  /// Trova il nome della funzione chiamante e la prepende al messaggio.
  static String _formatMsg(String msg) {
    final String stacktrace = StackTrace.current.toString();
    final String funLine = stacktrace.split("\n")[2];
    final List<String> tokens = funLine.split(" ");
    // Il primo elemento è la profondità della chiamata
    tokens.removeAt(0);
    // Il secondo elemento non vuoto è il nome della funzione
    final String funName =
        tokens.firstWhere((element) => element.isNotEmpty && element != "new");
    return "$funName: $msg";
  }

  /// Stampa un messaggio solo in snack e solo in modalità debug.
  static void d(String msg) {
    if (kDebugMode) {
      debugPrint(_formatMsg(msg));
    }
  }

  /// Stampa un messaggio sia in console sia in snack, se in modalità debug.
  static void v(String msg) {
    if (kDebugMode) {
      debugPrint(_formatMsg(msg));
      _snackStream.add(_formatMsg(msg));
    }
  }

  /// Stampa un messaggio in snack, e se in modalità debug anche in console.
  ///
  /// Se siamo in modalità debug, su snack viene mostrato anche
  /// il nome della funzione chiamante.
  static void l(String message) {
    if (kDebugMode) {
      debugPrint(_formatMsg(message));
      _snackStream.add(_formatMsg(message));
    } else {
      _snackStream.add(message);
    }
  }

  /// Aggiunge il listener al stream di snack.
  ///
  /// Quando una pagina viene inizializzata, aggiunge
  /// il listener al stream di snack, e quando viene
  /// distrutta rimuove il listener.
  static StreamSubscription<String> addListener(BuildContext context) {
    return Log._snackStream.stream.listen((event) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: const Duration(seconds: 1), content: Text(event)));
    });
  }
}
