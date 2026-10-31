import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'default_supplies.dart';
import 'supply_item.dart';

/// Single source of truth for supplies. Data is stored locally on the device.
///
/// Auto-shopping list: there is no separate "shopping list" storage.
/// It is derived from items whose status is Running low or Out, so the
/// list can never get out of sync with the stock.
class SuppliesController extends ChangeNotifier {
  SuppliesController(this._prefs) {
    _load();
  }

  static const _key = 'supplies_v1';
  final SharedPreferences _prefs;
  List<SupplyItem> _items = [];

  List<SupplyItem> get items => List.unmodifiable(_items);

  /// Out first, then Running low.
  List<SupplyItem> get shoppingList =>
      _items.where((i) => i.needsRestock).toList()
        ..sort((a, b) => b.status.index.compareTo(a.status.index));

  int get restockCount => _items.where((i) => i.needsRestock).length;

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _items = List.of(defaultSupplies);
      _save();
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _items = list
          .map((e) => SupplyItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _items = List.of(defaultSupplies);
    }
  }

  Future<void> _save() => _prefs.setString(
        _key,
        jsonEncode(_items.map((e) => e.toJson()).toList()),
      );

  static List<SupplyItem> parse(List<dynamic> list) => list
      .map((e) => SupplyItem.fromJson(e as Map<String, dynamic>))
      .toList();

  List<Map<String, dynamic>> toJson() => _items.map((e) => e.toJson()).toList();

  void loadJson(List<dynamic> list) {
    _items = parse(list);
    notifyListeners();
    _save();
  }

  void resetToDefaults() {
    _items = List.of(defaultSupplies);
    notifyListeners();
    _save();
  }

  void setStatus(String id, SupplyStatus status) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) return;
    var item = _items[i].copyWith(status: status);
    // Restocked an item that was counted at 0: it now has at least one.
    if (status == SupplyStatus.safe && item.quantity == 0) {
      item = item.copyWith(quantity: 1);
    }
    _items[i] = item;
    notifyListeners();
    _save();
  }

  /// null = stop counting. Reaching 0 marks the item Out; going back above 0
  /// from 0 marks it Safe.
  void setQuantity(String id, int? quantity) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) return;
    final before = _items[i];
    if (quantity == null) {
      _items[i] = before.copyWith(clearQuantity: true);
    } else {
      final q = quantity.clamp(0, 999).toInt();
      var item = before.copyWith(quantity: q);
      if (q == 0) {
        item = item.copyWith(status: SupplyStatus.out);
      } else if (before.quantity == 0) {
        item = item.copyWith(status: SupplyStatus.safe);
      }
      _items[i] = item;
    }
    notifyListeners();
    _save();
  }

  void add({
    required String name,
    required SupplyCategory category,
    SupplyStatus status = SupplyStatus.safe,
    int? quantity,
  }) {
    _items.add(SupplyItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      category: category,
      status: quantity == 0 ? SupplyStatus.out : status,
      quantity: quantity,
    ));
    notifyListeners();
    _save();
  }

  void remove(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    _save();
  }

  /// Used by "Undo" after deleting.
  void restore(SupplyItem item) {
    if (_items.any((e) => e.id == item.id)) return;
    _items.add(item);
    notifyListeners();
    _save();
  }
}
