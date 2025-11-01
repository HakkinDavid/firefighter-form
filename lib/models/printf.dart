import 'package:flutter/foundation.dart' show kDebugMode;

void log(Object? o, {String? caller}) {
  if (kDebugMode) {
    caller != null ? print("[$caller] > $o") : print(o);
  }
}