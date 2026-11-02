import 'package:flutter_test/flutter_test.dart';
import 'package:nesty/features/bills/data/bill.dart';
import 'package:nesty/features/bills/data/bills_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Bill date & cycle logic', () {
    test('calculates nextDue for current unpaid month', () {
      final now = DateTime(2026, 11, 2);
      const bill = Bill(
        id: '1',
        name: 'WiFi',
        amountRp: 350000,
        dayOfMonth: 15,
      );

      final due = bill.nextDue(now);
      expect(due, DateTime(2026, 11, 15));
      expect(bill.cycleKey(now), '2026-11');
      expect(bill.daysUntilDue(now), 13);
    });

    test('advances to next month once current cycle is paid', () {
      final now = DateTime(2026, 11, 2);
      const bill = Bill(
        id: '1',
        name: 'WiFi',
        amountRp: 350000,
        dayOfMonth: 15,
        paidThrough: '2026-11',
      );

      final due = bill.nextDue(now);
      expect(due, DateTime(2026, 12, 15));
      expect(bill.cycleKey(now), '2026-12');
    });

    test('detects overdue bills when past due day', () {
      final now = DateTime(2026, 11, 20);
      const bill = Bill(
        id: '1',
        name: 'Rent',
        amountRp: 1500000,
        dayOfMonth: 10,
      );

      expect(bill.daysUntilDue(now), -10); // 10 days overdue
    });

    test('splitWays and myShare calculation and serialization', () {
      const bill = Bill(
        id: 'split-1',
        name: 'Internet',
        amountRp: 300000,
        dayOfMonth: 20,
        splitWays: 3,
      );

      expect(bill.splitWays, 3);
      expect(bill.myShare, 100000);

      // JSON roundtrip
      final json = bill.toJson();
      expect(json['splitWays'], 3);

      final restored = Bill.fromJson(json);
      expect(restored.splitWays, 3);
      expect(restored.myShare, 100000);

      // Default splitWays
      final legacy = Bill.fromJson({
        'id': 'legacy',
        'name': 'Trash',
        'amountRp': 50000,
        'dayOfMonth': 1,
      });
      expect(legacy.splitWays, 1);
      expect(legacy.myShare, 50000);
    });
  });

  group('BillsController actions', () {
    test('markPaid advances paidThrough cycle', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = BillsController(prefs);

      controller.add(name: 'Electricity', amountRp: 200000, dayOfMonth: 5);
      final added = controller.items.first;

      final previous = controller.markPaid(added.id);
      expect(previous?.paidThrough, isNull);

      final updated = controller.items.first;
      expect(updated.paidThrough, isNotNull);
    });
  });
}
