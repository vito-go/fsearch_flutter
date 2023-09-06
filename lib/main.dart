import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fsearch_flutter/service/request.dart';

import 'package:fsearch_flutter/service/types.dart';
import 'package:fsearch_flutter/util/github_logo.dart';
import 'package:fsearch_flutter/util/global.dart';
import 'package:fsearch_flutter/util/prefs/prefs.dart';

import 'package:fsearch_flutter/widgets/restart_app.dart';
import 'package:fsearch_flutter/widgets/text_search_region.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Global.init().then((value) {
    runApp(const RestartApp(
      child: MyApp(),
    ));
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Search',
      themeMode: prefs.themeMode,
      darkTheme: ThemeData(
        // primarySwatch: Colors.teal,
        primaryColor: Colors.deepPurple,
        brightness: Brightness.dark,
        // useMaterial3: true
      ),
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          brightness: Brightness.light),
      home: const MyHomePage(title: 'File Search'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  NodeConfigInfo nodeConfigInfo = NodeConfigInfo();

  String appName = '';
  int nodeId = 0;

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

  List<String> get hosts => nodeConfigInfo.hosts(appName);

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
            title: const Text("全选"));
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
          title: SelectableText(items[index - 1]));
    });
  }

  String textFilter = '';

  void aboutOnTap( ) async {
    String version = "0.0.1";
    String applicationName = "File Search";
    if (context.mounted) {
      showAboutDialog(
        context: context,
        applicationName: "File Search",
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

  List<Widget> buildRadioAppNames() {
    List<Widget> children = [
      ListTile(
        title: const Text("App Names",
            style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: IconButton(
            onPressed: () {
              appName = "";
              setState(() {});
            },
            icon: const Icon(Icons.refresh)),
      ),
      CupertinoSearchTextField(
        onChanged: (v) {
          textFilter = v;
          setState(() {});
        },
      ),
    ];
    for (var name in appNamesWithFilter(textFilter)) {
      children.add(RadioListTile(
          title: Text(name),
          value: name,
          groupValue: appName,
          onChanged: (v) {
            appName = name;
            nodeId = 0;
            fileCheckMap.clear();
            setState(() {});
          }));
    }
    return children;
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
          title: SelectableText(info.hostName),
          value: info.nodeId,
          groupValue: nodeId,
          onChanged: (v) {
            nodeId = v ?? nodeId;
            fileCheckMap.clear();
            setState(() {});
          }));
    }
    return items;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    homeInfo(context).then((value) {
      nodeConfigInfo = value;
      globalSearchPath = value.searchPathWS;
      setState(() {});
    });
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

  @override
  Widget build(BuildContext context) {
    final mediaHeight = MediaQuery.of(context).size.height;
    final right =
        TextSearchRegion(appName: appName, nodeId: nodeId, files: fileChecked);
    final Widget body = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Flexible(
          flex: 10,
          child: ListView(children: buildRadioAppNames()),
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
        title: Text(widget.title),
        actions: [
          IconButton(onPressed: (){
            launchUrl(Uri.parse("https://github.com/vito-go/fsearch"));
          }, icon: githubSVG),
          IconButton(onPressed: aboutOnTap, icon: const Icon(Icons.help_outline)),
          IconButton(
              onPressed: changeThemeMode,
              icon: const Icon(Icons.sunny, color: Colors.white70))
        ],
      ),
      body: body,
    );
  }
}
