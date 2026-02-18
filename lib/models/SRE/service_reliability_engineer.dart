import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:bomberos/models/logging.dart' show Logging;
import 'package:bomberos/models/settings.dart';
import 'package:bomberos/models/user.dart';
import 'package:bomberos/models/form.dart';
import 'package:bomberos/viewmodels/overlay_service.dart';
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

  int updateAvailable = 0;
  late BuildContext welcomeContext;

  static final _platform = Platform.isAndroid
      ? const MethodChannel('mx.cetys.bomberos/low_level')
      : null;
  
  static String appVersion = "(?)";

  static Timer? _timer;
  static Function get startTimer => () {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer.periodic(
      const Duration(seconds: 5),
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
    );
    _tasksRepository["SetUser"] = Task(
      heuristic: ConnectionHeuristic(),
      duty: Settings.instance.setUser,
    );
    _tasksRepository["FetchTemplate"] = Task(
      heuristic: ConnectionHeuristic(),
      duty: Settings.instance.fetchTemplate
    );
    _tasksRepository["RefreshTemplates"] = Task(
      heuristic: ConnectionHeuristic(),
      duty: Settings.instance.refreshTemplates
    );

    enqueueTasks({"LoadFromDisk", "SyncForms", "FetchTemplate", "IsUpdateAvailable"});

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
    if (_tasksQueue.isEmpty) return;

    _tasksRepository.forEach((taskId, processedTask) async {
      if (_tasksQueue.contains(taskId)) {
        if (processedTask.dependsOn.every(
          (dependency) => !_tasksRepository[dependency]!.pending,
        )) {
          Logging(
            "Solicitando mutex. Actualmente está ${_busy.isLocked ? "bloqueado" : "libre"}.",
            caller: "SRE (_processQueue)",
          );
          await _busy.acquire();
          Logging(
            "Adquirido mutex. Ahora está ${_busy.isLocked ? "bloqueado" : "libre (??)"}.",
            caller: "SRE (_processQueue)",
          );
          Logging(
            "Ejecutando... $taskId",
            caller: "SRE (_processQueue)",
            attentionLevel: 1,
          );
          await processedTask.runTask();
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
          Logging(
            "Liberando mutex ${_busy.isLocked ? "bloqueado" : "libre (??)"}.",
            caller: "SRE (_processQueue)",
          );
          _busy.release();
        }
      }
      await Future.delayed(Duration.zero);
    });
  }

  bool _compareReleaseVersions(String latest, String current) {
    final latestList = latest.split('.').map((s) => int.parse(s)).toList();
    final currentList = current.split('.').map((s) => int.parse(s)).toList();

    // This will only work for the next 74 years
    return latestList[0] > currentList[0] ||
        (latestList[0] == currentList[0] &&
            (latestList[1] > currentList[1] ||
                (latestList[1] == currentList[1] &&
                    latestList[2] > currentList[2])));
  }

  Future<void> _isUpdateAvailable() async {
    if (_platform == null) {
      Logging(
        "El dispositivo no es Android. Saliendo de la función...",
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
        "Se encontró la versión v${releaseMap['latest_version']} (actual v${releaseMap['current_version']}). Pidiendo permiso al usuario para actualizar.",
        caller: "SRE (_isUpdateAvailable)",
        attentionLevel: 3,
      );
      updateAvailable = 1;
    } else {
      Logging(
        "No se encontraron actualizaciones del app (available: ${releaseMap['available']}). La versión actual es v${releaseMap['current_version']}.",
        caller: "SRE (_isUpdateAvailable)",
      );
      updateAvailable = 2;
    }
  }

  void askForUserPermission({BuildContext? context}) async {
    if (context != null) {
      welcomeContext = context;
    }

    if (updateAvailable == 0) {
      Future.delayed(Duration(milliseconds: 100), () {
        askForUserPermission();
      });
      return;
    }

    if (updateAvailable == 1) {
      final screenSize = MediaQuery.of(welcomeContext).size;
      final positionX = screenSize.width / 2;
      final positionY = screenSize.height - 190;

      Logging(
        "Mostrando alerta de actualización.",
        caller: "SRE (askForUserPermission)",
        attentionLevel: 2,
      );

      OverlayService.showOverlay(
        context: welcomeContext,
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
                    onPressed: () => enqueueTasks({"SaveToDisk", "UpdateApp"}),
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
  }

  Future<void> _updateApp() async {
    if (_platform == null) {
      Logging(
        "El dispositivo no es Android. Saliendo de la función...",
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

  void enqueueWriteTasks(
    List<(String, Map<String, dynamic> Function()?)> writeTasks,
  ) {
    int writeIndex = 0;
    Logging(
      "Recibiendo ${writeTasks.length} solicitudes para SaveToDisk...",
      caller: "SRE (enqueueWriteTasks)",
    );
    for (var writeTask in writeTasks) {
      Logging(
        "[$writeIndex] ${writeTask.$2 != null ? "Escritura" : "Eliminación"} para ruta ${writeTask.$1.replaceRange(0, writeTask.$1.length - 30, '...')}.",
        caller: "SRE (enqueueWriteTasks)",
      );
      _writeQueue.add((writeTask.$1, writeTask.$2));
      writeIndex++;
    }
    enqueueTasks({"SaveToDisk"});
  }

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

          Logging(
            "Actualizado Settings.instance.userId: ${Settings.instance.userId}",
            caller: "SRE (_loadFromDisk)",
          );
          Logging(
            "Actualizado Settings.instance.role: ${Settings.instance.role}",
            caller: "SRE (_loadFromDisk)",
          );
        } else {
          Logging("No existe userDataFile", caller: "SRE (_loadFromDisk)");
        }

        final userCacheFile = File('${directory.path}/user_cache.json');

        if (await userCacheFile.exists()) {
          final userCacheString = await userCacheFile.readAsString();
          final Map<String, dynamic> userCacheMap = jsonDecode(userCacheString);

          Settings.instance.userCache = userCacheMap.map(
            (key, value) => MapEntry(key, FirefighterUser.fromJson(value)),
          );
          Logging(
            "Actualizado Settings.instance.userCache: ${Settings.instance.userCache.keys}",
            caller: "SRE (_loadFromDisk)",
          );
        } else {
          Logging("No existe userCacheFile", caller: "SRE (_loadFromDisk)");
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

          Logging(
            "Actualizado Settings.instance.formsQueue con longitud: ${Settings.instance.formsQueue.length}",
            caller: "SRE (_loadFromDisk)",
          );
        } else {
          Logging(
            "No existe formsQueueDirectory",
            caller: "SRE (_loadFromDisk)",
          );
        }

        // Gather metrics for DiskHeuristic
        DiskHeuristic.lastWriteTime = DateTime.now()
            .difference(start)
            .inMilliseconds;
        DiskHeuristic.lastWriteTimestamp = DateTime.now();
      } else {
        Logging("El directorio no existe...", caller: "SRE (_loadFromDisk)");
      }
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

    for (var writeRequest in _writeQueue) {
      Logging(
        "Atendiendo ${writeRequest.$1.replaceRange(0, writeRequest.$1.length - 30, '...')}",
        caller: "SRE (_saveToDisk)",
      );
      try {
        final file = File(writeRequest.$1);

        if (writeRequest.$2 != null) {
          Map<String, dynamic> jsonMap = writeRequest.$2!();

          if (jsonMap.isNotEmpty) {
            final jsonString = jsonEncode(jsonMap);

            if (!await file.exists()) file.create(recursive: true);
            await file.writeAsString(jsonString);
          }
          Logging("Escrito.", caller: "SRE (_saveToDisk)");
        } else if (await file.exists()) {
          Logging("Eliminado.", caller: "SRE (_saveToDisk)");
          await file.delete();
        }

        completedWrites.add(writeRequest);
      } catch (e) {
        Logging(e, caller: "SRE (_saveToDisk)");
      }
    }
    // This seems fishy with the way Dart handles references
    _writeQueue.removeWhere((wq) => completedWrites.contains(wq));

    // Gather metrics for DiskHeuristic
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
