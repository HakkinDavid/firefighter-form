import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bomberos/models/database_service.dart';
import 'package:bomberos/models/form.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseService.instance.getUserDatabase('user-uuid-123');
  });

  group('Autosave Tests', () {
    test('form.set triggers debounced autosave state and flushAutosave persists to SQLite', () async {
      final form = ServiceForm(
        'test-form-1234567890',
        1,
        'user-uuid-123',
        DateTime.now(),
        {'paciente_nombre': 'Inicial'},
        0, // draft status
      );

      // Verify initial state
      expect(form.autosaveStatus.value, equals(AutosaveState.idle));
      expect(form.edited, isFalse);

      // Modify field
      form.set('paciente_nombre', 'Carlos Ruiz');

      // Modifying field marks form as edited and triggers autosave
      expect(form.content['paciente_nombre'], equals('Carlos Ruiz'));
      expect(form.edited, isTrue);

      // Immediately flush pending autosave
      await form.flushAutosave();

      expect(form.autosaveStatus.value, equals(AutosaveState.saved));
      expect(form.edited, isFalse);

      // Verify persistence in DatabaseService SQLite database
      final allForms = await DatabaseService.instance.getAllForms();
      final savedForm = allForms.firstWhere((f) => f.id == 'test-form-1234567890');
      expect(savedForm.content['paciente_nombre'], equals('Carlos Ruiz'));

      // Clean up
      form.dispose();
    });

    test('timer debouncer automatically saves after delay', () async {
      final form = ServiceForm(
        'test-form-timer-12345',
        1,
        'user-uuid-123',
        DateTime.now(),
        {'paciente_edad': '25'},
        0,
      );

      form.set('paciente_edad', '30');
      expect(form.edited, isTrue);

      // Wait for debouncer duration (750ms + margin)
      await Future.delayed(const Duration(milliseconds: 950));

      expect(form.autosaveStatus.value, equals(AutosaveState.saved));
      expect(form.edited, isFalse);

      final allForms = await DatabaseService.instance.getAllForms();
      final savedForm = allForms.firstWhere((f) => f.id == 'test-form-timer-12345');
      expect(savedForm.content['paciente_edad'], equals('30'));

      form.dispose();
    });
  });
}
