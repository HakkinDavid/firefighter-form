import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bomberos/models/SRE/service_reliability_engineer.dart';
import 'package:bomberos/models/form.dart';
import 'package:bomberos/models/logging.dart';
import 'package:bomberos/models/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ColorsSettings {
  final Color primary = Color.fromRGBO(98, 19, 51, 1.0);
  final Color primaryBright = Color.fromRGBO(156, 35, 72, 1.0);
  final Color background = CupertinoColors.white;
  final Color primaryContrast = Color.fromRGBO(231, 210, 149, 1.0);
  final Color primaryContrastDark = Color.fromRGBO(166, 128, 45, 1.0);
  final Color textOverPrimary = CupertinoColors.white;
  final Color attentionBadge = CupertinoColors.activeOrange;
  final Color disabled = Color.fromRGBO(152, 152, 154, 1.0);
}

class DatabaseSettings {
  static final host = 'gpmonaitogjvxrfznhef.supabase.co';
  static final url = 'https://${DatabaseSettings.host}';
  static final anonKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbW9uYWl0b2dqdnhyZnpuaGVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3NjQxNTksImV4cCI6MjA3NDM0MDE1OX0.-udPuvfzbJ1SKdP-QcBt_NTlpU720P-hdBGm_n0kE7I";
}

class Settings {
  static final Settings instance = Settings._internal();
  final ColorsSettings colors = ColorsSettings();

  Settings._internal();

  factory Settings() {
    return instance;
  }

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String? _userId;

  String get userId => _userId ?? '';
  set userId(String userId) {
    // Maybe check with regex that the id format is correct
    _userId = userId;
  }

  bool _allowDebugging = false;

  set allowDebugging(bool state) {
    _allowDebugging = state;
    Logging(
      "${state ? "Activando" : "Desactivando"} depuración",
      caller: "Settings (allowDebugging)",
    );
  }

  bool get allowDebugging => _allowDebugging;

  Map<String, FirefighterUser> _userCache = {};
  List<ServiceForm> _formsQueue = [];
  List<ServiceForm> _formsList = [];

  final StreamController<Map<String, FirefighterUser>>
  _userCacheStreamController =
      StreamController<Map<String, FirefighterUser>>.broadcast();
  Stream<Map<String, FirefighterUser>> get userCacheStream =>
      _userCacheStreamController.stream;

  final StreamController<List<ServiceForm>> _formsStreamController =
      StreamController<List<ServiceForm>>.broadcast();
  Stream<List<ServiceForm>> get formsListStream =>
      _formsStreamController.stream;

  Map<String, FirefighterUser> get userCache => _userCache;
  List<ServiceForm> get formsQueue => _formsQueue;
  // Direct setters for now
  set userCache(Map<String, FirefighterUser> userCache) {
    _userCache = userCache;
  }

  set formsQueue(List<ServiceForm> formsQueue) {
    _formsQueue = formsQueue;
  }

  bool get isLoggedIn => _userId != null && _userCache.containsKey(_userId);

  FirefighterUser? get self => _userCache[_userId];
  FirefighterUser? get watcher => _userCache[self?.watchedByUserId ?? ""];

  List<ServiceForm> get formsList {
    final combined =
        _formsQueue +
        (_formsList..retainWhere(
          (fl) => _formsQueue.indexWhere((fq) => fq.id == fl.id) == -1,
        ));
    _formsStreamController.add(combined);
    return combined;
  }

  Future<void> setUserRole(String userId, int userRole) async {
    await Supabase.instance.client.rpc(
      'set_user_role',
      params: {'p_user_id': userId, 'p_role_id': userRole},
    );
    FirefighterUser promotee = await fetchUser(pUserId: userId);
    Logging(
      "Se ha establecido ${promotee.fullName} como ${promotee.roleName}.",
      caller: "Settings (setUserRole)",
    );
  }

  Future<void> setUserHierarchy(String watchedId, String? watcherId) async {
    await Supabase.instance.client.rpc(
      'set_user_hierarchy',
      params: {'p_watched_id': watchedId, 'p_watcher_id': watcherId},
    );
    FirefighterUser watched = await fetchUser(pUserId: watchedId);
    FirefighterUser watcher = await fetchUser(pUserId: watcherId);
    Logging(
      "Se ha establecido ${watcher.fullName} como tutelar de ${watched.fullName}.",
      caller: "Settings (setUserHierarchy)",
    );
  }

