import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bill.dart';

class BillsController extends ChangeNotifier {
  BillsController(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        _items = parse(jsonDecode(raw) as List<dynamic>);
      } catch (_) {}
    }
  }

  /// Heads-up this many days before the due date.
  static const leadDays = 2;
  static const _key = 'bills_v1';
  final SharedPreferences _prefs;
  List<Bill> _items = [];

  List<Bill> get items => List.unmodifiable(_items);

  /// Soonest due first.
  List<Bill> get sorted =>
      [..._items]..sort((a, b) => a.nextDue().compareTo(b.nextDue()));

  int get dueSoonCount => _items.where((b) => b.daysUntilDue() <= 3).length;

  static List<Bill> parse(List<dynamic> list) =>
      list.map((e) => Bill.fromJson(e as Map<String, dynamic>)).toList();

  List<Map<String, dynamic>> toJson() => _items.map((e) => e.toJson()).toList();

  void loadJson(List<dynamic> list) {
    _items = parse(list);
    _changed();
  }

  void resetToDefaults() {
    _items = [];
    _changed();
  }

  void _changed() {
    notifyListeners();
    _prefs.setString(_key, jsonEncode(toJson()));
  }

  void add({
    required String name,
    int? amountRp,
    required int dayOfMonth,
    int splitWays = 1,
  }) {
    _items.add(Bill(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      amountRp: amountRp,
      dayOfMonth: dayOfMonth,
      splitWays: splitWays,
    ));
    _changed();
  }

  /// Returns the bill as it was before, for Undo.
  Bill? markPaid(String id) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) return null;
    final before = _items[i];
    _items[i] = before.copyWith(paidThrough: before.cycleKey());
    _changed();
    return before;
  }

  void remove(String id) {
    _items.removeWhere((e) => e.id == id);
    _changed();
  }

  /// Puts a bill back exactly as it was (Undo for pay / delete).
  void restore(Bill bill) {
    final i = _items.indexWhere((e) => e.id == bill.id);
    if (i == -1) {
      _items.add(bill);
    } else {
      _items[i] = bill;
    }
    _changed();
  }
}
