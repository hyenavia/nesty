import 'package:flutter_test/flutter_test.dart';
import 'package:nesty/features/bills/data/bill.dart';
import 'package:nesty/features/bills/data/monthly_expense.dart';
import 'package:nesty/features/laundry/data/laundry_order.dart';
import 'package:nesty/features/token/data/token_models.dart';

void main() {
  group('MonthlyExpenseCalculator', () {
    test('calculates monthly expenses and split bill portions correctly', () {
      final bills = [
        const Bill(
          id: 'b1',
          name: 'Kos',
          amountRp: 1500000,
          dayOfMonth: 1,
          splitWays: 1,
          paidThrough: '2026-11',
        ),
        const Bill(
          id: 'b2',
          name: 'WiFi',
          amountRp: 300000,
          dayOfMonth: 10,
          splitWays: 2, // my share = 150000
        ),
      ];

      final tokens = [
        TokenPurchase(
          at: DateTime(2026, 11, 5),
          amountRp: 100000,
          kwh: 65.5,
        ),
        TokenPurchase(
          at: DateTime(2026, 10, 20), // previous month, should be excluded
          amountRp: 50000,
          kwh: 32.0,
        ),
      ];

      final laundry = [
        LaundryOrder(
          id: 'l1',
          createdAt: DateTime(2026, 11, 2),
          doneAt: DateTime(2026, 11, 4),
          shop: 'Klin Laundry',
          weightKg: 4.5,
          costRp: 35000,
        ),
        LaundryOrder(
          id: 'l2',
          createdAt: DateTime(2026, 10, 15),
          doneAt: DateTime(2026, 10, 17), // previous month, should be excluded
          shop: 'Fast Laundry',
          costRp: 20000,
        ),
      ];

      final summary = MonthlyExpenseCalculator.calculate(
        year: 2026,
        month: 11,
        bills: bills,
        tokenPurchases: tokens,
        laundryOrders: laundry,
      );

      // Bills: 1,500,000 + 150,000 = 1,650,000
      expect(summary.totalBillsRp, 1650000);
      // Tokens: 100,000
      expect(summary.totalTokensRp, 100000);
      // Laundry: 35,000
      expect(summary.totalLaundryRp, 35000);
      // Grand Total: 1,785,000
      expect(summary.grandTotalRp, 1785000);

      // Items count: 2 bills + 1 token + 1 laundry = 4
      expect(summary.items.length, 4);

      // CSV export check
      final csv = summary.toCsv();
      expect(csv, contains('Date,Category,Description,Amount (Rp)'));
      expect(csv, contains('Bills'));
      expect(csv, contains('1500000'));
      expect(csv, contains('WiFi (Split 2)'));
      expect(csv, contains('TOTAL,,Grand Total,1785000'));

      // Summary text check
      final text = summary.toSummaryText();
      expect(text, contains('Period: 2026-11'));
      expect(text, contains('Total: Rp 1785000'));
    });

    test('calculates weekly expenses within week range correctly', () {
      final bills = [
        const Bill(
          id: 'b1',
          name: 'Kos',
          amountRp: 1500000,
          dayOfMonth: 1, // Sunday Nov 1
          splitWays: 1,
        ),
        const Bill(
          id: 'b2',
          name: 'WiFi',
          amountRp: 300000,
          dayOfMonth: 4, // Wednesday Nov 4, in week!
          splitWays: 2, // 150,000
        ),
      ];

      final tokens = [
        TokenPurchase(
          at: DateTime(2026, 11, 5), // Thursday Nov 5, in week!
          amountRp: 50000,
          kwh: 32.5,
        ),
        TokenPurchase(
          at: DateTime(2026, 11, 15), // next week, excluded
          amountRp: 100000,
          kwh: 65.0,
        ),
      ];

      final laundry = [
        LaundryOrder(
          id: 'l1',
          createdAt: DateTime(2026, 11, 3), // Tuesday Nov 3, in week!
          shop: 'Klin Laundry',
          costRp: 25000,
        ),
      ];

      // Week starting Monday Nov 2, 2026
      final weekStart = DateTime(2026, 11, 2);
      final weekly = MonthlyExpenseCalculator.calculateWeekly(
        weekStart: weekStart,
        bills: bills,
        tokenPurchases: tokens,
        laundryOrders: laundry,
      );

      // Bills: 150,000 (WiFi)
      expect(weekly.totalBillsRp, 150000);
      // Tokens: 50,000
      expect(weekly.totalTokensRp, 50000);
      // Laundry: 25,000
      expect(weekly.totalLaundryRp, 25000);
      // Grand Total: 225,000
      expect(weekly.grandTotalRp, 225000);
      expect(weekly.items, hasLength(3));
    });
  });
}
