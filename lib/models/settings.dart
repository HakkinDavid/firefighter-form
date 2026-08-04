import 'dart:async';
import 'package:bomberos/models/SRE/Heuristic/connection_heuristic.dart';
import 'package:bomberos/models/SRE/service_reliability_engineer.dart';
import 'package:bomberos/models/database_service.dart';
import 'package:bomberos/models/form.dart';
import 'package:bomberos/models/local_account.dart';
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
    _userId = userId;
    DatabaseService.instance.setAppState('userId', userId);
  }

  bool _allowDebugging = false;

  set allowDebugging(bool state) {
    _allowDebugging = state;
    DatabaseService.instance.setAppState('allowDebugging', state.toString());
    ServiceReliabilityEngineer.instance.enqueueTasks(["RefreshUsers"]);
    Logging(
      "${state ? "Activando" : "Desactivando"} depuración",
      caller: "Settings (allowDebugging)",
      attentionLevel: 2,
    );
  }

  bool get allowDebugging => _allowDebugging;

  Map<String, FirefighterUser> _userCache = {};
  List<ServiceForm> _formsQueue = [];
  List<ServiceForm> _formsList = [];
  List<LocalUserAccount> _localAccounts = [];
  bool _isSessionValid = true;

  bool get isSessionValid => _isSessionValid;

  bool get isCloudAuthAligned {
    if (!_isSessionValid) return false;
    final cloudUser = Supabase.instance.client.auth.currentUser;
    return cloudUser != null && cloudUser.id == _userId;
  }

  final StreamController<Map<String, FirefighterUser>>
      _userCacheStreamController =
      StreamController<Map<String, FirefighterUser>>.broadcast();
  Stream<Map<String, FirefighterUser>> get userCacheStream =>
      _userCacheStreamController.stream;

  final StreamController<List<ServiceForm>> _formsStreamController =
      StreamController<List<ServiceForm>>.broadcast();
  Stream<List<ServiceForm>> get formsListStream =>
      _formsStreamController.stream;

  final StreamController<List<LocalUserAccount>>
      _localAccountsStreamController =
      StreamController<List<LocalUserAccount>>.broadcast();
  Stream<List<LocalUserAccount>> get localAccountsStream =>
      _localAccountsStreamController.stream;

  // ignore: unnecessary_getters_setters
  Map<String, FirefighterUser> get userCache => _userCache;
  // ignore: unnecessary_getters_setters
  List<ServiceForm> get formsQueue => _formsQueue;
  List<LocalUserAccount> get localAccounts => _localAccounts;

  set userCache(Map<String, FirefighterUser> userCache) {
    _userCache = userCache;
  }

  set formsQueue(List<ServiceForm> formsQueue) {
    _formsQueue = formsQueue;
  }

  bool get isLoggedIn => _userId != null && _userId!.isNotEmpty;

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

  Future<void> loadLocalAccounts() async {
    _localAccounts = await DatabaseService.instance.getLocalAccounts();
    _localAccountsStreamController.add(_localAccounts);
  }

  Future<void> registerOrUpdateCurrentLocalAccount() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final currentSession = Supabase.instance.client.auth.currentSession;
    if (currentUser == null) return;

    final uId = currentUser.id;
    final uEmail = currentUser.email ?? '';
    final refreshToken = currentSession?.refreshToken;

    // Fetch or use self user info
    FirefighterUser? selfUser = _userCache[uId];
    if (selfUser == null) {
      try {
        await refreshUsers();
        selfUser = _userCache[uId];
      } catch (e) {
        // Fallback
      }
    }

    final account = LocalUserAccount(
      userId: uId,
      email: uEmail,
      givenName: selfUser?.givenName ?? 'Bombero',
      firstSurname: selfUser?.firstSurname ?? 'Local',
      secondSurname: selfUser?.secondSurname,
      role: selfUser?.role ?? 0,
      refreshToken: refreshToken,
      lastLoginAt: DateTime.now(),
      isSessionValid: true,
    );

    await DatabaseService.instance.saveLocalAccount(account);
    await loadLocalAccounts();
  }

  void setFormsFromDisk(
    List<ServiceForm> queueForms,
    List<ServiceForm> allForms,
  ) {
    _formsQueue = List.from(queueForms);
    _formsList = List.from(allForms);
    _formsStreamController.add(formsList);
  }

  Future<void> switchActiveUser(String targetUserId) async {
    Logging(
      "Iniciando cambio atómico al usuario $targetUserId...",
      caller: "Settings (switchActiveUser)",
      attentionLevel: 2,
    );

    ServiceReliabilityEngineer.instance.resetQueue();
    await ServiceReliabilityEngineer.instance.lockAndFlush();

    // 1. Clear current in-memory caches
    _userCache.clear();
    _formsQueue.clear();
    _formsList.clear();

    // 2. Switch database connection in DatabaseService
    await DatabaseService.instance.switchUserDatabase(targetUserId);

    // 3. Set active user ID
    _userId = targetUserId;
    await DatabaseService.instance.setAppState('userId', targetUserId);

    // 4. Restore Supabase JWT session if online and refresh token exists
    final account = await DatabaseService.instance.getLocalAccount(targetUserId);
    final isOnline = await ConnectionHeuristic().evaluate();

    if (isOnline &&
        account != null &&
        account.refreshToken != null &&
        account.refreshToken!.isNotEmpty) {
      try {
        final res = await Supabase.instance.client.auth
            .setSession(account.refreshToken!);
        if (res.session != null) {
          _isSessionValid = true;
          // Update refresh token if rotated
          if (res.session!.refreshToken != null &&
              res.session!.refreshToken != account.refreshToken) {
            final updatedAccount = account.copyWith(
              refreshToken: res.session!.refreshToken,
              lastLoginAt: DateTime.now(),
              isSessionValid: true,
            );
            await DatabaseService.instance.saveLocalAccount(updatedAccount);
          }
        }
      } on AuthException catch (e) {
        Logging(
          "Token no válido o revocado en la nube para $targetUserId: ${e.message}",
          caller: "Settings (switchActiveUser)",
          attentionLevel: 3,
        );
        _isSessionValid = false;
        final updatedAccount = account.copyWith(isSessionValid: false);
        await DatabaseService.instance.saveLocalAccount(updatedAccount);
      } catch (e) {
        Logging(
          "Red no disponible al conmutar usuario $targetUserId: $e. Manteniendo sesión local activa.",
          caller: "Settings (switchActiveUser)",
          attentionLevel: 1,
        );
        _isSessionValid = true;
      }
    } else {
      // Offline: Instant local switch (< 5ms) without blocking HTTP network call
      _isSessionValid = account?.isSessionValid ?? true;
    }

    // 5. Enqueue SRE reload and sync tasks for new user
    ServiceReliabilityEngineer.instance.enqueueTasks({
      "LoadFromDisk",
      "RefreshUsers",
      "SetForms",
      "SyncForms",
    });

    await loadLocalAccounts();

    // 6. Notify stream controllers
    _userCacheStreamController.add(_userCache);
    _formsStreamController.add(formsList);
  }

  Future<bool> removeLocalAccountWithAuth(
    String targetUserId,
    String password,
  ) async {
    final account = await DatabaseService.instance.getLocalAccount(targetUserId);
    if (account == null) return false;

    try {
      // Re-authenticate credentials against Supabase online
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: account.email,
        password: password,
      );

      if (res.user?.id == targetUserId) {
        await DatabaseService.instance.removeLocalAccount(targetUserId);
        await loadLocalAccounts();

        // If the removed account was active, clear active user ID or switch to remaining account
        if (_userId == targetUserId) {
          if (_localAccounts.isNotEmpty) {
            await switchActiveUser(_localAccounts.first.userId);
          } else {
            _userId = null;
            await DatabaseService.instance.setAppState('userId', '');
          }
        }
        return true;
      }
    } catch (e) {
      Logging(
        "Fallo de re-autenticación al eliminar cuenta local: $e",
        caller: "Settings (removeLocalAccountWithAuth)",
        attentionLevel: 3,
      );
    }
    return false;
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
            Map<String, dynamic> map = {
              'userId': Settings.instance.userId,
              'allowDebugging': Settings.instance.allowDebugging,
            };
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
      await registerOrUpdateCurrentLocalAccount();
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
      final remoteForms = formRecords
          .map((value) => ServiceForm.fromJson(value))
          .toList();
      await DatabaseService.instance.saveRemoteForms(remoteForms);
      _formsList = await DatabaseService.instance.getAllForms();
      _formsStreamController.add(formsList);
    } catch (e) {
      Logging(
        "Error intentando actualizar formularios: $e",
        caller: "Settings (setForms)",
        attentionLevel: 2,
      );
    }
  }

  void setUserId() {
    _userId = Supabase.instance.client.auth.currentUser!.id;
    DatabaseService.instance.setAppState('userId', _userId!);
    DatabaseService.instance.switchUserDatabase(_userId!);
  }

  Future<FirefighterUser> fetchUser({String? pUserId}) async {
    pUserId ??= _userId!;
    await refreshUsers();
    return _userCache[pUserId]!;
  }

  Future<bool> isTemplateAvailable(int id) async {
    return (await DatabaseService.instance.getTemplate(id)) != null;
  }

  Future<Map<String, dynamic>> getTemplate(int id) async {
    final cached = await DatabaseService.instance.getTemplate(id);
    if (cached != null) return cached;

    final template = await fetchTemplate(id: id);
    await DatabaseService.instance.saveTemplate(id, template.$2());
    return template.$2();
  }

  Future<int?> getNewestSavedTemplate() async {
    try {
      int? newest = await DatabaseService.instance.getNewestSavedTemplateId();
      if (newest == null) {
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
      final savedIds = await DatabaseService.instance.getSavedTemplateIds();
      for (var tId in savedIds) {
        final template = await fetchTemplate(id: tId);
        await DatabaseService.instance.saveTemplate(tId, template.$2());
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
      await DatabaseService.instance.saveUsers(_userCache);
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
      final content = template.$2();
      final tId = content['id'] as int? ?? 1;
      if (await isTemplateAvailable(tId)) return;
      await DatabaseService.instance.saveTemplate(tId, content);
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

    await DatabaseService.instance.saveForm(form);

    ServiceReliabilityEngineer.instance.enqueueTasks({"SyncForms"});
    _formsStreamController.add(formsList);
  }

  Future<void> dequeueForm(String id) async {
    _formsQueue.removeWhere((f) => f.id == id);

    await DatabaseService.instance.deleteForm(id);

    _formsStreamController.add(formsList);
  }

  Future<bool> uploadForm(ServiceForm form) async {
    if (!isCloudAuthAligned) {
      Logging(
        "Ignorando envío de formulario ${form.id}: La identidad del usuario autenticado en la nube no coincide con el usuario activo local.",
        caller: "Settings (uploadForm)",
        attentionLevel: 2,
      );
      return false;
    }

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
    if (!isCloudAuthAligned) {
      Logging(
        "Sincronización omitida: La sesión autenticada en la nube no está alineada con el usuario activo local.",
        caller: "Settings (syncForms)",
        attentionLevel: 2,
      );
      return;
    }

    final syncCandidates = List<ServiceForm>.from(
      _formsQueue.where((f) => f.status == 1),
    );

    for (var syncing in syncCandidates) {
      if (!(await uploadForm(syncing))) {
        throw Exception("Fallo de envío en formulario ${syncing.id} por problema de conexión.");
      }
    }

    ServiceReliabilityEngineer.instance.enqueueTasks({"SetForms"});
  }

  Future<void> deleteForm(ServiceForm form) async {
    try {
      if (form.status == 2 && isCloudAuthAligned) {
        await Supabase.instance.client.rpc(
          'delete_filled_in',
          params: {'p_id': form.id},
        );
      }
      await DatabaseService.instance.deleteForm(form.id);
      _formsQueue.removeWhere((f) => f.id == form.id);
      ServiceReliabilityEngineer.instance.enqueueTasks({"SetForms"});
      _formsStreamController.add(formsList);
    } catch (error) {
      // no importa si no se borra, mejor para nosotros.
    }
  }
}