  Map<String, dynamic> Function() mapAccessor(String accessed, {String? id}) {
    switch (accessed) {
      case 'userData':
        {
          return () {
            Map<String, dynamic> map = {'userId': Settings.instance.userId};
            return map;
          };
        }
      case 'userCache':
        {
          return () {
            Map<String, dynamic> map = Settings.instance.userCache.map(
              (key, value) => MapEntry(key, value.toJson()),
            );
            return map;
          };
        }
      case 'formsQueue':
        {
          if (id != null) {
            return () {
              Map<String, dynamic> map = Settings.instance.formsQueue
                  .firstWhere((f) => f.id == id)
                  .toJson();
              return map;
            };
          } else {
            return () {
              Map<String, dynamic> map = {};
              return map;
            };
          }
        }
      default:
        {
          return () {
            Map<String, dynamic> map = {};
            return map;
          };
        }
    }
  }

  Future<void> setUser() async {
    try {
      setUserId();
      await fetchUser();
    } catch (e) {
      Logging(
        "Error intentando establecer usuario. Probablemente no hay una sesión activa.\n\t\t$e",
        caller: "Settings (setUser)",
        attentionLevel: 4,
      );
    }
  }

  Future<void> setForms() async {
    try {
      final formRecords = await Supabase.instance.client
          .from('filled_in')
          .select('*')
          .order('filled_at');
      _formsList = formRecords
          .asMap()
          .map((key, value) => MapEntry(key, ServiceForm.fromJson(value)))
          .values
          .toList();
      _formsStreamController.add(formsList);
    } catch (e) {
      // yo cuando no hago nada
    }
  }

  void setUserId() {
    _userId = Supabase.instance.client.auth.currentUser!.id;
  }

  Future<FirefighterUser> fetchUser({String? pUserId}) async {
    pUserId ??= _userId!;
    await refreshUsers();
    return _userCache[pUserId]!;
  }

  Future<bool> isTemplateAvailable(int id) async {
    return await File(await getTemplateRoute(id)).exists();
  }

  Future<Map<String, dynamic>> getTemplate(int id) async {
    if (!(await isTemplateAvailable(id))) {
      final template = await fetchTemplate(id: id);
      ServiceReliabilityEngineer.instance.enqueueWriteTasks([template]);
      return template.$2();
    }
    File templateFile = File(await getTemplateRoute(id));

    return json.decode(await templateFile.readAsString());
  }

  Future<int?> getNewestSavedTemplate() async {
    try {
      final directory = Directory(await getTemplatesDirectoryRoute());
      int? newest;

      if (await directory.exists()) {
        await for (var t in directory.list()) {
          String name = t.path.split('/').last.split('.').first;
          int? tId = int.tryParse(name);
          if (tId != null && tId > (newest ?? 0)) newest = tId;
        }
      } else {
        ServiceReliabilityEngineer.instance.enqueueTasks({"UpdateTemplate"});
      }

      return newest;
    } catch (e) {
      // Handle exceptions if needed
    }

    return null;
  }

  Future<Map<String, dynamic>> getTemplateRecord({int? tId}) async {
    late final Map<String, dynamic> templateRecord;

    if (tId == null) {
      templateRecord = await Supabase.instance.client
          .from('template')
          .select('id, content')
          .order('created_at', ascending: false)
          .limit(1)
          .single();
    } else {
      templateRecord = await Supabase.instance.client
          .from('template')
          .select('id, content')
          .eq('id', tId)
          .single();
    }

    return templateRecord;
  }

  Future<String> getTemplateRoute(int id) async {
    return '${await getTemplatesDirectoryRoute()}/$id.json';
  }

  Future<String> getTemplatesDirectoryRoute() async {
    return '${(await getApplicationDocumentsDirectory()).path}/frap';
  }

  Future<String> getSettingsDirectoryRoute() async {
    return '${(await getApplicationDocumentsDirectory()).path}/settings';
  }

  Future<void> refreshTemplates() async {
    try {
      final directory = Directory(await getTemplatesDirectoryRoute());
      if (await directory.exists()) {
        final List<(String, Map<String, dynamic> Function()?)>
        templateRefreshTasks = [];
        await for (var t in directory.list()) {
          String name = t.path.split('/').last.split('.').first;
          int? tId = int.tryParse(name);
          if (tId == null) continue;
          templateRefreshTasks.addAll([
            (t.path, null),
            await fetchTemplate(id: tId),
          ]);
        }
        ServiceReliabilityEngineer.instance.enqueueWriteTasks(
          templateRefreshTasks,
        );
      }
    } catch (e) {
      // yo cuando no hago algo
    }
  }

