import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences _globalPrefs;

Future<void> initGlobalPrefs() async {
  _globalPrefs = await SharedPreferences.getInstance();
}

final prefs = _Prefs();

class _Prefs {
  String get _keyThemeMode => "fsearch:themeMode";
  String get _searchHTMLFontSize => "fsearch:searchHTMLFontSize";
  String get _searchHTMLOverflowX => "fsearch:searchHTMLOverflowX";
  String get _locationOrigin => "fsearch:window.location.origin";

  String get _keySelectFiles => "fsearch:_keySelectFiles";

  List<String> getSelectFiles(String appName) {
    final key = "$_keySelectFiles:$appName";
    return _globalPrefs.getStringList(key)??[];
  }

  setSelectFiles(String appName, List<String> files) {
    final key = "$_keySelectFiles:$appName";
    return _globalPrefs.setStringList(key, files);
  }
  int get searchHTMLFontSize{
    return _globalPrefs.getInt(_searchHTMLFontSize)??18;
  }
   set searchHTMLFontSize(int fontSize){
    _globalPrefs.setInt(_searchHTMLFontSize, fontSize);
  }

   String get searchHTMLOverflowX{
    return _globalPrefs.getString(_searchHTMLOverflowX)??"auto";
  }
   set searchHTMLOverflowX(String overflowX){
    _globalPrefs.setString(_searchHTMLOverflowX, overflowX);
  }

   String get locationOrigin{
    return _globalPrefs.getString(_locationOrigin)??"";
  }
   set locationOrigin(String overflowX){
    _globalPrefs.setString(_locationOrigin, overflowX);
  }


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
