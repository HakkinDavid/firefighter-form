import 'dart:convert';
import 'dart:io';
import 'package:bomberos/models/SRE/service_reliability_engineer.dart';
import 'package:bomberos/models/form.dart';
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

  String? _userId;
  int _role = 0;

  String get userId => _userId ?? '';
  int get role => _role;
  set userId(String userId) {
    // Maybe check with regex that the id format is correct
    _userId = userId;
  }
  set role(int role) {
    _role = (role >= 0 && role <= 2)
        ? role
        : 0;
  }

  Map<String, FirefighterUser> _userCache = {};
  List<ServiceForm> _formsQueue = [];
  List<ServiceForm> _formsList = [];

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

  List<ServiceForm> get formsList =>
      _formsQueue +
      (_formsList..retainWhere(
        (fl) => _formsQueue.indexWhere((fq) => fq.id == fl.id) == -1,
      ));

  Future<void> setUser() async {
    setUserId();
    await getUser();
    _role = self!.role;
    await saveToDisk();
  }

  Future<void> setForms() async {
    final formRecords = await Supabase.instance.client
        .from('filled_in')
        .select('*');
    _formsList = formRecords
        .asMap()
        .map((key, value) => MapEntry(key, ServiceForm.fromJson(value)))
        .values
        .toList();
  }

  void setUserId() {
    _userId = Supabase.instance.client.auth.currentUser!.id;
  }

  FirefighterUser getUserOrFail({String? pUserId}) {
    return _userCache[pUserId]!;
  }

  Future<FirefighterUser> getUser({String? pUserId}) async {
    pUserId ??= _userId!;
    if (_userCache.containsKey(pUserId)) return _userCache[pUserId]!;
    final nameRecord = await Supabase.instance.client
        .from('user_name')
        .select('id, given, surname1, surname2')
        .eq('id', pUserId)
        .maybeSingle();

    final roleRecord = await Supabase.instance.client
        .from('user_role')
        .select('id, value')
        .eq('id', pUserId)
        .maybeSingle();

    if (nameRecord == null || roleRecord == null) throw Error();

    final watchedByRecord = await Supabase.instance.client
        .from('user_hierarchy')
        .select('id, watched_by')
        .eq('id', pUserId)
        .maybeSingle();

    final watchesRecord = await Supabase.instance.client
        .from('user_hierarchy')
        .select('id')
        .eq('watched_by', pUserId);

    Set<String> watchesUsersId = {};
    for (var w in watchesRecord) {
      watchesUsersId.add(w['id']);
    }

    final user = FirefighterUser(
      id: pUserId,
      givenName: nameRecord['given'],
      firstSurname: nameRecord['surname1'],
      secondSurname: nameRecord['surname2'],
      role: roleRecord['value'],
      watchedByUserId: watchedByRecord?['watched_by'],
      watchesUsersId: watchesUsersId,
    );
    _userCache[pUserId] = user;

    // Watcher User logic
    if (watchedByRecord != null) {
      final watcherId = watchedByRecord['watched_by'];

      final watcherNameRecord = await Supabase.instance.client
          .from('user_name')
          .select('id, given, surname1, surname2')
          .eq('id', watcherId)
          .maybeSingle();

      if (watcherNameRecord != null) {
        // If tables are correct
        final watcherUser = FirefighterUser(
          id: watcherId,
          givenName: watcherNameRecord['given'],
          firstSurname: watcherNameRecord['surname1'],
          secondSurname: watcherNameRecord['surname2'],
          role: roleRecord['value'] + 1, // obviously wrong, check later
        );
        _userCache[watcherId] = watcherUser;
      }
    }

    // Subordinate Users logic
    for (var wId in watchesUsersId) {
      var underWatchNameRecord = await Supabase.instance.client
          .from('user_name')
          .select('id, given, surname1, surname2')
          .eq('id', wId)
          .maybeSingle();

      var underWatchRoleRecord = await Supabase.instance.client
          .from('user_role')
          .select('id, value')
          .eq('id', wId)
          .maybeSingle();

      if (underWatchNameRecord != null && underWatchRoleRecord != null) {
        // If tables are correct
        FirefighterUser underWatchUser = FirefighterUser(
          id: wId,
          givenName: underWatchNameRecord['given'],
          firstSurname: underWatchNameRecord['surname1'],
          secondSurname: underWatchNameRecord['surname2'],
          role: underWatchRoleRecord['value'],
          watchedByUserId: pUserId,
        );
        _userCache[wId] = underWatchUser;
      }
    }
    return user;
  }

  Future<bool> isTemplateAvailable(int id) async {
    return await File(await getTemplateRoute(id)).exists();
  }

  Future<Map<String, dynamic>> getTemplate(int id) async {
    if (!(await isTemplateAvailable(id))) await fetchTemplate(id: id);
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
        await updateTemplates();
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

  Future<void> updateTemplates() async {
    try {
      await fetchTemplate();
    } catch (e) {
      // yo cuando hago algo
    }
  }

  Future<void> fetchTemplate({int? id}) async {
    late final File templateFile;
    Map<String, dynamic>? template;

    if (id != null) {
      templateFile = File(await getTemplateRoute(id));
    } else {
      template = await getTemplateRecord();
      templateFile = File(await getTemplateRoute(template['id']));
    }
    if (await templateFile.exists()) return;
    template ??= await getTemplateRecord(tId: id);
    await templateFile.create(recursive: true);
    await templateFile.writeAsString(jsonEncode(template['content']));
  }

  // This will be an actual function later
  Future<void> uploadTemplate() async {
    return;
  }

  Future<void> enqueueForm(ServiceForm form) async {
    int index = _formsQueue.indexWhere((f) => f.id == form.id);
    if (index == -1) {
      _formsQueue.add(form);
    } else {
      _formsQueue[index] = form;
    }
    await saveToDisk();
    ServiceReliabilityEngineer.instance.enqueueTasks({"syncForms"});
  }

  Future<void> dequeueForm(String id) async {
    _formsQueue.removeWhere((f) => f.id == id);
    await saveToDisk();
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

    // try {
    //   await setForms();
    // } catch (error) { }
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
      await setForms();
    } catch (error) {}
  }

  Future<void> saveToDisk() async {
    try {
      final file = File(
        '${(await getApplicationDocumentsDirectory()).path}/settings.json',
      );

      Map<String, dynamic> jsonMap = {
        'userId': _userId,
        'role': _role,
        '_userCache': _userCache.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
        'formsQueue': _formsQueue.asMap().map(
          (key, value) => MapEntry('$key', value.toJson()),
        ),
      };

      final jsonString = jsonEncode(jsonMap);
      await file.writeAsString(jsonString);
    } catch (e) {}
  }

  Future<void> loadFromDisk() async {
    try {
      final file = File(
        '${(await getApplicationDocumentsDirectory()).path}/settings.json',
      );

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

        _userId = jsonMap['userId'];
        _role = jsonMap['role'] ?? 0;

        Map<String, dynamic> cacheMap = Map<String, dynamic>.from(
          jsonMap['_userCache'] ?? {},
        );

        Map<String, dynamic> queueMap = Map<String, dynamic>.from(
          jsonMap['formsQueue'] ?? {},
        );

        _userCache = cacheMap.map(
          (key, value) => MapEntry(key, FirefighterUser.fromJson(value)),
        );
        _formsQueue = queueMap
            .map((key, value) => MapEntry(key, ServiceForm.fromJson(value)))
            .values
            .toList();
      }
    } catch (e) {}
  }
}
