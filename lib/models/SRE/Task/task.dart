import 'package:bomberos/models/SRE/Heuristic/heuristic.dart';

class Task {
  final Heuristic heuristic;
  final Future<void> Function() duty;
  final Future<void> Function()? dereliction;
  final Set<String> dependsOn;
  bool _pending = false;

  bool get pending => _pending;

  Task({
    required this.heuristic,
    required this.duty,
    this.dereliction,
    this.dependsOn = const {},
  });

  void setAsPending() {
    _pending = true;
  }

  Future<void> runTask() async {
    if (await heuristic.result) {
      await duty();
      _pending = false;
    } else if (dereliction != null) {
      await dereliction!();
    }
  }
}
