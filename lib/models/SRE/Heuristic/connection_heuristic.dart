import 'dart:io';
import 'heuristic.dart';

class ConnectionHeuristic extends Heuristic {
  @override
  Future<bool> testHeuristic() async {
    try {
      final result = await InternetAddress.lookup('gpmonaitogjvxrfznhef.supabase.co');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}