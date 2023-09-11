import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:fsearch_flutter/service/service.dart';
import 'package:fsearch_flutter/service/types.dart';

import '../util/util.dart';

Future<NodeConfigInfo> homeInfo(BuildContext context) async {
  String url = "/_internal/config";
  if (kDebugMode) {
    url = "http://127.0.0.1:9097/_internal/config";
  }
  final RespData<NodeConfigInfo> result = await dioTryGet(context, url,
      queryParameters: {}, fromJson: NodeConfigInfo.fromJson);
  if (result.code != 0) {
    myToast(context, result.message);
    return NodeConfigInfo();
  }
  return result.data ?? NodeConfigInfo();
}
