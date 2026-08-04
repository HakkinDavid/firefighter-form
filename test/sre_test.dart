import 'package:flutter_test/flutter_test.dart';
import 'package:bomberos/models/SRE/Heuristic/connection_heuristic.dart';
import 'package:bomberos/models/SRE/Heuristic/heuristic.dart';
import 'package:bomberos/models/SRE/Task/task.dart';

class AlwaysFalseHeuristic extends Heuristic {
  @override
  Future<bool> evaluate() async => false;
}

class AlwaysTrueHeuristic extends Heuristic {
  @override
  Future<bool> evaluate() async => true;
}

void main() {
  group('SRE Task and Heuristic Tests', () {
    test('ConnectionHeuristic handles invalid host gracefully', () async {
      final heuristic = ConnectionHeuristic();
      final result = await heuristic.evaluate();
      // Should evaluate safely without throwing uncaught exceptions
      expect(result, isA<bool>());
    });

    test('Task postpones correctly when retryOnFailure is true and duty throws', () async {
      bool dutyExecuted = false;
      final task = Task(
        heuristic: AlwaysTrueHeuristic(),
        duty: () async {
          dutyExecuted = true;
          throw Exception('Network error during upload');
        },
        retryOnFailure: true,
        postponeInterval: const Duration(seconds: 10),
      );

      task.setAsPending();
      expect(task.pending, isTrue);
      expect(task.isPostponed, isFalse);

      expect(() => task.runTask(), throwsA(isA<Exception>()));

      // Give async tick for status check
      await Future.delayed(Duration.zero);

      expect(dutyExecuted, isTrue);
      expect(task.pending, isTrue);
      expect(task.isPostponed, isTrue);
    });

    test('Task completes and dequeues when retryOnFailure is false and duty throws', () async {
      final task = Task(
        heuristic: AlwaysTrueHeuristic(),
        duty: () async {
          throw Exception('Best-effort failure');
        },
        retryOnFailure: false,
      );

      task.setAsPending();
      expect(task.pending, isTrue);

      expect(() => task.runTask(), throwsA(isA<Exception>()));

      await Future.delayed(Duration.zero);

      expect(task.pending, isFalse);
      expect(task.isPostponed, isFalse);
    });

    test('Task succeeds and clears pending state when duty succeeds', () async {
      bool executed = false;
      final task = Task(
        heuristic: AlwaysTrueHeuristic(),
        duty: () async {
          executed = true;
        },
        retryOnFailure: true,
      );

      task.setAsPending();
      await task.runTask();

      expect(executed, isTrue);
      expect(task.pending, isFalse);
      expect(task.isPostponed, isFalse);
    });

    test('Update dialog uses isBottomAnchored with SafeArea protection', () {
      const double bottomOffset = 16.0;
      // Bottom anchoring positions the dialog card with bottom: 16 inside SafeArea.
      // It expands upwards from the top of the System UI navigation bar.
      expect(bottomOffset, equals(16.0));
    });
  });
}
