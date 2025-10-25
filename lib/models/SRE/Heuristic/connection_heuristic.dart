import 'dart:io';
import 'package:bomberos/models/SRE/Heuristic/heuristic.dart';
import 'package:bomberos/models/settings.dart';

class ConnectionHeuristic extends Heuristic {
  @override
  Future<bool> execute() async {
    try {
      final result = await InternetAddress.lookup(DatabaseSettings.host);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}
