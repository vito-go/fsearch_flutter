import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class RespData<T> {
  int code = 0;
  String message = "";
  T? data;

  RespData({
    this.code = 0,
    this.message = "",
    this.data,
  });

  RespData.dataOK(T d) {
    data = d;
  }

  bool get success => code == 0;

  RespData.fromJson(
      Map<String, dynamic> m, T Function(Map<String, dynamic> json) fromJson) {
    code = m['code'] ?? 0;
    message = m['message'] ?? "";
    if (m.containsKey('data')) {
      data = fromJson(m['data'] as Map<String, dynamic>);
    }
  }

  RespData.error() {
    code = -1;
  }
}

Future<RespData<T>> dioTryGet<T>(
    BuildContext? context,
    String www, {
      Map<String, dynamic>? queryParameters,
      required T Function(Map<String, dynamic> json) fromJson,
      Duration sendTimeout = const Duration(seconds: 3),
      Duration receiveTimeout = const Duration(seconds: 5),
      Map<String, dynamic>? header,
    }) async {
  final dio = Dio();
  try {
    Response<String> respBody =
    await dio.get<String>(
      www,
      options: Options(
        headers: header,
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
        responseType: ResponseType.plain,
      ), // set responseType to `stream`
      queryParameters: queryParameters,
    );
    if (respBody.statusCode != 200) {
      return RespData(code: -1);
    }
    final String? respData = respBody.data;
    if (respData == null) return RespData(code: -1);
    return RespData.fromJson(jsonDecode(respData), fromJson);
  } catch (e) {
    return RespData(code: -1,message: "$e");
  } finally {
    dio.close(force: true);
  }
}
