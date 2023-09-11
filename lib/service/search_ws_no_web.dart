import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  // todo
  final queryParameters = {
    "appName": appName,
    'nodeId': "$nodeId",
    "files": files,
    "kw": kw,
  };
  final query = Uri(queryParameters: queryParameters).query;
  myPrint(query);
  final Map<String, dynamic> header = {};
  header["Origin"] = "http://127.0.0.1";
  WebSocket socket;
  try {
    // Because there may be a large amount of content transmitted, we use websocket
    // to transmit the search result content in batches instead of using http
    // please modify the url below in online environment
    final String url = 'ws://127.0.0.1:9097$searchPathWS?$query';
    socket = await WebSocket.connect(url,
        protocols: ["mychat"],
        headers: header,
        customClient: HttpClient()
          ..userAgent = null
          ..connectionTimeout = const Duration(seconds: 3, milliseconds: 500));
  } catch (e) {
    myPrint("--------------====  $e");
    return null;
  }

  final listener = socket.listen((dynamic event) {
    if (event is String) {
      onData(event);
    } else if (event is List<int>) {
      onData(utf8.decode(event));
    } else {
      myPrint("unknown data type");
      socket.close();
    }
  }, cancelOnError: true);
  return listener;
}
