// ignore_for_file: constant_identifier_names, avoid_print

import 'package:bomberos/models/settings.dart' show Settings;

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

  static final List<String> logs = [];

  static log(String line) {
    print(line);
    logs.add(line);
  }

  Logging(Object? o, {String? caller, int attentionLevel = 0}) {
    if (Settings.instance.allowDebugging) {
      final rightNow = DateTime.now();
      if (rightNow.difference(lastLogTimestamp).inSeconds > 1) {
        log(
          "================================================================================",
        );
      }
      String printable =
          getAttention(attentionLevel) +
          (caller != null ? "[$caller] > $o" : "$o");
      log(printable);
      lastLogTimestamp = rightNow;
    }
  }
}
