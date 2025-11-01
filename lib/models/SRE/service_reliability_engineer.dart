import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bomberos/models/settings.dart';
import 'package:bomberos/models/user.dart';
import 'package:bomberos/models/form.dart';
import 'Heuristic/connection_heuristic.dart';
import 'Heuristic/disk_heuristic.dart';
import 'Task/task.dart';
import 'package:mutex/mutex.dart';

class ServiceReliabilityEngineer {
  static final ServiceReliabilityEngineer instance =
      ServiceReliabilityEngineer._internal();

  ServiceReliabilityEngineer._internal();

  factory ServiceReliabilityEngineer() {
    return instance;
  }

  final Map<String, Task> _tasksRepository = {};
  final List<String> _tasksQueue = [];
  final List<(String, Map<String, dynamic> Function()?)> _writeQueue = [];
  final _busy = Mutex();

  void initialize() {
    _tasksRepository["SaveToDisk"] = Task(
      heuristic: DiskHeuristic(),
      duty: _saveToDisk,
    );
    _tasksRepository["LoadFromDisk"] = Task(
      heuristic: DiskHeuristic(),
      duty: _loadFromDisk,
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
    if (_tasksQueue.isEmpty) return;

    _tasksRepository.forEach((taskId, processedTask) async {
      if (_tasksQueue.contains(taskId)) {
        if (processedTask.dependsOn.every(
          (dependency) => !_tasksRepository[dependency]!.pending,
        )) {
          await _busy.acquire();
          await processedTask.runTask();
          if (!processedTask.pending) {
            _tasksQueue.removeWhere((t) => t == taskId);
            _busy.release();
          }
        }
      }
      await Future.delayed(Duration.zero);
    });
  }

  void enqueueWriteTask(
    String path,
    Map<String, dynamic> Function()? accessor,
  ) {
    _writeQueue.add((path, accessor));
    enqueueTasks({"SaveToDisk"});
  }

  late Timer timer = Timer.periodic(
    const Duration(seconds: 5),
    (t) => _processQueue(),
  );

  // === DISK FUNCTIONS ===
  Future<void> _loadFromDisk() async {
    try {
      final directory = Directory(
        await Settings.instance.getSettingsDirectoryRoute(),
      );

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

          await for (var queued in formsQueueDirectory.list()) {
            String formString = await File(queued.path).readAsString();

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

  Future<void> _saveToDisk() async{
    if (_writeQueue.isEmpty) return;

    DateTime start = DateTime.now();
    List<(String, Map<String, dynamic> Function()?)> completedWrites = [];

    for (var writeRequest in _writeQueue) {
      try {
        final file = File(writeRequest.$1);

        if (writeRequest.$2 != null) {
          Map<String, dynamic> jsonMap = writeRequest.$2!();

          if (jsonMap.isNotEmpty) {
            final jsonString = jsonEncode(jsonMap);

            if (!await file.exists()) file.create(recursive: true);
            await file.writeAsString(jsonString);
          }
        } else if (await file.exists()) {
          await file.delete();
        }

        completedWrites.add(writeRequest);
      } catch (e) {
        //
      }
    }
    // This seems fishy with the way Dart handles references
    _writeQueue.removeWhere((wq) => completedWrites.contains(wq));

    // Gather metrics for DiskHeuristic
    DiskHeuristic.lastWriteTime = DateTime.now()
        .difference(start)
        .inMilliseconds;
    DiskHeuristic.lastWriteTimestamp = DateTime.now();
  }
}
