import 'heuristic.dart';

class DiskHeuristic extends Heuristic {
  static int lastWriteTime = 0;
  static DateTime lastWriteTimestamp = DateTime.utc(0);

  @override
  Future<bool> testHeuristic() async {
    if (lastWriteTime < 1000) return true;

    Duration timeElapsed = DateTime.now().difference(lastWriteTimestamp);
    return timeElapsed.inMilliseconds > (5000 * lastWriteTime);
  }
}