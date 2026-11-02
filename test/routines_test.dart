import 'package:flutter_test/flutter_test.dart';
import 'package:nesty/features/routine/data/routine_task.dart';
import 'package:nesty/features/routine/data/routines_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RoutineTask completion history and calculations', () {
    test('completedCount and due dates', () {
      final now = DateTime(2026, 11, 1);
      final task = RoutineTask(
        id: 'r1',
        name: 'Clean room',
        intervalDays: 7,
        createdAt: now,
      );

      expect(task.completedCount, 0);
      expect(task.daysUntilDue(now), 7);
      expect(task.history, isEmpty);

      // Add completions
      final updated = task.copyWith(
        lastDone: DateTime(2026, 11, 2),
        history: [DateTime(2026, 11, 2), DateTime(2026, 10, 25)],
      );

      expect(updated.completedCount, 2);
      expect(updated.dueDate, DateTime(2026, 11, 9));
      expect(updated.daysUntilDue(DateTime(2026, 11, 2)), 7);

      // JSON roundtrip
      final json = updated.toJson();
      expect(json['history'], hasLength(2));

      final restored = RoutineTask.fromJson(json);
      expect(restored.completedCount, 2);
      expect(restored.history, hasLength(2));
    });

    test('backward compatibility with legacy JSON lacking history field', () {
      final legacy = RoutineTask.fromJson({
        'id': 'legacy-1',
        'name': 'Scrub',
        'intervalDays': 10,
        'createdAt': '2026-10-01T00:00:00.000',
        'lastDone': '2026-10-15T00:00:00.000',
      });

      expect(legacy.completedCount, 1);
      expect(legacy.history, hasLength(1));
      expect(legacy.history.first, DateTime(2026, 10, 15));
    });
  });

  group('RoutinesController actions', () {
    test('markDone records timestamp in history and maintains limit', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = RoutinesController(prefs);

      final task = controller.items.first;
      final prev = controller.markDone(task.id);
      expect(prev, isNull);

      final doneTask = controller.items.firstWhere((e) => e.id == task.id);
      expect(doneTask.completedCount, 1);
      expect(doneTask.history, hasLength(1));

      // Simulate multiple completions
      for (var i = 0; i < 15; i++) {
        controller.markDone(task.id);
      }

      final capped = controller.items.firstWhere((e) => e.id == task.id);
      // History should be capped at 10 to keep storage minimal
      expect(capped.history.length, lessThanOrEqualTo(10));
    });
  });
}
