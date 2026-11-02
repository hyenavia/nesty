/// A monthly bill (rent, WiFi, ...) due on a day of the month.
class Bill {
  const Bill({
    required this.id,
    required this.name,
    this.amountRp,
    required this.dayOfMonth,
    this.paidThrough,
    this.splitWays = 1,
  });

  final String id;
  final String name;
  final int? amountRp;
  final int dayOfMonth; // 1..31 (short months use their last day)
  final String? paidThrough; // last paid cycle, "YYYY-MM"
  final int splitWays; // 1 = pay full, 2 = split with 1 roommate, etc.

  /// Returns user's portion when split with roommates.
  int? get myShare =>
      (amountRp != null && splitWays > 1) ? (amountRp! / splitWays).round() : amountRp;

  static String _key(int y, int m) => '$y-${m.toString().padLeft(2, '0')}';

  static DateTime _dueIn(int y, int m, int day) {
    final last = DateTime(y, m + 1, 0).day;
    return DateTime(y, m, day > last ? last : day);
  }

  /// The month cycle that is still to be paid.
  (int, int) _cycle(DateTime now) {
    var y = now.year, m = now.month;
    while (paidThrough != null && _key(y, m).compareTo(paidThrough!) <= 0) {
      m++;
      if (m > 12) {
        m = 1;
        y++;
      }
    }
    return (y, m);
  }

  DateTime nextDue([DateTime? now]) {
    final c = _cycle(now ?? DateTime.now());
    return _dueIn(c.$1, c.$2, dayOfMonth);
  }

  /// Cycle that "Mark paid" would settle.
  String cycleKey([DateTime? now]) {
    final c = _cycle(now ?? DateTime.now());
    return _key(c.$1, c.$2);
  }

  /// Negative = overdue, 0 = today.
  int daysUntilDue([DateTime? now]) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return (nextDue(n).difference(today).inHours / 24).round();
  }

  Bill copyWith({String? paidThrough, int? splitWays}) => Bill(
        id: id,
        name: name,
        amountRp: amountRp,
        dayOfMonth: dayOfMonth,
        paidThrough: paidThrough ?? this.paidThrough,
        splitWays: splitWays ?? this.splitWays,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amountRp': amountRp,
        'dayOfMonth': dayOfMonth,
        'paidThrough': paidThrough,
        'splitWays': splitWays,
      };

  factory Bill.fromJson(Map<String, dynamic> j) => Bill(
        id: j['id'] as String,
        name: j['name'] as String,
        amountRp: (j['amountRp'] as num?)?.toInt(),
        dayOfMonth: (j['dayOfMonth'] as num).toInt().clamp(1, 31).toInt(),
        paidThrough: j['paidThrough'] as String?,
        splitWays: (j['splitWays'] as num?)?.toInt() ?? 1,
      );
}
