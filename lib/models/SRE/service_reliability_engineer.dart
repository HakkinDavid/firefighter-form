import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bomberos/models/settings.dart';
import 'package:bomberos/models/user.dart';
import 'package:bomberos/models/form.dart';
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

    enqueueTasks({"LoadFromDisk"});
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
          if (!processedTask.pending) {
            _tasksQueue.removeWhere((t) => t == taskId);
          }
        }
      }
      await Future.delayed(Duration.zero);
    });
    _busy = false;
  }

  // final ConnectionHeuristic _connectionHeuristic = ConnectionHeuristic();

  late Timer timer = Timer.periodic(
    const Duration(seconds: 5),
    (t) => _processQueue(),
  );

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

  // === DISK FUNCTIONS ===
  Future<void> loadFromDisk() async {
    try {
      final directory = Directory(await Settings.instance.getSettingsDirectoryRoute());

      if (await directory.exists()) {
        DateTime start = DateTime.now();

        final userDataFile = File('${directory.path}/user_data.json');

        if (await userDataFile.exists()) {
          final userDataString = await userDataFile.readAsString();
          final Map<String, dynamic> userDataMap = jsonDecode(userDataString);

          Settings.instance.userId = userDataMap['userId'];
          Settings.instance.role = userDataMap['role'] ?? 0;
        }

        final userCacheFile = File('${directory.path}/user_cache.json');

        if (await userCacheFile.exists()) {
          final userCacheString = await userCacheFile.readAsString();
          final Map<String, dynamic> userCacheMap = jsonDecode(userCacheString);

          Settings.instance.userCache = userCacheMap.map(
                (key, value) => MapEntry(key, FirefighterUser.fromJson(value)),
          );
        }

        // What should the subdirectory be called?
        final formsQueueDirectory = Directory('${directory.path}/forms');

        if (await formsQueueDirectory.exists()) {
          List<ServiceForm> formsQueue = [];

          await for (var queuedForm in formsQueueDirectory.list()) {
            File formFile = File(queuedForm.path);
            String formString = await formFile.readAsString();

            ServiceForm form = ServiceForm.fromJson(jsonDecode(formString));
            formsQueue.add(form);
          }

          Settings.instance.formsQueue = formsQueue;
        }

        // Gather metrics for DiskHeuristic
        DiskHeuristic.lastWriteTime = DateTime.now()
            .difference(start)
            .inMilliseconds;
        DiskHeuristic.lastWriteTimestamp = DateTime.now();
      }
    } catch (e) {
      //
    }
  }
}
