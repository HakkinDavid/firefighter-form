import 'dart:convert';
import 'dart:io';
import 'package:bomberos/models/form.dart';
import 'package:bomberos/models/logging.dart';
import 'package:bomberos/models/user.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();

  DatabaseService._internal();

  factory DatabaseService() => instance;

  Database? _globalDb;
  Database? _userDb;
  String? _currentUserId;

  Future<Database> get globalDatabase async {
    if (_globalDb != null && _globalDb!.isOpen) return _globalDb!;
    _globalDb = await _initGlobalDatabase();
    return _globalDb!;
  }

  Future<Database> getUserDatabase([String? userId]) async {
    final targetUserId = userId ?? _currentUserId;
    if (targetUserId == null || targetUserId.isEmpty) {
      throw StateError("No hay un userId activo para acceder a la base de datos de usuario.");
    }

    if (_userDb != null && _userDb!.isOpen && _currentUserId == targetUserId) {
      return _userDb!;
    }

    if (_userDb != null && _userDb!.isOpen) {
      await closeUserDatabase();
    }

    _currentUserId = targetUserId;
    _userDb = await _initUserDatabase(targetUserId);
    return _userDb!;
  }

  /// Backward compatible getter returning user database if user active, otherwise global database.
  Future<Database> get database async {
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      return getUserDatabase(_currentUserId);
    }
    return globalDatabase;
  }

  Future<void> closeUserDatabase() async {
    if (_userDb != null && _userDb!.isOpen) {
      await _userDb!.close();
    }
    _userDb = null;
    _currentUserId = null;
  }

  Future<Database> _initGlobalDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'global.db');

    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE dict_roles (
            id INTEGER PRIMARY KEY,
            name TEXT UNIQUE NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE dict_form_status (
            id INTEGER PRIMARY KEY,
            name TEXT UNIQUE NOT NULL
          );
        ''');

        await db.execute("INSERT INTO dict_roles (id, name) VALUES (0, 'bombero'), (1, 'supervisor'), (2, 'administrador');");
        await db.execute("INSERT INTO dict_form_status (id, name) VALUES (0, 'borrador'), (1, 'finalizado'), (2, 'sincronizado');");

        await db.execute('''
          CREATE TABLE template (
            id INTEGER PRIMARY KEY,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            uploader TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE app_state (
            key TEXT PRIMARY KEY,
            value TEXT
          );
        ''');
      },
    );

    return db;
  }

  Future<Database> _initUserDatabase(String userId) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final usersDir = Directory(p.join(docsDir.path, 'users'));
    if (!await usersDir.exists()) {
      await usersDir.create(recursive: true);
    }
    final dbPath = p.join(usersDir.path, '$userId.db');

    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE user_name (
            id TEXT PRIMARY KEY,
            given TEXT NOT NULL,
            surname1 TEXT NOT NULL,
            surname2 TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE user_role (
            id TEXT PRIMARY KEY REFERENCES user_name(id) ON DELETE CASCADE,
            value INTEGER NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE user_hierarchy (
            id TEXT PRIMARY KEY REFERENCES user_name(id) ON DELETE CASCADE,
            watched_by TEXT REFERENCES user_name(id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
          CREATE TABLE filled_in (
            id TEXT PRIMARY KEY,
            template_id INTEGER NOT NULL,
            filler TEXT NOT NULL,
            status INTEGER NOT NULL,
            content TEXT NOT NULL,
            filled_at TEXT NOT NULL
          );
        ''');
      },
    );

    await _migrateLegacyFilesIfNeeded(userId, db);

    return db;
  }

  // === LEGACY ONE-TIME MIGRATION ===
  Future<void> _migrateLegacyFilesIfNeeded(String userId, Database userDb) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final settingsDir = Directory(p.join(docsDir.path, 'settings'));
      final templatesDir = Directory(p.join(docsDir.path, 'frap'));

      if (!await settingsDir.exists() && !await templatesDir.exists()) {
        return;
      }

      Logging("Iniciando migración de archivos JSON legacy...", caller: "DatabaseService (_migrateLegacyFilesIfNeeded)", attentionLevel: 2);

      final gDb = await globalDatabase;

      // 1. Migrate user_data.json to global.db & userDb
      final userDataFile = File(p.join(settingsDir.path, 'user_data.json'));
      if (await userDataFile.exists()) {
        try {
          final content = await userDataFile.readAsString();
          final map = jsonDecode(content) as Map<String, dynamic>;
          if (map.containsKey('userId') && map['userId'] != null) {
            await gDb.insert('app_state', {'key': 'userId', 'value': map['userId'].toString()}, conflictAlgorithm: ConflictAlgorithm.replace);
          }
          if (map.containsKey('allowDebugging')) {
            await gDb.insert('app_state', {'key': 'allowDebugging', 'value': map['allowDebugging'].toString()}, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        } catch (e) {
          Logging("Error migrando user_data.json: $e", caller: "DatabaseService", attentionLevel: 3);
        }
      }

      // 2. Migrate frap/ (templates) to global.db
      if (await templatesDir.exists()) {
        try {
          await for (var entity in templatesDir.list()) {
            if (entity is File && entity.path.endsWith('.json')) {
              final filename = p.basenameWithoutExtension(entity.path);
              final tId = int.tryParse(filename);
              if (tId != null) {
                final tContent = await entity.readAsString();
                await gDb.insert('template', {
                  'id': tId,
                  'content': tContent,
                  'created_at': DateTime.now().toIso8601String(),
                }, conflictAlgorithm: ConflictAlgorithm.replace);
              }
            }
          }
        } catch (e) {
          Logging("Error migrando plantillas: $e", caller: "DatabaseService", attentionLevel: 3);
        }
      }

      // 3. Migrate user_cache.json and forms/ into users/{userId}.db
      await userDb.transaction((txn) async {
        final userCacheFile = File(p.join(settingsDir.path, 'user_cache.json'));
        if (await userCacheFile.exists()) {
          try {
            final content = await userCacheFile.readAsString();
            final map = jsonDecode(content) as Map<String, dynamic>;
            for (var entry in map.entries) {
              final uMap = entry.value as Map<String, dynamic>;
              final u = FirefighterUser.fromJson(uMap);
              await _insertUserInTxn(txn, u);
            }
          } catch (e) {
            Logging("Error migrando user_cache.json: $e", caller: "DatabaseService", attentionLevel: 3);
          }
        }

        final formsDir = Directory(p.join(settingsDir.path, 'forms'));
        if (await formsDir.exists()) {
          try {
            await for (var entity in formsDir.list()) {
              if (entity is File && entity.path.endsWith('.json')) {
                final formStr = await entity.readAsString();
                final formMap = jsonDecode(formStr) as Map<String, dynamic>;
                final form = ServiceForm.fromJson(formMap);
                await txn.insert('filled_in', {
                  'id': form.id,
                  'template_id': form.templateId,
                  'filler': form.filler,
                  'status': form.status,
                  'content': jsonEncode(form.content),
                  'filled_at': form.filledAt.toIso8601String(),
                }, conflictAlgorithm: ConflictAlgorithm.replace);
              }
            }
          } catch (e) {
            Logging("Error migrando formularios: $e", caller: "DatabaseService", attentionLevel: 3);
          }
        }
      });

      // Cleanup legacy JSON files/folders after successful migration
      try {
        if (await settingsDir.exists()) await settingsDir.delete(recursive: true);
        if (await templatesDir.exists()) await templatesDir.delete(recursive: true);
        Logging("Migración legacy completada y archivos antiguos eliminados correctamente.", caller: "DatabaseService", attentionLevel: 2);
      } catch (e) {
        Logging("Advertencia al eliminar archivos legacy: $e", caller: "DatabaseService", attentionLevel: 1);
      }
    } catch (e) {
      Logging("Error general en _migrateLegacyFilesIfNeeded: $e", caller: "DatabaseService", attentionLevel: 4);
    }
  }

  Future<void> _insertUserInTxn(DatabaseExecutor db, FirefighterUser u) async {
    await db.insert('user_name', {
      'id': u.id,
      'given': u.givenName,
      'surname1': u.firstSurname,
      'surname2': u.secondSurname,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('user_role', {
      'id': u.id,
      'value': u.role,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('user_hierarchy', {
      'id': u.id,
      'watched_by': u.watchedByUserId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // === APP STATE CRUD (Global DB) ===
  Future<void> setAppState(String key, String value) async {
    final db = await globalDatabase;
    await db.insert('app_state', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getAppState(String key) async {
    final db = await globalDatabase;
    final results = await db.query('app_state', where: 'key = ?', whereArgs: [key]);
    if (results.isNotEmpty) {
      return results.first['value'] as String?;
    }
    return null;
  }

  Future<void> deleteAppState(String key) async {
    final db = await globalDatabase;
    await db.delete('app_state', where: 'key = ?', whereArgs: [key]);
  }

  // === USERS CACHE CRUD (User DB) ===
  Future<void> saveUsers(Map<String, FirefighterUser> userCache) async {
    final db = await getUserDatabase();
    await db.transaction((txn) async {
      await txn.delete('user_hierarchy');
      await txn.delete('user_role');
      await txn.delete('user_name');
      for (var u in userCache.values) {
        await _insertUserInTxn(txn, u);
      }
    });
  }

  Future<Map<String, FirefighterUser>> getUsers() async {
    final db = await getUserDatabase();
    final names = await db.query('user_name');
    final roles = await db.query('user_role');
    final hierarchies = await db.query('user_hierarchy');

    final roleMap = {for (var r in roles) r['id'] as String: r['value'] as int};
    final watchedByMap = {for (var h in hierarchies) h['id'] as String: h['watched_by'] as String?};

    final Map<String, Set<String>> watcherMap = {};
    for (var h in hierarchies) {
      final watchedBy = h['watched_by'] as String?;
      final id = h['id'] as String;
      if (watchedBy != null && watchedBy.isNotEmpty) {
        watcherMap.putIfAbsent(watchedBy, () => <String>{}).add(id);
      }
    }

    final Map<String, FirefighterUser> result = {};
    for (var n in names) {
      final id = n['id'] as String;
      result[id] = FirefighterUser(
        id: id,
        givenName: n['given'] as String,
        firstSurname: n['surname1'] as String,
        secondSurname: n['surname2'] as String?,
        role: roleMap[id] ?? 0,
        watchedByUserId: watchedByMap[id],
        watchesUsersId: watcherMap[id] ?? <String>{},
      );
    }
    return result;
  }

  // === FORMS CRUD (User DB) ===
  Future<void> saveForm(ServiceForm form) async {
    final db = await getUserDatabase();
    await db.insert('filled_in', {
      'id': form.id,
      'template_id': form.templateId,
      'filler': form.filler,
      'status': form.status,
      'content': jsonEncode(form.content),
      'filled_at': form.filledAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Saves remote forms fetched from Supabase with Local Precedence Protection Guard.
  /// If a form exists locally with status 0 (draft) or status 1 (outbox pending upload),
  /// the remote form WILL NOT overwrite it.
  Future<void> saveRemoteForms(List<ServiceForm> remoteForms) async {
    final db = await getUserDatabase();
    await db.transaction((txn) async {
      for (var form in remoteForms) {
        await txn.rawInsert('''
          INSERT INTO filled_in (id, template_id, filler, status, content, filled_at)
          VALUES (?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            template_id = excluded.template_id,
            filler = excluded.filler,
            status = excluded.status,
            content = excluded.content,
            filled_at = excluded.filled_at
          WHERE filled_in.status = 2;
        ''', [
          form.id,
          form.templateId,
          form.filler,
          form.status,
          jsonEncode(form.content),
          form.filledAt.toIso8601String(),
        ]);
      }
    });
  }

  Future<void> deleteForm(String id) async {
    final db = await getUserDatabase();
    await db.delete('filled_in', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ServiceForm>> getFormsQueue() async {
    final db = await getUserDatabase();
    final results = await db.query(
      'filled_in',
      where: 'status IN (0, 1)',
      orderBy: 'filled_at ASC',
    );
    return _parseFormList(results);
  }

  Future<List<ServiceForm>> getAllForms() async {
    final db = await getUserDatabase();
    final results = await db.query(
      'filled_in',
      orderBy: 'filled_at DESC',
    );
    return _parseFormList(results);
  }

  List<ServiceForm> _parseFormList(List<Map<String, dynamic>> rows) {
    return rows.map((r) {
      final contentRaw = r['content'] as String;
      final contentMap = jsonDecode(contentRaw) as Map<String, dynamic>;
      return ServiceForm(
        r['id'] as String,
        r['template_id'] as int,
        r['filler'] as String,
        DateTime.parse(r['filled_at'] as String),
        contentMap,
        r['status'] as int,
      );
    }).toList();
  }

  // === TEMPLATES CRUD (Global DB) ===
  Future<void> saveTemplate(int id, Map<String, dynamic> content, {String? uploader}) async {
    final db = await globalDatabase;
    await db.insert('template', {
      'id': id,
      'content': jsonEncode(content),
      'created_at': DateTime.now().toIso8601String(),
      'uploader': uploader,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getTemplate(int id) async {
    final db = await globalDatabase;
    final results = await db.query('template', where: 'id = ?', whereArgs: [id]);
    if (results.isNotEmpty) {
      final contentStr = results.first['content'] as String;
      return jsonDecode(contentStr) as Map<String, dynamic>;
    }
    return null;
  }

  Future<int?> getNewestSavedTemplateId() async {
    final db = await globalDatabase;
    final result = await db.rawQuery('SELECT MAX(id) as max_id FROM template');
    if (result.isNotEmpty && result.first['max_id'] != null) {
      return result.first['max_id'] as int;
    }
    return null;
  }

  Future<List<int>> getSavedTemplateIds() async {
    final db = await globalDatabase;
    final results = await db.query('template', columns: ['id']);
    return results.map((r) => r['id'] as int).toList();
  }

}
