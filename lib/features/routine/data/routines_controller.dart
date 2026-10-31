import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'routine_task.dart';

List<RoutineTask> defaultRoutines() {
  final now = DateTime.now();
  return [
    RoutineTask(id: 'r1', name: 'Change bedsheets & pillowcases', nameId: 'Ganti sprei & sarung bantal', intervalDays: 14, createdAt: now),
    RoutineTask(id: 'r2', name: 'Scrub the bathroom', nameId: 'Sikat kamar mandi', intervalDays: 10, createdAt: now),
    RoutineTask(id: 'r3', name: 'Clean the AC filter', nameId: 'Cuci filter AC', intervalDays: 30, createdAt: now),
    RoutineTask(id: 'r4', name: 'Take out the trash', nameId: 'Buang sampah kamar', intervalDays: 2, createdAt: now),
  ];
}

/// Interval tracker: each task repeats every N days after it was last done.
class RoutinesController extends ChangeNotifier {
  RoutinesController(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _items = defaultRoutines();
      _save();
    } else {
      try {
        _items = parse(jsonDecode(raw) as List<dynamic>);
      } catch (_) {
        _items = defaultRoutines();
      }
    }
  }

  static const _key = 'routines_v1';
  final SharedPreferences _prefs;
  List<RoutineTask> _items = [];

  List<RoutineTask> get items => List.unmodifiable(_items);

  /// Soonest due first.
  List<RoutineTask> get sorted =>
      [..._items]..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  int get dueCount => _items.where((t) => t.daysUntilDue() <= 0).length;

  static List<RoutineTask> parse(List<dynamic> list) => list
      .map((e) => RoutineTask.fromJson(e as Map<String, dynamic>))
      .toList();

  List<Map<String, dynamic>> toJson() => _items.map((e) => e.toJson()).toList();

  void loadJson(List<dynamic> list) {
    _items = parse(list);
    notifyListeners();
    _save();
  }

  void resetToDefaults() {
    _items = defaultRoutines();
    notifyListeners();
    _save();
  }

  Future<void> _save() => _prefs.setString(_key, jsonEncode(toJson()));

  /// Returns the previous value so the UI can offer Undo.
  DateTime? markDone(String id) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) return null;
    final previous = _items[i].lastDone;
    _items[i] = _items[i].copyWith(lastDone: DateTime.now());
    notifyListeners();
    _save();
    return previous;
  }

  void setLastDone(String id, DateTime? value) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) return;
    _items[i] = value == null
        ? _items[i].copyWith(clearLastDone: true)
        : _items[i].copyWith(lastDone: value);
    notifyListeners();
    _save();
  }

  void add(String name, int intervalDays) {
    _items.add(RoutineTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      intervalDays: intervalDays,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
    _save();
  }

  void remove(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    _save();
  }

  void restore(RoutineTask task) {
    if (_items.any((e) => e.id == task.id)) return;
    _items.add(task);
    notifyListeners();
    _save();
  }
}
