import 'dart:async';
import 'dart:io';
import 'package:bomberos/models/SRE/Heuristic/heuristic.dart';
import 'package:bomberos/models/settings.dart';

class ConnectionHeuristic extends Heuristic {
  @override
  Future<bool> evaluate() async {
    try {
      final socket = await Socket.connect(DatabaseSettings.host, 443,
              timeout: const Duration(milliseconds: 500));
      socket.destroy();
      return true;
    } catch (_) {
      try {
        final result = await InternetAddress.lookup(DatabaseSettings.host)
            .timeout(const Duration(milliseconds: 500));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }
}
