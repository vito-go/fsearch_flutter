import 'dart:async';
import 'dart:html';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:fsearch_flutter/service/service.dart';
import 'package:fsearch_flutter/service/types.dart';

import '../util/util.dart';

Future<String> searchTextHTTP({
  required String appName,
  required String searchPathHTTP,
  required int nodeId,
  required List<String> files,
  required List<String> kw,
}) async {
  final params = <String, dynamic>{
    'appName': appName,
    'nodeId': "$nodeId",
    'files': files,
    'kw': kw,
    'dataType': 'text',
  };
  String url = searchPathHTTP;
  if (kDebugMode) {
    url = 'http://127.0.0.1:9097$url';
  }
  print("search: $url");
  final dio = Dio();
  final Response<String> response = await dio.get(url,
      options: Options(
          responseType: ResponseType.plain,
          validateStatus: (int? status) {
            return true;
          }),
      queryParameters: params);
  if (response.statusCode != 200) {
    return "http statusCode not ok: $response.statusCode";
  }
  return response.data ?? "";
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
