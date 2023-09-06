import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences _globalPrefs;

Future<void> initGlobalPrefs() async {
  _globalPrefs = await SharedPreferences.getInstance();
}

final prefs = _Prefs();

class _Prefs {
  String get _keyThemeMode => "myoption:themeMode";

  ThemeMode get themeMode {
    final key = _keyThemeMode;
    final result = _globalPrefs.getInt(key);
    if (result == null) {
      _globalPrefs.setInt(key, 2);
      return ThemeMode.light;
    }
    if (result == 0) {
      return ThemeMode.system;
    }
    if (result == 1) {
      return ThemeMode.dark;
    }
    if (result == 2) {
      return ThemeMode.light;
    }
    return ThemeMode.system;
  }

  // 0 system 1 dark 2 light
  set themeMode(ThemeMode value) {
    final key = _keyThemeMode;
    if (value == ThemeMode.system) {
      _globalPrefs.setInt(key, 0);
    } else if (value == ThemeMode.dark) {
      _globalPrefs.setInt(key, 1);
    } else if (value == ThemeMode.light) {
      _globalPrefs.setInt(key, 2);
    }
  }
}
