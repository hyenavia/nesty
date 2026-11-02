import 'package:flutter_test/flutter_test.dart';
import 'package:nesty/features/gallon/data/gallon_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GallonData parsing & serialization', () {
    test('parses empty and default values correctly', () {
      final parsed = GallonController.parse({});
      expect(parsed.starts, isEmpty);
      expect(parsed.defaultDays, 7);
    });

    test('parses and sorts custom values', () {
      final parsed = GallonController.parse({
        'starts': [
          '2026-10-20T08:00:00.000',
          '2026-10-10T08:00:00.000',
        ],
        'defaultDays': 5,
      });

      expect(parsed.starts.length, 2);
      expect(parsed.starts.first, DateTime(2026, 10, 10, 8));
      expect(parsed.defaultDays, 5);
    });
  });

  group('GallonController calculation', () {
    test('uses default days when no history exists', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = GallonController(prefs);

      expect(controller.avgDays, 7);
      expect(controller.currentStart, isNull);
      expect(controller.daysLeft, isNull);
    });

    test('calculates learned average from consecutive gallons', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = GallonController(prefs);

      // Gallon 1: Oct 1
      controller.newGallon(DateTime(2026, 10, 1, 8));
      // Gallon 2: Oct 9 (lasted 8 days)
      controller.newGallon(DateTime(2026, 10, 9, 8));
      // Gallon 3: Oct 15 (lasted 6 days)
      controller.newGallon(DateTime(2026, 10, 15, 8));

      // Average of 8 and 6 is 7
      expect(controller.learnedCount, 2);
      expect(controller.avgDays, 7);
      expect(controller.lastedDays(DateTime(2026, 10, 1, 8)), 8);
      expect(controller.lastedDays(DateTime(2026, 10, 9, 8)), 6);
      expect(controller.lastedDays(DateTime(2026, 10, 15, 8)), isNull); // currently in use
    });
  });
}

