import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

List<int> randomBytes({int length = 16}) {
  var rnd = Random();
  var list = List<int>.generate(length, (i) => rnd.nextInt(255));
  return list;
}

enum PlatformOS { android, ios, linux, web, windows, none }

bool platFormIsMobile() {
  if (kIsWeb) {
    return false;
  }
  if (Platform.isAndroid || Platform.isIOS) {
    return true;
  }
  return false;
}

PlatformOS getPlatformOS() {
  if (kIsWeb) {
    return PlatformOS.web;
  }
  if (Platform.isAndroid) {
    return PlatformOS.android;
  }
  if (Platform.isIOS) {
    return PlatformOS.ios;
  }
  if (Platform.isLinux) {
    return PlatformOS.linux;
  }
  if (Platform.isWindows) {
    return PlatformOS.windows;
  }
  return PlatformOS.none;
}

myToast(BuildContext context, dynamic msg) {
  myPrint(msg, skip: 2);

  if (!context.mounted) return;
  showToast(
    "$msg",
    context: context,
    animation: StyledToastAnimation.fade,
    reverseAnimation: StyledToastAnimation.fade,
    position: StyledToastPosition.center,
    // curve: Curves.linear,
    // reverseCurve: Curves.linear,
  );
}

myPrint(dynamic msg,
    {List<dynamic>? args, String level = 'INFO', int skip = 1}) {
  if (kIsWeb) {
    skip++;
  }
  //  根据环境进行打印输出
  if (kDebugMode) {
    var traceString = StackTrace.current.toString().split("\n")[skip];
    String arg = "";

    if (args != null) {
      arg = "{";
      for (var i = 0; i < args.length; i++) {
        if (i % 2 == 0) {
          arg += '"${args[i]}": ';
        } else {
          if (i == args.length - 1) {
            arg += '${args[i]}';
          } else {
            arg += '${args[i]}, ';
          }
        }
      }
      arg += "}";
    }

    print("[$level] ${DateTime.now()} $traceString $msg $arg");
  }
}
