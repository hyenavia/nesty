import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app language. Default: English. Option: Bahasa Indonesia.
class LocaleController extends ChangeNotifier {
  LocaleController(this._prefs) {
    _locale = Locale(_prefs.getString(_key) ?? 'en');
  }

  static const _key = 'locale';
  final SharedPreferences _prefs;
  late Locale _locale;

  Locale get locale => _locale;

  Future<void> setLanguage(String code) async {
    if (code == _locale.languageCode) return;
    _locale = Locale(code);
    notifyListeners();
    await _prefs.setString(_key, code);
  }
}
