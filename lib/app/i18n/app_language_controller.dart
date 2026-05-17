import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageController extends ChangeNotifier {
  AppLanguageController() {
    unawaited(_restore());
  }

  static const _storageKey = 'app_language.locale';
  static const _supportedLanguageCodes = {'en', 'zh'};

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    final normalized = Locale(locale.languageCode);
    if (!_supportedLanguageCodes.contains(normalized.languageCode)) {
      return;
    }
    if (_locale == normalized) {
      return;
    }
    _locale = normalized;
    notifyListeners();
    unawaited(_save());
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_storageKey);
    if (languageCode == null ||
        !_supportedLanguageCodes.contains(languageCode) ||
        _locale.languageCode == languageCode) {
      return;
    }
    _locale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _locale.languageCode);
  }
}
