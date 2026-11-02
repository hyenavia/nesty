import 'bill.dart';
import '../../laundry/data/laundry_order.dart';
import '../../token/data/token_models.dart';

enum ExpensePeriodMode { monthly, weekly }

class ExpenseItem {
  const ExpenseItem({
    required this.date,
    required this.category,
    required this.title,
    required this.amountRp,
    this.subtitle,
    this.isPaid = true,
  });

  final DateTime date;
  final String category;
  final String title;
  final int amountRp;
  final String? subtitle;
  final bool isPaid;
}

class ExpenseSummary {
  const ExpenseSummary({
    required this.periodLabel,
    required this.totalBillsRp,
    required this.totalTokensRp,
    required this.totalLaundryRp,
    required this.items,
  });

  final String periodLabel;
  final int totalBillsRp;
  final int totalTokensRp;
  final int totalLaundryRp;
  final List<ExpenseItem> items;

  int get grandTotalRp => totalBillsRp + totalTokensRp + totalLaundryRp;

  String toCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Date,Category,Description,Amount (Rp)');
    for (final item in items) {
      final d =
          '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}';
      final cat = item.category;
      final desc = item.subtitle != null && item.subtitle!.isNotEmpty
          ? '"${item.title} (${item.subtitle})"'
          : '"${item.title}"';
      buffer.writeln('$d,$cat,$desc,${item.amountRp}');
    }
    buffer.writeln('TOTAL,,Grand Total,$grandTotalRp');
    return buffer.toString();
  }

  String toSummaryText() {
    final buffer = StringBuffer();
    buffer.writeln('🏠 Nesty - Expense Summary');
    buffer.writeln('Period: $periodLabel');
    buffer.writeln('--------------------------------');
    buffer.writeln('• Bills: Rp $totalBillsRp');
    buffer.writeln('• Token PLN: Rp $totalTokensRp');
    buffer.writeln('• Laundry: Rp $totalLaundryRp');
    buffer.writeln('--------------------------------');
    buffer.writeln('Total: Rp $grandTotalRp');
    return buffer.toString();
  }
}

class MonthlyExpenseSummary extends ExpenseSummary {
  const MonthlyExpenseSummary({
    required this.year,
    required this.month,
    required super.totalBillsRp,
    required super.totalTokensRp,
    required super.totalLaundryRp,
    required super.items,
  }) : super(
          periodLabel:
              '$year-${month < 10 ? '0$month' : '$month'}',
        );

  final int year;
  final int month;
}

class MonthlyExpenseCalculator {
  MonthlyExpenseCalculator._();

  static DateTime startOfWeek(DateTime d) {
    final dayOnly = DateTime(d.year, d.month, d.day);
    return dayOnly.subtract(Duration(days: dayOnly.weekday - 1));
  }

  static DateTime endOfWeek(DateTime d) {
    final start = startOfWeek(d);
    return DateTime(start.year, start.month, start.day + 6, 23, 59, 59);
  }

  static MonthlyExpenseSummary calculate({
    required int year,
    required int month,
    required List<Bill> bills,
    required List<TokenPurchase> tokenPurchases,
    required List<LaundryOrder> laundryOrders,
  }) {
    final items = <ExpenseItem>[];

    int billsTotal = 0;
    for (final b in bills) {
      final share = b.myShare;
      if (share != null && share > 0) {
        billsTotal += share;
        final sub = b.splitWays > 1 ? 'Split ${b.splitWays}' : null;
        items.add(ExpenseItem(
          date: DateTime(year, month, b.dayOfMonth.clamp(1, 28)),
          category: 'Bills',
          title: b.name,
          amountRp: share,
          subtitle: sub,
          isPaid: b.paidThrough ==
              '$year-${month.toString().padLeft(2, '0')}',
        ));
      }
    }

    int tokensTotal = 0;
    for (final p in tokenPurchases) {
      if (p.at.year == year && p.at.month == month && p.amountRp > 0) {
        tokensTotal += p.amountRp;
        items.add(ExpenseItem(
          date: p.at,
          category: 'Token',
          title: 'PLN Token',
          amountRp: p.amountRp,
          subtitle: p.kwh != null ? '${p.kwh} kWh' : null,
          isPaid: true,
        ));
      }
    }

    int laundryTotal = 0;
    for (final o in laundryOrders) {
      final date = o.doneAt ?? o.createdAt;
      if (date.year == year &&
          date.month == month &&
          o.costRp != null &&
          o.costRp! > 0) {
        laundryTotal += o.costRp!;
        items.add(ExpenseItem(
          date: date,
          category: 'Laundry',
          title: o.shop ?? 'Laundry',
          amountRp: o.costRp!,
          subtitle: o.weightKg != null ? '${o.weightKg} kg' : null,
          isPaid: true,
        ));
      }
    }

    items.sort((a, b) => a.date.compareTo(b.date));

    return MonthlyExpenseSummary(
      year: year,
      month: month,
      totalBillsRp: billsTotal,
      totalTokensRp: tokensTotal,
      totalLaundryRp: laundryTotal,
      items: items,
    );
  }

  static ExpenseSummary calculateWeekly({
    required DateTime weekStart,
    required List<Bill> bills,
    required List<TokenPurchase> tokenPurchases,
    required List<LaundryOrder> laundryOrders,
  }) {
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = DateTime(start.year, start.month, start.day + 6, 23, 59, 59);
    final items = <ExpenseItem>[];

    int billsTotal = 0;
    for (final b in bills) {
      final share = b.myShare;
      if (share != null && share > 0) {
        for (var d = 0; d < 7; d++) {
          final cur = start.add(Duration(days: d));
          if (cur.day == b.dayOfMonth) {
            billsTotal += share;
            final sub = b.splitWays > 1 ? 'Split ${b.splitWays}' : null;
            items.add(ExpenseItem(
              date: cur,
              category: 'Bills',
              title: b.name,
              amountRp: share,
              subtitle: sub,
              isPaid: b.paidThrough ==
                  '${cur.year}-${cur.month.toString().padLeft(2, '0')}',
            ));
            break;
          }
        }
      }
    }

    int tokensTotal = 0;
    for (final p in tokenPurchases) {
      if (p.at.isAfter(start.subtract(const Duration(seconds: 1))) &&
          p.at.isBefore(end.add(const Duration(seconds: 1))) &&
          p.amountRp > 0) {
        tokensTotal += p.amountRp;
        items.add(ExpenseItem(
          date: p.at,
          category: 'Token',
          title: 'PLN Token',
          amountRp: p.amountRp,
          subtitle: p.kwh != null ? '${p.kwh} kWh' : null,
          isPaid: true,
        ));
      }
    }

    int laundryTotal = 0;
    for (final o in laundryOrders) {
      final date = o.doneAt ?? o.createdAt;
      if (date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          date.isBefore(end.add(const Duration(seconds: 1))) &&
          o.costRp != null &&
          o.costRp! > 0) {
        laundryTotal += o.costRp!;
        items.add(ExpenseItem(
          date: date,
          category: 'Laundry',
          title: o.shop ?? 'Laundry',
          amountRp: o.costRp!,
          subtitle: o.weightKg != null ? '${o.weightKg} kg' : null,
          isPaid: true,
        ));
      }
    }

    items.sort((a, b) => a.date.compareTo(b.date));

    final label =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')} .. ${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

    return ExpenseSummary(
      periodLabel: label,
      totalBillsRp: billsTotal,
      totalTokensRp: tokensTotal,
      totalLaundryRp: laundryTotal,
      items: items,
    );
  }
}
