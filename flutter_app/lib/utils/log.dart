import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Log {

  static final Log _instance = Log._internal();

  factory Log() {
    return _instance;
  }

  Log._internal();

  // a stream of strings
  static final StreamController<String> snackStream = StreamController<String>.broadcast();

  static String formatMsg(String stacktrace, String msg) {
    // get the line of the log
    String lol = stacktrace.split("\n")[1];
    List<String> lol2 = lol.split(" ");
    //Delete first element
    lol2.removeAt(0);
    // The second non empty string is the name of the calling function
    for (String s in lol2) {
      if (s.isNotEmpty) {
        stacktrace = s;
        break;
      }
    }
    return "$stacktrace: $msg";
  }
  // Make warnings shut up
  static void l(String message) {
    if (kDebugMode) {
      // Get the name of the calling function
      String caller = StackTrace.current.toString();
      print(formatMsg(caller, message));
      snackStream.add(formatMsg(caller, message));
    }
  }

  static void addListener(BuildContext context) {
    Log.snackStream.stream.listen((event) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              duration: const Duration(seconds: 2),
              content: Text(event)
          )
      );
    });
  }

}