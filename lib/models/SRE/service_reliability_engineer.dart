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
  final List<String> _tasksQueue = [];
  bool _isWorking = false;

  void initialize() {
    tasks["LoadFromDisk"] = Task(
      heuristic: DiskHeuristic(),
      trueTask: timeDiskTask(Settings.instance.loadFromDisk)
    );
    tasks["SetForms"] = Task(
        heuristic: ConnectionHeuristic(),
        trueTask: () => Settings.instance.setForms
    );

    enqueueTasks({"LoadFromDisk"});
  }

  void enqueueTasks(Iterable<String> newTasks) {
    for (String task in newTasks) {
      if (tasks.containsKey(task)) {
        tasks[task]!.setReady(true);
        _tasksQueue.add(task);
      }
    }

    _processQueue();
  }

  void _processQueue() async {
    if (_isWorking || _tasksQueue.isEmpty) return;

    _isWorking = true;
    tasks.forEach((key, value) async {
      if (_tasksQueue.contains(key)) {
        await value.runTask();
        if (!value.ready) {
          _tasksQueue.removeWhere((t) => t == key);
        }
      }
      await Future.delayed(Duration.zero);
    });
    _isWorking = false;
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
  //       if (tasks[taskName]!.ready) {
  //         await tasks[taskName]!.runTask();
  //       }
  //     }
  //   }
  // }

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