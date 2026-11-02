class RoutineTask {
  const RoutineTask({
    required this.id,
    required this.name,
    this.nameId,
    required this.intervalDays,
    required this.createdAt,
    this.lastDone,
    this.history = const [],
  });

  final String id;
  final String name;
  final String? nameId;
  final int intervalDays;
  final DateTime createdAt;
  final DateTime? lastDone;
  final List<DateTime> history;

  int get completedCount =>
      history.isNotEmpty ? history.length : (lastDone != null ? 1 : 0);

  String displayName(String lang) =>
      (lang == 'id' && nameId != null) ? nameId! : name;

  /// Next due date (date only): last done (or creation date) + interval.
  DateTime get dueDate {
    final base = lastDone ?? createdAt;
    return DateTime(base.year, base.month, base.day + intervalDays);
  }

  /// Negative = overdue, 0 = today.
  int daysUntilDue([DateTime? now]) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return (dueDate.difference(today).inHours / 24).round();
  }

  RoutineTask copyWith({
    DateTime? lastDone,
    bool clearLastDone = false,
    List<DateTime>? history,
  }) =>
      RoutineTask(
        id: id,
        name: name,
        nameId: nameId,
        intervalDays: intervalDays,
        createdAt: createdAt,
        lastDone: clearLastDone ? null : (lastDone ?? this.lastDone),
        history: history ?? this.history,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameId': nameId,
        'intervalDays': intervalDays,
        'createdAt': createdAt.toIso8601String(),
        'lastDone': lastDone?.toIso8601String(),
        'history': history.map((e) => e.toIso8601String()).toList(),
      };

  factory RoutineTask.fromJson(Map<String, dynamic> j) => RoutineTask(
        id: j['id'] as String,
        name: j['name'] as String,
        nameId: j['nameId'] as String?,
        intervalDays: (j['intervalDays'] as num).toInt(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        lastDone: j['lastDone'] == null
            ? null
            : DateTime.parse(j['lastDone'] as String),
        history: (j['history'] as List<dynamic>?)
                ?.map((e) => DateTime.parse(e as String))
                .toList() ??
            (j['lastDone'] != null
                ? [DateTime.parse(j['lastDone'] as String)]
                : const []),
      );
}
