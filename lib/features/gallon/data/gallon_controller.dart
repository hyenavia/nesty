import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GallonData {
  const GallonData(this.starts, this.defaultDays);
  final List<DateTime> starts; // when each gallon was put in use (ascending)
  final int defaultDays;
}

/// One-tap gallon cycle. Each tap = a new gallon. The average of the last
/// few gaps becomes the expected lifetime of the current gallon.
class GallonController extends ChangeNotifier {
  GallonController(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        _apply(parse(jsonDecode(raw) as Map<String, dynamic>));
      } catch (e) {
        debugPrint('[GallonController] Failed to parse saved data: $e');
      }
    }
  }

  static const _key = 'gallon_v1';
  final SharedPreferences _prefs;
  List<DateTime> _starts = [];
  int _defaultDays = 7;

  List<DateTime> get starts => List.unmodifiable(_starts);
  int get defaultDays => _defaultDays;

  static GallonData parse(Map<String, dynamic> j) {
    final starts = ((j['starts'] as List<dynamic>?) ?? [])
        .map((e) => DateTime.parse(e as String))
        .toList()
      ..sort();
    final days = ((j['defaultDays'] as num?)?.toInt() ?? 7).clamp(1, 60).toInt();
    return GallonData(starts, days);
  }

  Map<String, dynamic> toJson() => {
        'starts': _starts.map((e) => e.toIso8601String()).toList(),
        'defaultDays': _defaultDays,
      };

  void _apply(GallonData d) {
    _starts = d.starts;
    _defaultDays = d.defaultDays;
  }

  void loadJson(Map<String, dynamic> j) {
    _apply(parse(j));
    _changed();
  }

  void resetToDefaults() {
    _starts = [];
    _defaultDays = 7;
    _changed();
  }

  void _changed() {
    notifyListeners();
    _prefs.setString(_key, jsonEncode(toJson()));
  }

  // ------------------------------------------------------------ editing

  void newGallon([DateTime? at]) {
    _starts.add(at ?? DateTime.now());
    _starts.sort();
    if (_starts.length > 40) _starts.removeAt(0);
    _changed();
  }

  void remove(DateTime start) {
    _starts.removeWhere((e) => e == start);
    _changed();
  }

  void setDefaultDays(int days) {
    _defaultDays = days.clamp(1, 60).toInt();
    _changed();
  }

  // ----------------------------------------------------------- forecast

  /// Gaps (in days) between consecutive gallons; last 5, ignoring accidental
  /// double taps (< 12 hours apart).
  List<double> get _durations {
    final out = <double>[];
    for (var i = 1; i < _starts.length; i++) {
      final d = _starts[i].difference(_starts[i - 1]).inMinutes / 1440;
      if (d >= 0.5) out.add(d);
    }
    return out.length > 5 ? out.sublist(out.length - 5) : out;
  }

  int get learnedCount => _durations.length;

  int get avgDays {
    final d = _durations;
    if (d.isEmpty) return _defaultDays;
    return max(1, (d.reduce((a, b) => a + b) / d.length).round());
  }

  DateTime? get currentStart => _starts.isEmpty ? null : _starts.last;

  DateTime? get expectedEmpty {
    final s = currentStart;
    if (s == null) return null;
    return DateTime(s.year, s.month, s.day + avgDays);
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Days until the current gallon is expected to be empty (<= 0: now / overdue).
  int? get daysLeft {
    final e = expectedEmpty;
    if (e == null) return null;
    return (e.difference(_today()).inHours / 24).round();
  }

  /// "Day N" of the current gallon.
  int? get dayNumber {
    final s = currentStart;
    if (s == null) return null;
    final start = DateTime(s.year, s.month, s.day);
    return (_today().difference(start).inHours / 24).round() + 1;
  }

  /// Heads-up the day before it is expected to run out.
  DateTime? get reminderDate {
    final e = expectedEmpty;
    return e == null ? null : DateTime(e.year, e.month, e.day - 1);
  }

  /// How many days gallon [start] lasted (null for the one in use).
  int? lastedDays(DateTime start) {
    final i = _starts.indexOf(start);
    if (i == -1 || i == _starts.length - 1) return null;
    return max(1, (_starts[i + 1].difference(start).inMinutes / 1440).round());
  }
}