  Future<void> refreshUsers() async {
    try {
      final userNamesRecord = await Supabase.instance.client
          .from('user_name')
          .select('*');

      final userRolesMap =
          (await Supabase.instance.client.from('user_role').select('*'))
              .asMap()
              .map((key, value) => MapEntry(value['id'], value['value']));

      final userHierarchyRecord = await Supabase.instance.client
          .from('user_hierarchy')
          .select('*');

      final watchedMapById = {
        for (var element in userHierarchyRecord)
          element['id']: element['watched_by'],
      };

      final Map<String, Set<String>> watcherMapById = {};
      for (var hierarchyRecordX in userHierarchyRecord) {
        if (hierarchyRecordX['watched_by'] == null) continue;
        watcherMapById.update(
          hierarchyRecordX['watched_by'],
          (watches) => watches..add(hierarchyRecordX['id']),
          ifAbsent: () => {hierarchyRecordX['id']},
        );
      }

      for (var userNameRecordX in userNamesRecord) {
        String idX = userNameRecordX['id'];
        _userCache[idX] = FirefighterUser(
          id: idX,
          givenName: userNameRecordX['given'],
          firstSurname: userNameRecordX['surname1'],
          secondSurname: userNameRecordX['surname2'],
          role: userRolesMap[idX],
          watchedByUserId: watchedMapById[idX],
          watchesUsersId: watcherMapById[idX] ?? <String>{},
        );
      }
      _userCacheStreamController.add(_userCache);
      String directory = await getSettingsDirectoryRoute();
      ServiceReliabilityEngineer.instance.enqueueWriteTasks([
        ('$directory/user_data.json', mapAccessor('userData')),
        ('$directory/user_cache.json', mapAccessor('userCache')),
      ]);
    } catch (e) {
      Logging(
        "Error intentando refrescar usuarios: $e",
        caller: "Settings (refreshUsers)",
        attentionLevel: 3,
      );
    }
  }

  Future<(String, Map<String, dynamic> Function())> fetchTemplate({
    int? id,
  }) async {
    late final String templateRoute;
    late final Map<String, dynamic> template;

    if (id != null) {
      template = await getTemplateRecord(tId: id);
      templateRoute = await getTemplateRoute(id);
    } else {
      template = await getTemplateRecord();
      templateRoute = await getTemplateRoute(template['id']);
    }
    return (templateRoute, () => template['content'] as Map<String, dynamic>);
  }

  Future<void> updateTemplate() async {
    try {
      final template = await fetchTemplate();
      if (await File(template.$1).exists()) return;
      ServiceReliabilityEngineer.instance.enqueueWriteTasks([template]);
    } catch (e) {
      // yo cuando hago algo
    }
  }

  // This will be an actual function later
  Future<bool> uploadTemplate(Map<String, dynamic> template) async {
    try {
      await Supabase.instance.client.rpc(
        'upload_template',
        params: {'p_template': template},
      );
      ServiceReliabilityEngineer.instance.enqueueTasks({"UpdateTemplate"});
    } catch (error) {
      if (!error.toString().contains('Postgrest')) {
        return false;
      } else {
        rethrow;
      }
    }
    return true;
  }

  Future<void> enqueueForm(ServiceForm form) async {
    int index = _formsQueue.indexWhere((f) => f.id == form.id);
    if (index == -1) {
      _formsQueue.add(form);
    } else {
      _formsQueue[index] = form;
    }

    String directory = await getSettingsDirectoryRoute();

    ServiceReliabilityEngineer.instance.enqueueWriteTasks([
      (
        '$directory/forms/${form.id}.json',
        mapAccessor('formsQueue', id: form.id),
      ),
    ]);

    ServiceReliabilityEngineer.instance.enqueueTasks({"SyncForms"});
    _formsStreamController.add(formsList);
  }

  Future<void> dequeueForm(String id) async {
    _formsQueue.removeWhere((f) => f.id == id);

    String directory = await getSettingsDirectoryRoute();
    ServiceReliabilityEngineer.instance.enqueueWriteTasks([
      ('$directory/forms/$id.json', null),
    ]);

    _formsStreamController.add(formsList);
  }

  Future<bool> uploadForm(ServiceForm form) async {
    try {
      await Supabase.instance.client.rpc(
        'upload_filled_in',
        params: form.toJson(asUpload: true),
      );
    } catch (error) {
      if (!error.toString().contains('Postgrest')) {
        return false;
      } else {
        rethrow;
      }
    }
    await dequeueForm(form.id);
    return true;
  }

  Future<void> syncForms() async {
    final syncCandidates = List<ServiceForm>.from(
      _formsQueue.where((f) => f.status == 1),
    );

    for (var syncing in syncCandidates) {
      if (!(await uploadForm(syncing))) {
        return;
      }
    }

    ServiceReliabilityEngineer.instance.enqueueTasks({"SetForms"});
  }

  Future<void> deleteForm(ServiceForm form) async {
    try {
      if (form.status == 2) {
        await Supabase.instance.client.rpc(
          'delete_filled_in',
          params: {'p_id': form.id},
        );
      } else {
        await Settings.instance.dequeueForm(form.id);
      }
      ServiceReliabilityEngineer.instance.enqueueTasks({"SetForms"});
      _formsStreamController.add(formsList);
    } catch (error) {
      // no importa si no se borra, mejor para nosotros.
    }
  }
}
