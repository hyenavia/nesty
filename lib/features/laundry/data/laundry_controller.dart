import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'laundry_order.dart';

/// Laundry tracker: In basket -> At the laundry -> Ready for pickup -> Done.
class LaundryController extends ChangeNotifier {
  LaundryController(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        _orders = parse(jsonDecode(raw) as List<dynamic>);
      } catch (e) {
        debugPrint('[LaundryController] Failed to parse saved data: $e');
      }
    }
  }

  static const _key = 'laundry_v1';
  static const _maxDone = 20;
  final SharedPreferences _prefs;
  List<LaundryOrder> _orders = [];

  List<LaundryOrder> get orders => List.unmodifiable(_orders);

  /// Not finished yet: ready first, then at the laundry (soonest due), then basket.
  List<LaundryOrder> get active => _orders
      .where((o) => o.status != LaundryStatus.done)
      .toList()
    ..sort((a, b) {
      final byStatus = b.status.index.compareTo(a.status.index);
      if (byStatus != 0) return byStatus;
      final da = a.dueDate ?? DateTime(9999), db = b.dueDate ?? DateTime(9999);
      return da.compareTo(db);
    });

  /// At the laundry or ready (i.e. out of the house).
  List<LaundryOrder> get pending => active
      .where((o) =>
          o.status == LaundryStatus.droppedOff || o.status == LaundryStatus.ready)
      .toList();

  List<LaundryOrder> get history => _orders
      .where((o) => o.status == LaundryStatus.done)
      .toList()
    ..sort((a, b) => (b.doneAt ?? b.createdAt).compareTo(a.doneAt ?? a.createdAt));

  int get activeCount => active.length;
  int get readyCount =>
      _orders.where((o) => o.status == LaundryStatus.ready).length;
  int get pickupCount => _orders.where((o) => o.needsPickup).length;

  /// Most recently used shop, to pre-fill the hand-over form.
  String? get lastShop {
    final withShop = _orders.where((o) => (o.shop ?? '').isNotEmpty).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return withShop.isEmpty ? null : withShop.first.shop;
  }

  static List<LaundryOrder> parse(List<dynamic> list) => list
      .map((e) => LaundryOrder.fromJson(e as Map<String, dynamic>))
      .toList();

  List<Map<String, dynamic>> toJson() => _orders.map((e) => e.toJson()).toList();

  void loadJson(List<dynamic> list) {
    _orders = parse(list);
    _changed();
  }

  void resetToDefaults() {
    _orders = [];
    _changed();
  }

  void _changed() {
    notifyListeners();
    _prefs.setString(_key, jsonEncode(toJson()));
  }

  // ------------------------------------------------------------ editing

  LaundryOrder addToBasket() {
    final order = LaundryOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
    );
    _orders.add(order);
    _changed();
    return order;
  }

  void _update(String id, LaundryOrder Function(LaundryOrder) fn) {
    final i = _orders.indexWhere((e) => e.id == id);
    if (i == -1) return;
    _orders[i] = fn(_orders[i]);
    _changed();
  }

  void dropOff(
    String id, {
    String? shop,
    double? weightKg,
    int? costRp,
    required DateTime dueDate,
    String? photo,
  }) =>
      _update(
        id,
        (o) => o.copyWith(
          status: LaundryStatus.droppedOff,
          shop: shop,
          weightKg: weightKg,
          costRp: costRp,
          dueDate: dueDate,
          photo: photo,
        ),
      );

  void setStatus(String id, LaundryStatus status) {
    _update(
      id,
      (o) => status == LaundryStatus.done
          ? o.copyWith(status: status, doneAt: DateTime.now())
          : o.copyWith(status: status, clearDoneAt: true),
    );
    _trimDone();
  }

  void setPhoto(String id, String photo) =>
      _update(id, (o) => o.copyWith(photo: photo));

  void _trimDone() {
    final done = history;
    if (done.length > _maxDone) {
      final drop = done.sublist(_maxDone).map((e) => e.id).toSet();
      _orders.removeWhere((o) => drop.contains(o.id));
      _changed();
    }
  }

  void remove(String id) {
    _orders.removeWhere((e) => e.id == id);
    _changed();
  }

  /// Puts an order back exactly as it was (used by Undo).
  void restore(LaundryOrder order) {
    final i = _orders.indexWhere((e) => e.id == order.id);
    if (i == -1) {
      _orders.add(order);
    } else {
      _orders[i] = order;
    }
    _changed();
  }
}
