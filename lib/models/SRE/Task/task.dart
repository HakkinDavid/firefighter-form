import 'package:bomberos/models/SRE/Heuristic/heuristic.dart';

class Task {
  final Heuristic heuristic;
  final Future<void> Function() trueTask;
  final Future<void> Function()? fallbackTask;
  final Set<String> dependsOn;
  bool ready = false;
  Task({
    required this.heuristic,
    required this.trueTask,
    this.fallbackTask,
    this.dependsOn = const {},
  });

  void setReady(bool value) => ready = value;

  Future<void> runTask() async {
    if (await heuristic.value) {
      await trueTask();
      ready = false;
    } else if (fallbackTask != null) {
      await Future.value(fallbackTask!);
    }
  }
}
