import 'dart:convert';
import 'dart:io';
import 'package:bomberos/models/form.dart';
import 'package:bomberos/models/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ColorsSettings {
  final Color primary = Color.fromRGBO(98, 19, 51, 1.0);
  final Color background = CupertinoColors.white;
  final Color primaryContrast = Color.fromRGBO(231, 210, 149, 1.0);
  final Color textOverPrimary = CupertinoColors.white;
  final Color attentionBadge = CupertinoColors.activeOrange;
}

class Settings {
  static final Settings instance = Settings._internal();

  Settings._internal();

  factory Settings() {
    return instance;
  }

  final ColorsSettings colors = ColorsSettings();

  String? userId;
  int role = 0;

  Map<String, FirefighterUser> userCache = {};
  List<ServiceForm> _formsQueue = [];
  List<ServiceForm> _formsList = [];

  bool get isLoggedIn => userId != null && userCache.containsKey(userId);

  FirefighterUser? get self => userCache[userId];
  FirefighterUser? get watcher => userCache[self?.watchedByUserId ?? ""];

  List<ServiceForm> get formsList =>
      _formsQueue +
      (_formsList..retainWhere(
        (fl) => _formsQueue.indexWhere((fq) => fq.id == fl.id) == -1,
      ));

  Future<void> setUser() async {
    setUserId();
    await getUser();
    role = self!.role;
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
    userId = Supabase.instance.client.auth.currentUser!.id;
  }

  FirefighterUser getUserOrFail({String? pUserId}) {
    return userCache[pUserId]!;
  }

  Future<FirefighterUser> getUser({String? pUserId}) async {
    pUserId ??= userId!;
    if (userCache.containsKey(pUserId)) return userCache[pUserId]!;
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
    userCache[pUserId] = user;

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
        userCache[watcherId] = watcherUser;
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
        userCache[wId] = underWatchUser;
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
    final syncCandidates = List<ServiceForm>.from(_formsQueue.where((f) => f.status == 1));

    for (var syncing in syncCandidates) {
      if (!(await uploadForm(syncing))) {
        return;
      }
    }

    try {
      await setForms();
    } catch (error) {}
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
        'userId': userId,
        'role': role,
        'userCache': userCache.map(
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

        userId = jsonMap['userId'];
        role = jsonMap['role'] ?? 0;

        Map<String, dynamic> cacheMap = Map<String, dynamic>.from(
          jsonMap['userCache'] ?? {},
        );

        Map<String, dynamic> queueMap = Map<String, dynamic>.from(
          jsonMap['formsQueue'] ?? {},
        );

        userCache = cacheMap.map(
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
