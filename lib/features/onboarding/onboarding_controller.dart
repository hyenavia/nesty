import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the intro has been seen on this device.
class OnboardingController extends ChangeNotifier {
  OnboardingController(this._prefs) {
    _done = _prefs.getBool(_key) ?? false;
  }

  static const _key = 'onboarding_done';
  final SharedPreferences _prefs;
  late bool _done;

  bool get done => _done;

  Future<void> complete() => _set(true);
  Future<void> reset() => _set(false); // "Show intro again" in Profile

  Future<void> _set(bool value) async {
    _done = value;
    notifyListeners();
    await _prefs.setBool(_key, value);
  }
}
