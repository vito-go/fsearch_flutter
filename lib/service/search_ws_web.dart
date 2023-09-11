import 'dart:async';
import 'dart:html';

import 'package:flutter/foundation.dart';

import '../util/util.dart';

Future<StreamSubscription<dynamic>?> searchText({
  required String appName,
  required String searchPathWS,
  required int nodeId,
  required List<String> files,
  required List<String> kw,
  required void Function(String data) onData,
  void Function()? onClose,
}) async {
  // in browsers, you need to pass a http.BrowserClient:
  // todo 服务端适配协议
  WebSocket ws;

  final params = <String, dynamic>{
    'appName': appName,
    'nodeId': "$nodeId",
    'files': files,
    'kw': kw,
  };
  final path = searchPathWS;
  final query = Uri(queryParameters: params).query;
// Because there may be a large amount of content transmitted, we use websocket
// to transmit the search result content in batches instead of using http
  String url = "ws://${window.location.host}$path?$query";
  if (kDebugMode) {
    // you can modify the port 9097 to that really is
    url = "ws://127.0.0.1:9097$path?$query";
  }
  myPrint("url is : $url");
  try {
    ws = WebSocket(url);
  } catch (e) {
    myPrint("-------- $e");
    return null;
  }
  ws.onError.listen((Event event) {
    myPrint("websocket error $event");

    ws.close();
  });
  ws.onOpen.listen((Event event) {
    myPrint("websocket open");
  });
  ws.onClose.listen((Event event) {
    myPrint("websocket close");
    if (onClose != null) {
      onClose();
    }
  });

  final listener = ws.onMessage.listen((MessageEvent event) {
    onData(event.data);
    myPrint("---------------------- websocket onMessage -------------------");
  }, onError: (e) {
    myPrint("-------->>> $e");
  }, cancelOnError: true);
  return listener;
}
