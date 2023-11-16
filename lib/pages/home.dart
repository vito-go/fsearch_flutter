import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fsearch_flutter/service/search_ws_web.dart';

import 'package:fsearch_flutter/service/types.dart';
import 'package:fsearch_flutter/util/github_logo.dart';
import 'package:fsearch_flutter/util/prefs/prefs.dart';

import 'package:fsearch_flutter/widgets/restart_app.dart';
import 'package:fsearch_flutter/widgets/text_search_region.dart';
import 'package:url_launcher/url_launcher.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  NodeConfigInfo nodeConfigInfo = NodeConfigInfo();
  String appName = '';
  int nodeId = 0;
  String textFilter = '';

  List<String> get appNames => nodeConfigInfo.appNames;

  List<String> appNamesWithFilter(String filter) {
    List<String> items = [];
    for (var name in nodeConfigInfo.appNames) {
      if (name.toLowerCase().contains(filter)) {
        items.add(name);
      }
    }
    return items;
  }

  List<String> get allFiles => nodeConfigInfo.allFiles(appName);

  List<String> get files => nodeConfigInfo.files(appName, nodeId);

  Map<String, bool> fileCheckMap = {};

  List<String> get fileChecked {
    List<String> result = [];
    for (var entry in fileCheckMap.entries) {
      if (entry.key == "_") continue;
      if (entry.value) {
        result.add(entry.key);
      }
    }
    return result;
  }

  List<Widget> buildCheckboxListTile(
      List<String> items, Map<String, bool> itemCheckMap) {
    return List<CheckboxListTile>.generate(items.length + 1, (index) {
      if (index == 0) {
        return CheckboxListTile(
            value: itemCheckMap["_"] ?? false,
            onChanged: (v) {
              for (var ele in items) {
                itemCheckMap[ele] = v ?? false;
              }
              itemCheckMap["_"] = v ?? false;
              setState(() {});
            },
            title: const Text("Select All the Files"));
      }
      final fileName = items[index - 1];

      return CheckboxListTile(
          value: itemCheckMap[fileName] ?? false,
          onChanged: (v) {
            itemCheckMap[fileName] = v ?? false;
            if (v != true) {
              itemCheckMap["_"] = false;
            } else {
              int count = 0;
              for (var ele in itemCheckMap.values) {
                if (ele) {
                  count++;
                }
              }
              if (items.length == count) {
                itemCheckMap["_"] = true;
              }
            }
            setState(() {});
          },
          title: Text(items[index - 1]));
    });
  }

  void aboutOnTap() async {
    String version = "0.0.1";
    const applicationName = "File Search";
    if (context.mounted) {
      showAboutDialog(
        context: context,
        applicationName: applicationName,
        applicationIcon: InkWell(
          child: const FlutterLogo(),
          onTap: () async {},
        ),
        applicationVersion: "version: $version",
        applicationLegalese: '© All rights reserved',
        children: [
          const SizedBox(
            height: 5,
          ),
          const Text("author:liushihao888@gmail.com"),
          const SizedBox(
            height: 2,
          ),
          const Text("address: Beijing, China"),
        ],
      );
    }
  }

  changeThemeMode() {
    switch (prefs.themeMode) {
      case ThemeMode.system:
        break;
      case ThemeMode.light:
        prefs.themeMode = ThemeMode.dark;
        RestartApp.restart(context);
        break;
      case ThemeMode.dark:
        prefs.themeMode = ThemeMode.light;
        RestartApp.restart(context);
        break;
    }
  }

  Widget buildRadioAppNames() {
    List<Widget> children = [];
    for (var name in appNamesWithFilter(textFilter)) {
      children.add(RadioListTile(
          title: Text(name),
          value: name,
          groupValue: appName,
          onChanged: (v) {
            appName = name;
            nodeId = 0;
            fileCheckMap.clear();
            final files = prefs.getSelectFiles(appName);
            if (files.isNotEmpty) {
              for (var f in files) {
                fileCheckMap[f] = true;
              }
              bool allSelected = true;
              for (var f in allFiles) {
                if (fileCheckMap[f] != true) {
                  allSelected = false;
                  break;
                }
              }
              if (allSelected) {
                fileCheckMap["_"] = true;
              }
            }
            setState(() {});
          }));
    }
    return Column(
      children: [
        ListTile(
          title: Text("App Names(${children.length})",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: IconButton(
              onPressed: () {
                appName = "";
                setState(() {});
              },
              icon: const Icon(Icons.refresh)),
        ),
        CupertinoSearchTextField(
          style: TextStyle(
            color: prefs.themeMode == ThemeMode.light
                ? Colors.black
                : Colors.white,
          ),
          onChanged: (v) {
            textFilter = v;
            setState(() {});
          },
        ),
        Expanded(
            child: ListView(
          children: children,
        ))
      ],
    );
  }

  List<Widget> buildRadioHosts() {
    List<Widget> items = [
      ListTile(
        title: const Text(
          "Cluster Node",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: IconButton(
            onPressed: () {
              nodeId = 0;
              setState(() {});
            },
            icon: const Icon(Icons.refresh)),
      )
    ];
    final infos = nodeConfigInfo.nodeInfos(appName);
    for (var info in infos) {
      items.add(RadioListTile<int>(
          title: Text(info.hostName),
          value: info.nodeId,
          groupValue: nodeId,
          onChanged: (v) {
            nodeId = v ?? nodeId;
            // fileCheckMap.clear();
            setState(() {});
          }));
    }
    return items;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void updateHomeInfo() {
    homeInfo(context).then((value) {
      nodeConfigInfo = value;
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    updateHomeInfo();
  }

  @override
  Widget build(BuildContext context) {
    final mediaHeight = MediaQuery.of(context).size.height;
    final right = TextSearchRegion(
      appName: appName,
      nodeId: nodeId,
      files: fileChecked,
      searchPathHTTP: nodeConfigInfo.searchPathHTTP,
    );
    final Widget body = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Flexible(
          flex: 10,
          child: buildRadioAppNames(),
        ),
        const VerticalDivider(),
        Flexible(
            flex: 12,
            child: Column(children: [
              const SizedBox(height: 10),
              const Text("Clusters",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: mediaHeight * 0.37,
                child: ListView(children: buildRadioHosts()),
              ),
              const Divider(),
              const Text("Files",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                  child: ListView(
                      children: nodeId == 0
                          ? buildCheckboxListTile(allFiles, fileCheckMap)
                          : buildCheckboxListTile(files, fileCheckMap)))
            ])),
        const VerticalDivider(),
        Expanded(flex: 50, child: right),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kMinInteractiveDimension,
        backgroundColor: prefs.themeMode == ThemeMode.light
            ? Theme.of(context).colorScheme.inversePrimary
            : null,
        title: const Text('File Search'),
        actions: [
          IconButton(
              onPressed: () {
                launchUrl(Uri.parse("https://github.com/vito-go/fsearch"));
              },
              icon: githubSVG),
          IconButton(
              onPressed: aboutOnTap, icon: const Icon(Icons.help_outline)),
          IconButton(
              onPressed: changeThemeMode,
              icon: const Icon(Icons.sunny, color: Colors.white70)),
          IconButton(
              onPressed: updateHomeInfo, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: body,
    );
  }
}
