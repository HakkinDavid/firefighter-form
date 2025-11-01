// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart' show kDebugMode;

class Logging {
  static DateTime lastLogTimestamp = DateTime(0);

  static String getAttention(int a) {
    switch (a) {
      case 5:
        return "🚨 ";
      case 4:
        return "‼️ ";
      case 3:
        return "📌 ";
      case 2:
        return "⚠️ ";
      case 1:
        return "ⓘ ";
      case 0:
      default:
        return "\t\t";
    }
  }

  Logging(Object? o, {String? caller, int attentionLevel = 0}) {
    if (kDebugMode) {
      final rightNow = DateTime.now();
      if (rightNow.difference(lastLogTimestamp).inSeconds > 1) {
        print(
          "================================================================================",
        );
      }
      String printable =
          getAttention(attentionLevel) +
          (caller != null ? "[$caller] > $o" : "$o");
      print(printable);
      lastLogTimestamp = rightNow;
    }
  }
}
