import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bomberos/models/database_service.dart';
import 'package:bomberos/models/form.dart';
import 'package:bomberos/models/user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('DatabaseService initializes tables and CRUD operations work correctly', () async {
    final db = await DatabaseService.instance.database;
    expect(db.isOpen, isTrue);

    // Test app_state CRUD
    await DatabaseService.instance.setAppState('test_key', 'test_val');
    final val = await DatabaseService.instance.getAppState('test_key');
    expect(val, equals('test_val'));

    // Test User CRUD
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

    // Cleanup
    await DatabaseService.instance.deleteForm('form-1');
    final emptyQueue = await DatabaseService.instance.getFormsQueue();
    expect(emptyQueue.isEmpty, isTrue);
  });
}
