class ClusterNode {
  String appName = "";
  List<String> allFiles = [];

  // Map<String, List<String>> hostFilesMap = {}; //user:[a.log, a.log]
  List<NodeInfo> nodeInfos = [];

  ClusterNode.fromJson(Map<String, dynamic> json) {
    appName = json['appName'] ?? "";
    allFiles = List<String>.from(json["allFiles"] ?? []);
    // for (var entry
    //     in ((json["hostFilesMap"] ?? {}) as Map<String, dynamic>).entries) {
    //   hostFilesMap[entry.key] = List<String>.from(entry.value);
    // }

    for (var entry in ((json["nodeInfos"] ?? []) as List<dynamic>)) {
      nodeInfos.add(NodeInfo.fromJson(entry));
      // hostFilesMap[entry.key] = List<String>.from(entry.value);
    }
  }
}

class NodeInfo {
  int nodeId = 0;
  String hostName = "";
  List<String> files = [];

  NodeInfo.fromJson(Map<String, dynamic> json) {
    nodeId = json['nodeId'];
    hostName = json['hostName'];
    files = json['files'].cast<String>();
  }
}

class NodeConfigInfo {
  List<ClusterNode> clusterNodes = [];
  String searchPathHTTP = "";
  String searchPathSSE = "";

  NodeConfigInfo();

  List<String> get appNames => List<String>.generate(
      clusterNodes.length, (index) => clusterNodes[index].appName);

  List<String> hosts(String appName) {
    for (var ele in clusterNodes) {
      if (ele.appName == appName) {
        List<String> hosts = [];
        for (var info in ele.nodeInfos) {
          hosts.add(info.hostName);
        }
        return hosts;
      }
    }
    return [];
  }

  List<NodeInfo> nodeInfos(String appName) {
    for (var ele in clusterNodes) {
      if (ele.appName == appName) {
        return ele.nodeInfos;
      }
    }
    return [];
  }

  List<String> allFiles(String appName) {
    for (var ele in clusterNodes) {
      if (ele.appName == appName) {
        return ele.allFiles;
      }
    }
    return [];
  }

  List<String> files(String appName, int nodeId) {
    for (var ele in clusterNodes) {
      if (ele.appName == appName) {
        for (var info in ele.nodeInfos) {
          if (info.nodeId == nodeId) {
            return info.files;
          }
        }
      }
    }
    return [];
  }

  NodeConfigInfo.fromJson(Map<String, dynamic> json) {
    for (var ele in json["clusterNodes"] ?? []) {
      clusterNodes.add(ClusterNode.fromJson(ele));
    }
    searchPathHTTP = json['searchPathHTTP'] ?? '';
    searchPathSSE = json['searchPathSSE'] ?? '';
  }
}
