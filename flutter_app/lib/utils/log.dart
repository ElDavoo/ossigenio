import 'package:flutter/foundation.dart';

class Log {
  // Make warnings shut up
  static void l(String message) {
    if (kDebugMode) {
      // Get the name of the calling function
      String caller = StackTrace.current.toString();
          String lol = caller.split("\n")[1];
          List<String> lol2= lol.split(" ");
          //Delete first element
          lol2.removeAt(0);
          // The second non empty string is the name of the calling function
          for (String s in lol2){
            if (s.isNotEmpty){
              caller = s;
              break;
            }
          }
     print("$caller: $message");
    }
  }
}