import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:fsearch_flutter/service/service.dart';
import 'package:fsearch_flutter/service/types.dart';

import '../util/util.dart';

Future<StreamSubscription<dynamic>?> searchText({
  required String appName,
  required String searchPathSSE,
  required int nodeId,
  required List<String> files,
  required List<String> kw,
  required void Function(String data) onData,
  void Function()? onClose,
}) async {
  final params = <String, dynamic>{
    'appName': appName,
    'nodeId': "$nodeId",
    'files': files,
    'kw': kw,
    'dataType': 'text',
  };
  final path = searchPathSSE;
  final query = Uri(queryParameters: params).query;
  String url = "$path?$query";
  if (kDebugMode) {
    url = 'http://127.0.0.1:9097$url';
  }
  myPrint("url is : $url");
  EventSource eventSource;
  try {
    eventSource = EventSource(url);
  } catch (e) {
    myPrint("-------- $e");
    return null;
  }
  eventSource.onError.listen((Event event) {
    myPrint(
        "----========onError========----------  ${event.type}${event} ${event.path}");
    eventSource.close();
    if (onClose != null) {
      onClose();
    }
  });
  eventSource.onOpen.listen((Event event) {
    myPrint("----========open========----------  ${event.type} ${event.path}");
  });
  final listener = eventSource.onMessage.listen((MessageEvent event) {
    onData(event.data);
  }, onError: (e) {
    myPrint("-------->>> $e");
  }, cancelOnError: true);
  // window.alert("SSE链接成功");
  return listener;
}

Future<NodeConfigInfo> homeInfo(BuildContext context) async {
  String url;
  const internConfig = "/_internal/config";
  final pathname = window.location.pathname ?? '/';
  if (pathname == "/") {
    url = internConfig;
  } else if (pathname.endsWith("/")) {
    // /user/home/
    String temp = pathname.substring(0, pathname.length - 1);
    temp = temp.substring(0, temp.lastIndexOf("/"));
    url = "$temp$internConfig";
  } else {
    // /user/home
    String temp = pathname;
    temp = temp.substring(0, temp.lastIndexOf("/"));
    url = "$temp$internConfig";
  }
  // FIXME
  if (kDebugMode) {
    url = 'http://127.0.0.1:9097/_internal/config';
  }
  print("config url: $url");
  final RespData<NodeConfigInfo> result = await dioTryGet(context, url,
      queryParameters: {}, fromJson: NodeConfigInfo.fromJson);
  if (result.code != 0) {
    myToast(context, result.message);
    return NodeConfigInfo();
  }
  return result.data ?? NodeConfigInfo();
}

void saveContent(String content, String fileName) {
  final downLink = AnchorElement();
  downLink.download = fileName;
  final blob = Blob([content]);
  downLink.href = Url.createObjectUrlFromBlob(blob);
  document.body?.append(downLink);
  downLink.click();
  downLink.remove();
}
