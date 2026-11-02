enum LaundryStatus { inBasket, droppedOff, ready, done }

class LaundryOrder {
  const LaundryOrder({
    required this.id,
    required this.createdAt,
    this.status = LaundryStatus.inBasket,
    this.shop,
    this.weightKg,
    this.costRp,
    this.dueDate,
    this.photo,
    this.doneAt,
  });

  final String id;
  final DateTime createdAt;
  final LaundryStatus status;
  final String? shop;
  final double? weightKg;
  final int? costRp;
  final DateTime? dueDate; // promised completion date
  final String? photo; // receipt photo file name (local only)
  final DateTime? doneAt;

  /// Negative = overdue, 0 = today. Null when no promised date.
  int? daysUntilDue([DateTime? now]) {
    if (dueDate == null) return null;
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return (due.difference(today).inHours / 24).round();
  }

  /// Needs the person to act today (collect it).
  bool get needsPickup =>
      status == LaundryStatus.ready ||
      (status == LaundryStatus.droppedOff && (daysUntilDue() ?? 1) <= 0);

  LaundryOrder copyWith({
    LaundryStatus? status,
    String? shop,
    double? weightKg,
    int? costRp,
    DateTime? dueDate,
    String? photo,
    DateTime? doneAt,
    bool clearDoneAt = false,
  }) =>
      LaundryOrder(
        id: id,
        createdAt: createdAt,
        status: status ?? this.status,
        shop: shop ?? this.shop,
        weightKg: weightKg ?? this.weightKg,
        costRp: costRp ?? this.costRp,
        dueDate: dueDate ?? this.dueDate,
        photo: photo ?? this.photo,
        doneAt: clearDoneAt ? null : (doneAt ?? this.doneAt),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'shop': shop,
        'weightKg': weightKg,
        'costRp': costRp,
        'dueDate': dueDate?.toIso8601String(),
        'photo': photo,
        'doneAt': doneAt?.toIso8601String(),
      };

  factory LaundryOrder.fromJson(Map<String, dynamic> j) => LaundryOrder(
        id: j['id'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        status: LaundryStatus.values.byName(j['status'] as String),
        shop: j['shop'] as String?,
        weightKg: (j['weightKg'] as num?)?.toDouble(),
        costRp: (j['costRp'] as num?)?.toInt(),
        dueDate:
            j['dueDate'] == null ? null : DateTime.parse(j['dueDate'] as String),
        photo: j['photo'] as String?,
        doneAt:
            j['doneAt'] == null ? null : DateTime.parse(j['doneAt'] as String),
      );
}
