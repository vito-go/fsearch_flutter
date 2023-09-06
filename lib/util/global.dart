import 'dart:async';

import 'package:fsearch_flutter/util/prefs/prefs.dart';

class Global {
  static Future<void> init() async {
    await initGlobalPrefs();
  }
}
