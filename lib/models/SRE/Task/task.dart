import 'package:bomberos/models/SRE/Heuristic/heuristic.dart';

class Task {
  final Heuristic heuristic;
  final Future<void> Function() duty;
  final Future<void> Function()? dereliction;
  final Set<String> dependsOn;
  final bool retryOnFailure;
  final Duration postponeInterval;

  bool _pending = false;
  DateTime? _nextAttemptTimestamp;

  bool get pending => _pending;
  bool get isPostponed =>
      _nextAttemptTimestamp != null &&
      DateTime.now().isBefore(_nextAttemptTimestamp!);

  Task({
    required this.heuristic,
    required this.duty,
    this.dereliction,
    this.dependsOn = const {},
    this.retryOnFailure = false,
    this.postponeInterval = const Duration(seconds: 5),
  });

  void setAsPending() {
    _pending = true;
    _nextAttemptTimestamp = null;
  }

  void postpone([Duration? interval]) {
    _nextAttemptTimestamp = DateTime.now().add(interval ?? postponeInterval);
  }

  Future<void> runTask() async {
    if (await heuristic.result) {
      try {
        await duty();
        _pending = false;
        _nextAttemptTimestamp = null;
      } catch (e) {
        if (retryOnFailure) {
          _pending = true;
          postpone();
        } else {
          _pending = false;
          _nextAttemptTimestamp = null;
        }
        rethrow;
      }
    } else if (dereliction != null) {
      await dereliction!();
    }
  }
}

