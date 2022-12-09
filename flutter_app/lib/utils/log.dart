import 'package:flutter/foundation.dart';

class Log {
  // Make warnings shut up
  static void l(String message) {
    if (kDebugMode) {
      // Get the name of the calling function
      String caller = StackTrace.current.toString();
          String lol = caller.split("\n")[1];
          String lol2= lol.split(".")[1].split(" ")[0];
      print("$lol2: $message");
    }
  }
}