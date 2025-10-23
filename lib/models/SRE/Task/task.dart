import '../Heuristic/heuristic.dart';

class Task {
  final Heuristic heuristic;
  final void Function() trueTask;
  final void Function()? fallbackTask;
  bool ready = false;
  Task({
    required this.heuristic,
    required this.trueTask,
    this.fallbackTask,
  });

  void setReady(bool value) => ready = value;

  Future<void> runTask() async {
    if (await heuristic.value) {
      await Future.value(trueTask);
      ready = false;
    } else if (fallbackTask != null) {
      await Future.value(fallbackTask!);
    }
  }
}