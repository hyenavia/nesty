import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app language.
/// Defaults to device language if Indonesian ('id'), otherwise English ('en').
class LocaleController extends ChangeNotifier {
  LocaleController(this._prefs) {
    final saved = _prefs.getString(_key);
    if (saved != null) {
      _locale = Locale(saved);
    } else {
      final devLang = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      _locale = Locale(devLang == 'id' ? 'id' : 'en');
    }
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
