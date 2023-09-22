import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
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
  // todo
  final queryParameters = {
    "appName": appName,
    'nodeId': "$nodeId",
    "files": files,
    "kw": kw,
    'dataType': 'json',
  };
  final dio = Dio();
  final query = Uri(queryParameters: queryParameters).query;
  myPrint(query);
  ResponseBody? data;
  try {
    Response<ResponseBody> response = await dio.get<ResponseBody>(
      "$searchPathSSE?$query",
      options: Options(
          headers: {
            "Accept": "text/event-stream",
            "Cache-Control": "no-cache",
          },
          responseType: ResponseType.stream,
          sendTimeout:
              const Duration(seconds: 3)), // set responseType to `stream`
    );
    myPrint("--------------==== ${response.data}");
    data = response.data;
  } catch (e) {
    myPrint("--------------====  $e");
    return null;
  }
  if (data == null) return null;
  final listener = data.stream.listen((Uint8List event) {
    // myPrint(event);
    onData(utf8.decode(event));
  }, cancelOnError: true);
  return listener;
}

Future<NodeConfigInfo> homeInfo(BuildContext context) async {
  String url = const String.fromEnvironment("CONFIG_PATH", defaultValue: "");
  if (url == "") {
    throw "no config for CONFIG_PATH";
  }
  final RespData<NodeConfigInfo> result = await dioTryGet(context, url,
      queryParameters: {}, fromJson: NodeConfigInfo.fromJson);
  if (result.code != 0) {
    myToast(context, result.message);
    return NodeConfigInfo();
  }
  return result.data ?? NodeConfigInfo();
}

void saveContent(String content, String fileName) {
  throw "implement me";
}
