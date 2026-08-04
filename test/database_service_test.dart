import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bomberos/models/database_service.dart';
import 'package:bomberos/models/form.dart';
import 'package:bomberos/models/local_account.dart';
import 'package:bomberos/models/user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('DatabaseService initializes tables and CRUD operations work correctly', () async {
    final db = await DatabaseService.instance.globalDatabase;
    expect(db.isOpen, isTrue);

    // Test app_state CRUD
    await DatabaseService.instance.setAppState('test_key', 'test_val');
    final val = await DatabaseService.instance.getAppState('test_key');
    expect(val, equals('test_val'));

    // Test Local User Accounts CRUD
    final account1 = LocalUserAccount(
      userId: 'usr-1',
      email: 'juan@bomberos.org',
      givenName: 'Juan',
      firstSurname: 'Pérez',
      secondSurname: 'Gómez',
      role: 0,
      refreshToken: 'tok-123',
      lastLoginAt: DateTime.now(),
    );
    await DatabaseService.instance.saveLocalAccount(account1);
    final accounts = await DatabaseService.instance.getLocalAccounts();
    expect(accounts.any((a) => a.userId == 'usr-1'), isTrue);

    // Test User & Form CRUD in isolated user DB
    await DatabaseService.instance.switchUserDatabase('usr-1');
    final user = FirefighterUser(
      id: 'usr-1',
      givenName: 'Juan',
      firstSurname: 'Pérez',
      secondSurname: 'Gómez',
      role: 0,
    );
    await DatabaseService.instance.saveUsers({'usr-1': user});
    final users = await DatabaseService.instance.getUsers();
    expect(users.containsKey('usr-1'), isTrue);
    expect(users['usr-1']!.fullName, equals('Juan Pérez Gómez'));

    // Test Form CRUD & Local Precedence Guard
    final formDraft = ServiceForm(
      'form-1',
      1,
      'usr-1',
      DateTime.now(),
      {'campo1': 'respuesta'},
      0, // Draft
    );

    await DatabaseService.instance.saveForm(formDraft);
    final queue = await DatabaseService.instance.getFormsQueue();
    expect(queue.length, equals(1));
    expect(queue.first.id, equals('form-1'));

    // Attempt to overwrite local draft with remote synced form
    final remoteForm = ServiceForm(
      'form-1',
      1,
      'usr-1',
      DateTime.now(),
      {'campo1': 'overwrite_attempt'},
      2, // Synced status
    );

    await DatabaseService.instance.saveRemoteForms([remoteForm]);

    // Local draft MUST be preserved (WHERE status = 2 guard)
    final formsAfterRemoteSync = await DatabaseService.instance.getFormsQueue();
    expect(formsAfterRemoteSync.first.content['campo1'], equals('respuesta'));

    // Test Multi-DB User Isolation: Switch to usr-2, form-1 MUST NOT exist in usr-2 DB
    await DatabaseService.instance.switchUserDatabase('usr-2');
    final usr2Forms = await DatabaseService.instance.getAllForms();
    expect(usr2Forms.isEmpty, isTrue);

    // Switch back to usr-1, form-1 MUST still exist
    await DatabaseService.instance.switchUserDatabase('usr-1');
    final usr1Forms = await DatabaseService.instance.getAllForms();
    expect(usr1Forms.length, equals(1));

    // Cleanup
    await DatabaseService.instance.deleteForm('form-1');
    final emptyQueue = await DatabaseService.instance.getFormsQueue();
    expect(emptyQueue.isEmpty, isTrue);
  });

  test('Legacy JSON migration correctly imports user profiles and filled-in forms into per-user DB', () async {
    // Create mock legacy directory structure
    final settingsDir = Directory('./settings');
    final formsDir = Directory('./forms');
    final frapDir = Directory('./frap');

    if (!await settingsDir.exists()) await settingsDir.create();
    if (!await formsDir.exists()) await formsDir.create();
    if (!await frapDir.exists()) await frapDir.create();

    // Create mock user_data.json
    final userDataFile = File('./settings/user_data.json');
    await userDataFile.writeAsString('{"userId": "legacy-usr-999", "allowDebugging": true}');

    // Create mock user_cache.json
    final userCacheFile = File('./settings/user_cache.json');
    await userCacheFile.writeAsString('''
    {
      "legacy-usr-999": {
        "id": "legacy-usr-999",
        "givenName": "Carlos",
        "firstSurname": "Mendoza",
        "secondSurname": "Soto",
        "role": 1,
        "watchedByUserId": null,
        "watchesUsersId": []
      }
    }
    ''');

    // Create mock legacy template
    final templateFile = File('./frap/1.json');
    await templateFile.writeAsString('{"id": 1, "title": "Parte General"}');

    // Create mock legacy filled-in form
    final legacyFormFile = File('./forms/legacy-form-100.json');
    final legacyForm = ServiceForm(
      'legacy-form-100',
      1,
      'legacy-usr-999',
      DateTime.now(),
      {'motivo': 'Incendio vehicular'},
      0, // Draft
    );
    await legacyFormFile.writeAsString(jsonEncode(legacyForm.toJson()));

    // Run migration
    await DatabaseService.instance.migrateLegacyFilesIfNeeded();

    // Verify app_state migrated
    final migratedUserId = await DatabaseService.instance.getAppState('userId');
    expect(migratedUserId, equals('legacy-usr-999'));

    // Verify local_user_accounts registered
    final accounts = await DatabaseService.instance.getLocalAccounts();
    expect(accounts.any((a) => a.userId == 'legacy-usr-999'), isTrue);

    // Verify template migrated
    final templateContent = await DatabaseService.instance.getTemplate(1);
    expect(templateContent != null, isTrue);

    // Switch to legacy user DB and verify user profiles & form queue
    await DatabaseService.instance.switchUserDatabase('legacy-usr-999');
    final users = await DatabaseService.instance.getUsers();
    expect(users.containsKey('legacy-usr-999'), isTrue);
    expect(users['legacy-usr-999']!.fullName, equals('Carlos Mendoza Soto'));

    final forms = await DatabaseService.instance.getFormsQueue();
    expect(forms.any((f) => f.id == 'legacy-form-100'), isTrue);
    expect(forms.firstWhere((f) => f.id == 'legacy-form-100').content['motivo'], equals('Incendio vehicular'));

    // Cleanup mock directories
    if (await settingsDir.exists()) await settingsDir.delete(recursive: true);
    if (await formsDir.exists()) await formsDir.delete(recursive: true);
    if (await frapDir.exists()) await frapDir.delete(recursive: true);
  });
}
