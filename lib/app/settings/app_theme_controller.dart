import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController() {
    unawaited(_restore());
  }

  static const _storageKey = 'app_theme.style';

  AppGameThemeStyle _style = AppGameThemeStyle.glyph;

  AppGameThemeStyle get style => _style;

  AppGameTheme get gameTheme => AppGameTheme.ofStyle(_style);

  void setStyle(AppGameThemeStyle style) {
    if (_style == style) {
      return;
    }
    _style = style;
    notifyListeners();
    unawaited(_save());
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_storageKey);
    AppGameThemeStyle? restored;
    for (final item in AppGameThemeStyle.values) {
      if (item.name == name) {
        restored = item;
        break;
      }
    }
    if (restored == null || restored == _style) {
      return;
    }
    _style = restored;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _style.name);
  }
}
