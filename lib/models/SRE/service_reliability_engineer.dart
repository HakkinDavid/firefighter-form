import 'dart:async';
import 'package:bomberos/models/settings.dart';
import 'Heuristic/connection_heuristic.dart';
import 'Heuristic/disk_heuristic.dart';
import 'Task/task.dart';

class ServiceReliabilityEngineer {
  static final ServiceReliabilityEngineer instance =
      ServiceReliabilityEngineer._internal();

  ServiceReliabilityEngineer._internal();

  factory ServiceReliabilityEngineer() {
    return instance;
  }

  final Map<String, Task> _tasksRepository = {};
  final List<String> _tasksQueue = [];
  bool _busy = false;

  void initialize() {
    _tasksRepository["LoadFromDisk"] = Task(
      heuristic: DiskHeuristic(),
      duty: timeDiskTask(Settings.instance.loadFromDisk),
    );
    _tasksRepository["SetForms"] = Task(
      heuristic: ConnectionHeuristic(),
      duty: Settings.instance.setForms,
    );
    _tasksRepository["SyncForms"] = Task(
      heuristic: ConnectionHeuristic(),
      duty: Settings.instance.syncForms,
      dependsOn: {"LoadFromDisk"},
    );

    enqueueTasks({"LoadFromDisk", "SetForms", "SyncForms"});
  }

  void enqueueTasks(Iterable<String> requestedTasks) {
    for (String requested in requestedTasks) {
      _tasksRepository[requested]?.setAsPending();
      _tasksQueue.add(requested);
    }

    _processQueue();
  }

  void _processQueue() async {
    if (_busy || _tasksQueue.isEmpty) return;

    _busy = true;
    _tasksRepository.forEach((taskId, processedTask) async {
      if (_tasksQueue.contains(taskId)) {
        if (processedTask.dependsOn.every(
          (dependency) => !_tasksRepository[dependency]!.pending,
        )) {
          await processedTask.runTask();
        }
        if (!processedTask.pending) {
          _tasksQueue.removeWhere((t) => t == taskId);
        }
      }
      await Future.delayed(Duration.zero);
    });
    _busy = false;
  }

  // final ConnectionHeuristic _connectionHeuristic = ConnectionHeuristic();

  // late Timer timer = Timer.periodic(
  //   const Duration(seconds: 30),
  //   (t) async => await testConnectionHeuristic(),
  // );
  //
  // Future<void> testConnectionHeuristic() async {
  //   if (await _connectionHeuristic.value) {
  //     for (var taskName in _connectionTasks) {
  //       if (_tasksRepository[taskName]!.pending) {
  //         await _tasksRepository[taskName]!.runTask();
  //       }
  //     }
  //   }
  // }

  // Temporary function while all disk logic is being moved from Settings to here
  Future<void> Function() timeDiskTask(Future<void> Function() func) {
    return () async {
      DateTime start = DateTime.now();
      await func();
      DiskHeuristic.lastWriteTime = DateTime.now()
          .difference(start)
          .inMilliseconds;
      DiskHeuristic.lastWriteTimestamp = DateTime.now();
    };
  }
}
