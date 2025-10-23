import 'dart:async';
import 'package:bomberos/models/settings.dart';
import 'Heuristic/connection_heuristic.dart';
import 'Heuristic/disk_heuristic.dart';
import 'Task/task.dart';

class ServiceReliabilityEngineer {
  static final ServiceReliabilityEngineer instance = ServiceReliabilityEngineer._internal();

  ServiceReliabilityEngineer._internal();

  factory ServiceReliabilityEngineer() {
    return instance;
  }

  final Map<String, Task> tasks = {};
  final List<String> _connectionTasks = [];
  final List<String> _diskTasks = [];

  void setInitialTasks() {
    // The tasks being added are just examples
    tasks["SyncForms"] = Task(
        heuristic: ConnectionHeuristic(),
        trueTask: () => Settings.instance.syncForms
    );
    tasks["SyncForms"]!.setReady(true);

    tasks["SaveToDisk"] = Task(
      heuristic: DiskHeuristic(),
      trueTask: timeDiskTask(Settings.instance.saveToDisk)
    );

    _connectionTasks.addAll({"SyncForms"});
    _diskTasks.addAll({"SaveToDisk"});
  }

  final ConnectionHeuristic _connectionHeuristic = ConnectionHeuristic();

  late Timer timer = Timer.periodic(
    const Duration(seconds: 30),
    (t) async => await testConnectionHeuristic(),
  );

  Future<void> testConnectionHeuristic() async {
    if (await _connectionHeuristic.value) {
      for (var taskName in _connectionTasks) {
        if (tasks[taskName]!.ready) {
          await tasks[taskName]!.runTask();
        }
      }
    }
  }

  // Temporary function while all disk logic is being moved from Settings to here
  void Function() timeDiskTask(void Function() func) {
    return () async {
      DateTime start = DateTime.now();
      await Future.value(func);
      DiskHeuristic.lastWriteTime = DateTime.now().difference(start).inMilliseconds;
      DiskHeuristic.lastWriteTimestamp = DateTime.now();
    };
  }
}