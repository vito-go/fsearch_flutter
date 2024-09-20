import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fsearch/service/search_ws_web.dart';

import 'package:fsearch/service/types.dart';


import 'package:fsearch/widgets/text_search_region.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/prefs/prefs.dart';
import '../common/queue.dart';
import '../util/util.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  NodeConfigInfo nodeConfigInfo = NodeConfigInfo();
  String appName = '';
  int nodeId = 0;
  String textFilter = '';
  String githubSVGContent = '';

  void eventHandler(Event event) {
    if (event.eventType == EventType.updateTheme) {
      setState(() {});
    }
  }

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
            title:   const Text("Select All the Files",style: TextStyle(fontWeight: FontWeight.bold),));
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
        produceEvent(EventType.updateTheme, ThemeMode.dark);
        break;
      case ThemeMode.dark:
        prefs.themeMode = ThemeMode.light;
        produceEvent(EventType.updateTheme, ThemeMode.light);
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
    eventConsumer?.cancel();
  }

  void updateHomeInfo() async {
    final value = await homeInfo(context);
    nodeConfigInfo = value;
    setState(() {});
  }

  StreamSubscription<Event>? eventConsumer;

  void updateGitHubSVGContent() async {
    final bool isDark = prefs.themeMode == ThemeMode.dark;
    if (isDark) {
      githubSVGContent =
          await rootBundle.loadString("assets/images/github-dark.svg");
    } else {
      githubSVGContent =
          await rootBundle.loadString("assets/images/github-dark.svg");
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    updateHomeInfo();
    updateGitHubSVGContent();
    eventConsumer = consume(eventHandler);
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
        const SizedBox(width: 10),
      ],
    );
    final sunIcon=prefs.themeMode == ThemeMode.light?Icons.nightlight_round:Icons.sunny;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kMinInteractiveDimension,
        title: const Text('File Search', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
              onPressed: () {
                launchUrl(Uri.parse("https://github.com/vito-go/fsearch"));
              },
              icon: githubSVGContent == ""
                  ? const Icon(Icons.link)
                  : SvgPicture.string(githubSVGContent)),
          IconButton(
              onPressed: aboutOnTap,
              icon: const Icon(Icons.help_outline, color: Colors.white)),
          IconButton(
              onPressed: changeThemeMode,
              icon:   Icon(sunIcon, color: Colors.white)),
          IconButton(
              onPressed: updateHomeInfo,
              icon: const Icon(Icons.refresh, color: Colors.white)),
          const SizedBox(width: 20),
        ],
      ),
      body: body,
    );
  }
}
