import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'token_models.dart';

/// Electricity token prediction.
///
/// Idea: the prepaid meter shows remaining kWh. Between two meter readings,
///   used = earlierReading + topUps(kWh) - laterReading
/// Average the last few segments to get kWh/day, then
///   run-out date = latest reading time + (latest reading + later top-ups) / rate.
class TokenController extends ChangeNotifier {
  TokenController(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        _apply(parse(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {}
    }
  }

  static const _key = 'token_v1';
  static const _maxItems = 60;
  final SharedPreferences _prefs;
  List<MeterReading> _readings = [];
  List<TokenPurchase> _purchases = [];
  double? _tariff;

  List<MeterReading> get readings => List.unmodifiable(_readings);
  List<TokenPurchase> get purchases => List.unmodifiable(_purchases);
  double? get tariff => _tariff;

  static TokenState parse(Map<String, dynamic> j) => TokenState(
        ((j['readings'] as List<dynamic>?) ?? [])
            .map((e) => MeterReading.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.at.compareTo(b.at)),
        ((j['purchases'] as List<dynamic>?) ?? [])
            .map((e) => TokenPurchase.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.at.compareTo(b.at)),
        (j['tariff'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'readings': _readings.map((e) => e.toJson()).toList(),
        'purchases': _purchases.map((e) => e.toJson()).toList(),
        'tariff': _tariff,
      };

  void _apply(TokenState s) {
    _readings = s.readings;
    _purchases = s.purchases;
    _tariff = s.tariff;
  }

  void loadJson(Map<String, dynamic> j) {
    _apply(parse(j));
    _changed();
  }

  void resetToDefaults() {
    _readings = [];
    _purchases = [];
    _tariff = null;
    _changed();
  }

  void _changed() {
    notifyListeners();
    _prefs.setString(_key, jsonEncode(toJson()));
  }

  // ------------------------------------------------------------ editing

  void addReading(double kwh) {
    _readings.add(MeterReading(at: DateTime.now(), kwh: kwh));
    _readings.sort((a, b) => a.at.compareTo(b.at));
    if (_readings.length > _maxItems) _readings.removeAt(0);
    _changed();
  }

  void addPurchase(int amountRp, double? kwh) {
    var estimated = false;
    if (kwh == null && _tariff != null && _tariff! > 0) {
      kwh = amountRp / _tariff!;
      estimated = true;
    }
    _purchases.add(TokenPurchase(
        at: DateTime.now(), amountRp: amountRp, kwh: kwh, kwhEstimated: estimated));
    _purchases.sort((a, b) => a.at.compareTo(b.at));
    if (_purchases.length > _maxItems) _purchases.removeAt(0);
    _changed();
  }

  void removeReading(MeterReading r) {
    _readings.removeWhere((e) => e.at == r.at);
    _changed();
  }

  void restoreReading(MeterReading r) {
    _readings.add(r);
    _readings.sort((a, b) => a.at.compareTo(b.at));
    _changed();
  }

  void removePurchase(TokenPurchase p) {
    _purchases.removeWhere((e) => e.at == p.at);
    _changed();
  }

  void restorePurchase(TokenPurchase p) {
    _purchases.add(p);
    _purchases.sort((a, b) => a.at.compareTo(b.at));
    _changed();
  }

  void setTariff(double? value) {
    _tariff = value;
    _changed();
  }

  // ----------------------------------------------------------- forecast

  double? _ratePerDay() {
    if (_readings.length < 2) return null;
    final rs = _readings.sublist(max(0, _readings.length - 6));
    var used = 0.0, days = 0.0;
    for (var i = 1; i < rs.length; i++) {
      final a = rs[i - 1], b = rs[i];
      final dt = b.at.difference(a.at).inMinutes / 1440;
      if (dt < 0.5) continue; // too close together to be meaningful
      var added = 0.0;
      var unknown = false;
      for (final p in _purchases) {
        if (p.at.isAfter(a.at) && !p.at.isAfter(b.at)) {
          if (p.kwh == null) {
            unknown = true;
          } else {
            added += p.kwh!;
          }
        }
      }
      if (unknown) continue;
      final u = a.kwh + added - b.kwh;
      if (u < 0) continue; // inconsistent entry, ignore
      used += u;
      days += dt;
    }
    if (days <= 0 || used <= 0) return null;
    return used / days;
  }

  TokenForecast forecast() {
    if (_readings.isEmpty) return const TokenForecast(hint: TokenHint.needReading);
    final base = _readings.last;
    var added = 0.0;
    for (final p in _purchases) {
      if (!p.at.isAfter(base.at)) continue;
      if (p.kwh == null) return const TokenForecast(hint: TokenHint.needKwh);
      added += p.kwh!;
    }
    final start = base.kwh + added;
    final rate = _ratePerDay();
    if (rate == null) {
      return TokenForecast(hint: TokenHint.needSecondReading, remainingKwh: start);
    }
    final runOut = base.at.add(Duration(minutes: (start / rate * 1440).round()));
    final elapsed = DateTime.now().difference(base.at).inMinutes / 1440;
    return TokenForecast(
      remainingKwh: max(0.0, start - rate * elapsed),
      ratePerDay: rate,
      runOutDate: runOut,
    );
  }
}
