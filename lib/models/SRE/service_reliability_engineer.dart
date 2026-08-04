import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:bomberos/models/logging.dart' show Logging;
import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/overlay_service.dart';
import 'Heuristic/connection_heuristic.dart';
import 'Heuristic/disk_heuristic.dart';
import 'Task/task.dart';
import 'package:bomberos/models/database_service.dart';
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

  static final _platform = Platform.isAndroid || Platform.isWindows
      ? const MethodChannel('mx.cetys.bomberos/low_level')
      : null;

  static String appVersion = "(?)";

  static Timer? _timer;
  static Function get startTimer => () {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (t) => ServiceReliabilityEngineer.instance._processQueue(),
    );
  };

  Future<void> fetchAppVersion() async {
    appVersion = (await PackageInfo.fromPlatform()).version;
  }

  void initialize() {
    _tasksRepository["SaveToDisk"] = Task(
      heuristic: DiskHeuristic(),
      duty: _saveToDisk,
    );
    _tasksRepository["IsUpdateAvailable"] = Task(
      heuristic: ConnectionHeuristic(),
      duty: _isUpdateAvailable,
      dependsOn: {"LoadFromDisk"},
    );
    _tasksRepository["UpdateApp"] = Task(
      heuristic: ConnectionHeuristic(),
      duty: _updateApp,
      dependsOn: {"SaveToDisk"},
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
      retryOnFailure: true,
      postponeInterval: const Duration(seconds: 5),
    );
    _tasksRepository["SetUser"] = Task(
      heuristic: ConnectionHeuristic(),
      duty: Settings.instance.setUser,
    );
    _tasksRepository["UpdateTemplate"] = Task(
      heuristic: ConnectionHeuristic(),
      duty: Settings.instance.updateTemplate,
      dependsOn: {"LoadFromDisk"},
    );
    _tasksRepository["RefreshTemplates"] = Task(
      heuristic: ConnectionHeuristic(),
      duty: Settings.instance.refreshTemplates,
    );
    _tasksRepository["RefreshUsers"] = Task(
      heuristic: ConnectionHeuristic(),
      duty: Settings.instance.refreshUsers,
      dependsOn: {"LoadFromDisk"},
    );

    enqueueTasks({
      "LoadFromDisk",
      "SetUser",
      "SyncForms",
      "UpdateTemplate",
      "IsUpdateAvailable",
      "RefreshUsers",
    });

    ServiceReliabilityEngineer.startTimer();
  }

  void enqueueTasks(Iterable<String> requestedTasks) {
    for (String requested in requestedTasks) {
      if (!_tasksRepository.containsKey(requested)) {
        Logging(
          "Rechazando encolamiento de $requested. No es una tarea válida.",
          caller: "SRE (enqueueTasks)",
          attentionLevel: 2,
        );
        return;
      }
      Logging(
        "Aceptando encolamiento de $requested en la posición ${_tasksQueue.length}.",
        caller: "SRE (enqueueTasks)",
        attentionLevel: 1,
      );
      _tasksRepository[requested]?.setAsPending();
      _tasksQueue.add(requested);
    }
    _processQueue();
  }

  void _processQueue() async {
    if (_tasksQueue.isEmpty || _busy.isLocked) return;

    for (String taskId in List<String>.from(_tasksQueue)) {
      final processedTask = _tasksRepository[taskId];
      if (processedTask == null || processedTask.isPostponed) continue;

      final dependenciesResolved = processedTask.dependsOn.every(
        (dependency) => !(_tasksRepository[dependency]?.pending ?? false),
      );

      if (!dependenciesResolved) continue;

      final isViable = await processedTask.heuristic.evaluate();
      if (!isViable) {
        Logging(
          "Heurística no viable para $taskId. Posponiendo ejecución.",
          caller: "SRE (_processQueue)",
        );
        processedTask.postpone();
        continue;
      }

      Logging(
        "Solicitando mutex para $taskId. Actualmente está ${_busy.isLocked ? "bloqueado" : "libre"}.",
        caller: "SRE (_processQueue)",
      );
      await _busy.acquire();
      try {
        Logging(
          "Ejecutando... $taskId",
          caller: "SRE (_processQueue)",
          attentionLevel: 1,
        );
        await processedTask.runTask();
      } catch (e) {
        Logging(
          "Excepción durante ejecución de $taskId: $e",
          caller: "SRE (_processQueue)",
          attentionLevel: 2,
        );
      } finally {
        Logging(
          "Liberando mutex tras $taskId.",
          caller: "SRE (_processQueue)",
        );
        _busy.release();
      }

      Logging(
        "Terminó ejecución de $taskId. Tarea ${processedTask.pending ? "pendiente" : "terminada"}.",
        caller: "SRE (_processQueue)",
        attentionLevel: 1,
      );

      if (!processedTask.pending) {
        Logging(
          "Eliminando de la cola a $taskId.",
          caller: "SRE (_processQueue)",
          attentionLevel: 1,
        );
        _tasksQueue.removeWhere((t) => t == taskId);
      }
    }
  }

  bool _compareReleaseVersions(String latest, String current) {
    final latestList = latest.split('.').map((s) => int.parse(s)).toList();
    final currentList = current.split('.').map((s) => int.parse(s)).toList();

    // This will only work for the next 73 years
    return latestList[0] > currentList[0] ||
        (latestList[0] == currentList[0] &&
            (latestList[1] > currentList[1] ||
                (latestList[1] == currentList[1] &&
                    latestList[2] > currentList[2])));
  }

  Future<void> _isUpdateAvailable() async {
    if (_platform == null) {
      Logging(
        "El dispositivo no soporta actualizaciones automáticas. Saliendo de la función...",
        caller: "SRE (_isUpdateAvailable)",
      );
      return;
    }

    final releaseMap = await _platform!.invokeMethod('isUpdateAvailable');
    if (releaseMap['available'] == true &&
        _compareReleaseVersions(
          releaseMap['latest_version'],
          releaseMap['current_version'],
        )) {
      Logging(
        "Se encontró la versión v${releaseMap['latest_version']} (actual v${releaseMap['current_version']}). Llamando _askForUserPermission.",
        caller: "SRE (_isUpdateAvailable)",
        attentionLevel: 3,
      );
      _askForUserPermission();
    } else {
      Logging(
        "No se encontraron actualizaciones del app (available: ${releaseMap['available']}). La versión actual es v${releaseMap['current_version']}.",
        caller: "SRE (_isUpdateAvailable)",
      );
    }
  }

  void _askForUserPermission() async {
    final navKey = Settings.instance.navigatorKey;
    final navState = navKey.currentState;

    // This might not be necessary, but just in case
    if (navState == null || navState.overlay == null) {
      Future.delayed(Duration(milliseconds: 100), () {
        _askForUserPermission();
      });
      return;
    }

    final screenSize = MediaQuery.of(navKey.currentContext!).size;
    final positionX = screenSize.width / 2;
    final positionY = screenSize.height - 190;

    Logging(
      "Mostrando alerta de actualización.",
      caller: "SRE (_askForUserPermission)",
      attentionLevel: 2,
    );

    OverlayService.showOverlay(
      position: Offset(positionX, positionY),
      buttonSize: Size.zero,
      overlayWidth: screenSize.width - 10,
      overlayPadding: 10,
      borderRadius: 8,
      tapToClose: false,
      overlayContent: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Se encontró una versión más reciente de la aplicación, ¿actualizar ahora?",
              style: TextStyle(
                color: Settings.instance.colors.textOverPrimary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CupertinoButton(
                  onPressed: OverlayService.closeCurrentOverlay,
                  color: CupertinoColors.systemGrey,
                  child: const Text('Más tarde'),
                ),
                CupertinoButton(
                  onPressed: () {
                    Logging(
                      "El usuario aceptó la actualización. Encolando SaveToDisk y UpdateApp.",
                      caller: "SRE (_askForUserPermission)",
                      attentionLevel: 3,
                    );
                    OverlayService.closeCurrentOverlay();
                    enqueueTasks({"SaveToDisk", "UpdateApp"});
                  },
                  color: Settings.instance.colors.primaryContrastDark,
                  child: const Text('Actualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateApp() async {
    if (_platform == null) {
      Logging(
        "El dispositivo no soporta actualizaciones automáticas. Saliendo de la función...",
        caller: "SRE (_updateApp)",
      );
      return;
    }

    try {
      await _platform!.invokeMethod('updateApp');
      Logging(
        "Actualización descargada. Delegando responsabilidad al usuario.",
        caller: "SRE (_updateApp)",
        attentionLevel: 3,
      );
    } catch (e) {
      Logging(
        "Error actualizando app: $e",
        caller: "SRE (_updateApp)",
        attentionLevel: 3,
      );
    }
  }

  // === DISK / DATABASE FUNCTIONS ===
  Future<void> _loadFromDisk() async {
    try {
      DateTime start = DateTime.now();

      final userId = await DatabaseService.instance.getAppState('userId');
      final allowDebuggingStr = await DatabaseService.instance.getAppState('allowDebugging');

      if (userId != null) {
        Settings.instance.userId = userId;
      }
      if (allowDebuggingStr != null) {
        Settings.instance.allowDebugging = (allowDebuggingStr == 'true');
      }

      Settings.instance.userCache = await DatabaseService.instance.getUsers();
      Settings.instance.formsQueue = await DatabaseService.instance.getFormsQueue();

      Logging(
        "Cargado de SQLite: userId=${Settings.instance.userId}, userCache=${Settings.instance.userCache.keys}, formsQueue=${Settings.instance.formsQueue.length}",
        caller: "SRE (_loadFromDisk)",
      );

      DiskHeuristic.lastWriteTime = DateTime.now()
          .difference(start)
          .inMilliseconds;
      DiskHeuristic.lastWriteTimestamp = DateTime.now();
    } catch (e) {
      Logging(e, caller: "SRE (_loadFromDisk)");
    }
  }

  Future<void> _saveToDisk() async {
    if (_writeQueue.isEmpty) {
      Logging("No hay nada para escribir", caller: "SRE (_saveToDisk)");
      return;
    }

    DateTime start = DateTime.now();
    List<(String, Map<String, dynamic> Function()?)> completedWrites = [];

    final currentQueue = List.from(_writeQueue);
    for (var writeRequest in currentQueue) {
      try {
        if (writeRequest.$2 != null) {
          Map<String, dynamic> jsonMap = writeRequest.$2!();
          if (jsonMap.isNotEmpty) {
            // Write requests processed directly via DatabaseService helper functions
          }
        }
        completedWrites.add(writeRequest);
      } catch (e) {
        Logging(e, caller: "SRE (_saveToDisk)");
      }
    }
    _writeQueue.removeWhere((wq) => completedWrites.contains(wq));

    DiskHeuristic.lastWriteTime = DateTime.now()
        .difference(start)
        .inMilliseconds;
    DiskHeuristic.lastWriteTimestamp = DateTime.now();

    Logging(
      "Nuevas heurísticas: ${DiskHeuristic.lastWriteTime} ms (${DiskHeuristic.lastWriteTimestamp})",
      caller: "SRE (_saveToDisk)",
    );
  }
}
