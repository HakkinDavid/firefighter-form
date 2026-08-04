import 'dart:convert';
import 'dart:io';
import 'package:bomberos/models/form.dart';
import 'package:bomberos/models/local_account.dart';
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

  Future<Database> get database async => await globalDatabase;

  Future<Database> get globalDatabase async {
    if (_globalDb != null) return _globalDb!;
    _globalDb = await _initGlobalDatabase();
    return _globalDb!;
  }

  Future<Database?> get userDatabase async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return null;
    if (_userDb != null) return _userDb!;
    _userDb = await _initUserDatabase(_currentUserId!);
    return _userDb!;
  }

  String? get currentUserId => _currentUserId;

  Future<Database> _initGlobalDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'bomberos_global.db');

    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        // Dictionaries
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

        // Seed dictionaries
        await db.execute(
          "INSERT INTO dict_roles (id, name) VALUES (0, 'bombero'), (1, 'supervisor'), (2, 'administrador');",
        );
        await db.execute(
          "INSERT INTO dict_form_status (id, name) VALUES (0, 'borrador'), (1, 'finalizado'), (2, 'sincronizado');",
        );

        // Global Templates
        await db.execute('''
          CREATE TABLE template (
            id INTEGER PRIMARY KEY,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            uploader TEXT
          );
        ''');

        // Global Client Application State
        await db.execute('''
          CREATE TABLE app_state (
            key TEXT PRIMARY KEY,
            value TEXT
          );
        ''');

        // Local Accounts Registry
        await db.execute('''
          CREATE TABLE local_user_accounts (
            user_id TEXT PRIMARY KEY,
            email TEXT NOT NULL,
            given_name TEXT NOT NULL,
            first_surname TEXT NOT NULL,
            second_surname TEXT,
            role INTEGER NOT NULL DEFAULT 0,
            refresh_token TEXT,
            last_login_at TEXT NOT NULL,
            is_session_valid INTEGER NOT NULL DEFAULT 1
          );
        ''');
      },
    );

    // Execute one-time legacy migration if legacy files or legacy bomberos.db exist
    await _migrateLegacyFilesIfNeeded(db);

    return db;
  }

  Future<Database> _initUserDatabase(String userId) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final usersDir = Directory(p.join(docsDir.path, 'users'));
    if (!await usersDir.exists()) {
      await usersDir.create(recursive: true);
    }
    final dbPath = p.join(usersDir.path, 'user_$userId.db');

    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        // User names, roles, and hierarchy cache
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
            id TEXT PRIMARY KEY,
            value INTEGER NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE user_hierarchy (
            id TEXT PRIMARY KEY,
            watched_by TEXT
          );
        ''');

        // Forms filled by or visible to this user session
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

    return db;
  }

  Future<void> switchUserDatabase(String userId) async {
    if (_currentUserId == userId && _userDb != null) return;

    if (_userDb != null) {
      await _userDb!.close();
      _userDb = null;
    }

    _currentUserId = userId;
    if (userId.isNotEmpty) {
      _userDb = await _initUserDatabase(userId);
    }
    Logging(
      "Base de datos cambiada al usuario: $userId",
      caller: "DatabaseService (switchUserDatabase)",
    );
  }

  // === LEGACY ONE-TIME MIGRATION ===
  Future<void> _migrateLegacyFilesIfNeeded(Database globalDb) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final oldSingleDbPath = p.join(docsDir.path, 'bomberos.db');
      final settingsDir = Directory(p.join(docsDir.path, 'settings'));
      final templatesDir = Directory(p.join(docsDir.path, 'frap'));

      final oldDbFile = File(oldSingleDbPath);
      final hasOldDb = await oldDbFile.exists();
      final hasSettingsDir = await settingsDir.exists();
      final hasTemplatesDir = await templatesDir.exists();

      if (!hasOldDb && !hasSettingsDir && !hasTemplatesDir) {
        return;
      }

      Logging(
        "Iniciando migración legacy a arquitectura multi-base de datos...",
        caller: "DatabaseService (_migrateLegacyFilesIfNeeded)",
        attentionLevel: 2,
      );

      String? activeUserId;

      // 1. If old bomberos.db exists, migrate its contents
      if (hasOldDb) {
        try {
          final oldDb = await openDatabase(oldSingleDbPath);
          final appStates = await oldDb.query('app_state');
          for (var r in appStates) {
            await globalDb.insert('app_state', r,
                conflictAlgorithm: ConflictAlgorithm.replace);
            if (r['key'] == 'userId') {
              activeUserId = r['value'] as String?;
            }
          }

          final templates = await oldDb.query('template');
          for (var t in templates) {
            await globalDb.insert('template', t,
                conflictAlgorithm: ConflictAlgorithm.replace);
          }

          if (activeUserId != null && activeUserId.isNotEmpty) {
            final userDb = await _initUserDatabase(activeUserId);

            final names = await oldDb.query('user_name');
            for (var r in names) {
              await userDb.insert('user_name', r,
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
            final roles = await oldDb.query('user_role');
            for (var r in roles) {
              await userDb.insert('user_role', r,
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
            final hierarchies = await oldDb.query('user_hierarchy');
            for (var r in hierarchies) {
              await userDb.insert('user_hierarchy', r,
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
            final forms = await oldDb.query('filled_in');
            for (var r in forms) {
              await userDb.insert('filled_in', r,
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }

            // Create initial local_user_account for active user
            final activeUserRow =
                names.firstWhere((element) => element['id'] == activeUserId,
                    orElse: () => {
                          'id': activeUserId,
                          'given': 'Usuario',
                          'surname1': 'Local',
                        });
            final roleRow = roles.firstWhere(
                (element) => element['id'] == activeUserId,
                orElse: () => {'value': 0});

            await globalDb.insert(
              'local_user_accounts',
              {
                'user_id': activeUserId,
                'email': '',
                'given_name': activeUserRow['given'] ?? 'Usuario',
                'first_surname': activeUserRow['surname1'] ?? 'Local',
                'second_surname': activeUserRow['surname2'],
                'role': roleRow['value'] ?? 0,
                'refresh_token': null,
                'last_login_at': DateTime.now().toIso8601String(),
                'is_session_valid': 1,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          await oldDb.close();
          await oldDbFile.delete();
          Logging("Migración desde bomberos.db completada exitosamente.",
              caller: "DatabaseService", attentionLevel: 2);
        } catch (e) {
          Logging("Error migrando desde bomberos.db antigua: $e",
              caller: "DatabaseService", attentionLevel: 3);
        }
      }

      // 2. Migrate legacy JSON directories if present
      if (hasSettingsDir || hasTemplatesDir) {
        final userDataFile = File(p.join(settingsDir.path, 'user_data.json'));
        if (await userDataFile.exists()) {
          try {
            final content = await userDataFile.readAsString();
            final map = jsonDecode(content) as Map<String, dynamic>;
            if (map.containsKey('userId') && map['userId'] != null) {
              activeUserId = map['userId'].toString();
              await globalDb.insert('app_state',
                  {'key': 'userId', 'value': activeUserId},
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
            if (map.containsKey('allowDebugging')) {
              await globalDb.insert('app_state',
                  {'key': 'allowDebugging', 'value': map['allowDebugging'].toString()},
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
          } catch (e) {
            Logging("Error migrando user_data.json: $e",
                caller: "DatabaseService", attentionLevel: 3);
          }
        }

        if (hasTemplatesDir) {
          try {
            await for (var entity in templatesDir.list()) {
              if (entity is File && entity.path.endsWith('.json')) {
                final filename = p.basenameWithoutExtension(entity.path);
                final tId = int.tryParse(filename);
                if (tId != null) {
                  final tContent = await entity.readAsString();
                  await globalDb.insert('template', {
                    'id': tId,
                    'content': tContent,
                    'created_at': DateTime.now().toIso8601String(),
                  }, conflictAlgorithm: ConflictAlgorithm.replace);
                }
              }
            }
          } catch (e) {
            Logging("Error migrando plantillas JSON: $e",
                caller: "DatabaseService", attentionLevel: 3);
          }
        }

        if (hasSettingsDir) {
          try {
            if (await settingsDir.exists()) {
              await settingsDir.delete(recursive: true);
            }
            if (await templatesDir.exists()) {
              await templatesDir.delete(recursive: true);
            }
          } catch (e) {
            // Ignorar errores de limpieza
          }
        }
      }
    } catch (e) {
      Logging("Error general en _migrateLegacyFilesIfNeeded: $e",
          caller: "DatabaseService", attentionLevel: 4);
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

  // === LOCAL USER ACCOUNTS CRUD (GLOBAL DB) ===
  Future<void> saveLocalAccount(LocalUserAccount account) async {
    final db = await globalDatabase;
    await db.insert('local_user_accounts', account.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<LocalUserAccount>> getLocalAccounts() async {
    final db = await globalDatabase;
    final results = await db.query('local_user_accounts', orderBy: 'last_login_at DESC');
    return results.map((r) => LocalUserAccount.fromMap(r)).toList();
  }

  Future<LocalUserAccount?> getLocalAccount(String userId) async {
    final db = await globalDatabase;
    final results =
        await db.query('local_user_accounts', where: 'user_id = ?', whereArgs: [userId]);
    if (results.isNotEmpty) {
      return LocalUserAccount.fromMap(results.first);
    }
    return null;
  }

  Future<void> removeLocalAccount(String userId) async {
    final global = await globalDatabase;
    await global.delete('local_user_accounts', where: 'user_id = ?', whereArgs: [userId]);

    // Close and remove the isolated database file for this user
    if (_currentUserId == userId && _userDb != null) {
      await _userDb!.close();
      _userDb = null;
      _currentUserId = null;
    }

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final userDbFile = File(p.join(docsDir.path, 'users', 'user_$userId.db'));
      if (await userDbFile.exists()) {
        await userDbFile.delete();
      }
    } catch (e) {
      Logging("Error al eliminar archivo de BD para usuario $userId: $e",
          caller: "DatabaseService (removeLocalAccount)", attentionLevel: 2);
    }
  }

  // === APP STATE CRUD (GLOBAL DB) ===
  Future<void> setAppState(String key, String value) async {
    final db = await globalDatabase;
    await db.insert('app_state', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getAppState(String key) async {
    final db = await globalDatabase;
    final results =
        await db.query('app_state', where: 'key = ?', whereArgs: [key]);
    if (results.isNotEmpty) {
      return results.first['value'] as String?;
    }
    return null;
  }

  // === USERS CACHE CRUD (USER DB) ===
  Future<void> saveUsers(Map<String, FirefighterUser> userCache) async {
    final uDb = await userDatabase;
    if (uDb == null) return;
    await uDb.transaction((txn) async {
      for (var u in userCache.values) {
        await _insertUserInTxn(txn, u);
      }
    });
  }

  Future<Map<String, FirefighterUser>> getUsers() async {
    final uDb = await userDatabase;
    if (uDb == null) return {};
    final names = await uDb.query('user_name');
    final roles = await uDb.query('user_role');
    final hierarchies = await uDb.query('user_hierarchy');

    final roleMap = {for (var r in roles) r['id'] as String: r['value'] as int};
    final watchedByMap = {
      for (var h in hierarchies) h['id'] as String: h['watched_by'] as String?
    };

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

  // === FORMS CRUD (USER DB) ===
  Future<void> saveForm(ServiceForm form) async {
    final uDb = await userDatabase;
    if (uDb == null) return;
    await uDb.insert('filled_in', {
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
    final uDb = await userDatabase;
    if (uDb == null) return;
    await uDb.transaction((txn) async {
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
    final uDb = await userDatabase;
    if (uDb == null) return;
    await uDb.delete('filled_in', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ServiceForm>> getFormsQueue() async {
    final uDb = await userDatabase;
    if (uDb == null) return [];
    final results = await uDb.query(
      'filled_in',
      where: 'status IN (0, 1)',
      orderBy: 'filled_at ASC',
    );
    return _parseFormList(results);
  }

  Future<List<ServiceForm>> getAllForms() async {
    final uDb = await userDatabase;
    if (uDb == null) return [];
    final results = await uDb.query(
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

  // === TEMPLATES CRUD (GLOBAL DB) ===
  Future<void> saveTemplate(int id, Map<String, dynamic> content,
      {String? uploader}) async {
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
