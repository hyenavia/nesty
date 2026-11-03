import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages which modules the user wants Nesty to track on their dashboard.
/// Supported modules:
/// - 'token'    : Electricity token prediction & usage
/// - 'gallon'   : Drinking water gallon tracking
/// - 'laundry'  : Laundry drop-off & pickup tracker
/// - 'supplies' : Kost essentials & shopping list
/// - 'bills'    : Recurring rent, wifi, and split bills
class ModuleController extends ChangeNotifier {
  ModuleController(this._prefs) {
    final list = _prefs.getStringList(_key);
    if (list != null) {
      _enabled = list.toSet();
    } else {
      // Default: all modules enabled
      _enabled = Set.from(allModules);
    }
  }

  static const _key = 'enabled_modules_v1';
  static const moduleToken = 'token';
  static const moduleGallon = 'gallon';
  static const moduleLaundry = 'laundry';
  static const moduleSupplies = 'supplies';
  static const moduleBills = 'bills';

  static const List<String> allModules = [
    moduleToken,
    moduleGallon,
    moduleLaundry,
    moduleSupplies,
    moduleBills,
  ];

  final SharedPreferences _prefs;
  late Set<String> _enabled;

  Set<String> get enabledModules => Set.unmodifiable(_enabled);

  bool isEnabled(String module) => _enabled.contains(module);

  Future<void> setEnabled(String module, bool enabled) async {
    if (enabled) {
      _enabled.add(module);
    } else {
      _enabled.remove(module);
    }
    await _save();
    notifyListeners();
  }

  Future<void> toggle(String module) async {
    if (_enabled.contains(module)) {
      _enabled.remove(module);
    } else {
      _enabled.add(module);
    }
    await _save();
    notifyListeners();
  }

  Future<void> setAll(Set<String> modules) async {
    _enabled = Set.from(modules);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    await _prefs.setStringList(_key, _enabled.toList());
  }
}

