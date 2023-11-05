import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:fsearch_flutter/service/search_ws_web.dart';

import 'package:fsearch_flutter/util/util.dart';

import '../util/prefs/prefs.dart';

class TextSearchRegion extends StatefulWidget {
  const TextSearchRegion(
      {super.key,
      required this.appName,
      required this.searchPathHTTP,
      required this.nodeId,
      required this.files});

  final String appName;
  final String searchPathHTTP;
  final int nodeId;
  final List<String> files;

  @override
  State<StatefulWidget> createState() {
    return TextSearchRegionState();
  }
}

class TextSearchRegionState extends State<TextSearchRegion> {
  List<String> searchResult = [];
  final TextEditingController controller = TextEditingController(text: " ");

  ScrollController scrollController = ScrollController();
  bool searchDone = false;
  bool loading = false;
  final FocusNode focusNode = FocusNode();
  int fontSize = 18;
  Widget noResult = Center(
      child: SelectableText("no result",
          style: TextStyle(
              color: prefs.themeMode == ThemeMode.light
                  ? Colors.black
                  : Colors.white,
              fontSize: 48)));

  @override
  void dispose() {
    super.dispose();
    myPrint("dispose search");
    scrollController.dispose();
    controller.dispose();
  }

  Future<void> _search() async {
    if (loading) {
      return;
    }
    if (widget.appName == "") {
      myToast(context, "please select a app");
      return;
    }
    final text = controller.text.trim();
    if (text == "") {
      myToast(context, "please enter the keywords");
      return;
    }
    List<String> kw = [];
    final splits = text.split(";");
    for (var ele in splits) {
      kw.add(ele.trim());
    }
    if (widget.nodeId == 0 && widget.files.isEmpty) {
      myToast(
          context, "Please select at least one file when not selecting a host");
      return;
    }
    setState(() {
      searchResult.clear();
      searchDone = false;
      loading = true;
    });
    prefs.setSelectFiles(widget.appName, widget.files);
    final result = await searchTextHTTP(
        appName: widget.appName,
        searchPathHTTP: widget.searchPathHTTP,
        nodeId: widget.nodeId,
        kw: kw,
        files: widget.files);
    setState(() {
      searchDone = true;
      loading = false;
      if (result != "") {
        searchResult = result.split("\n");
      }
    });
  }

  late final searchLoading = SizedBox(
    width: 50,
    child: UnconstrainedBox(
        child: SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        // color: widget.progressColor,
        valueColor: AlwaysStoppedAnimation<Color>(
            prefs.themeMode == ThemeMode.dark
                ? Colors.white
                : Theme.of(context).primaryColor),
      ),
    )),
  );
  late final sizeBoxText = const SizedBox(
    width: 50,
    child: UnconstrainedBox(child: Text("Search")),
  );

  Widget widgetWrapResult() {
    List<Widget> result = [];
    for (var e in searchResult) {
      result.add(SelectableText(
        e,
        style: TextStyle(
            fontSize: fontSize.toDouble(),
            // color: Colors.white,
            height: 1.37),
      ));
    }
    return Wrap(children: result);
  }

  final List<String> tokens = [
    '[info]',
    '[INFO]',
    '[error]',
    '[ERROR]',
    'warn',
    '[WARN]',
    'warning',
    'WARNING',
    '[debug]',
    '[DEBUG]',
  ];

  Widget highlightText(String text) {
    if (text == "") {
      return SelectableText(
        text,
        style: TextStyle(
            fontSize: fontSize.toDouble(),
            // color: Colors.white,
            height: 1.37),
      );
    }
    final bool isDark = prefs.themeMode == ThemeMode.dark;
    List<InlineSpan>? children = [];
    String token = '';
    List<String> infos = [];
    for (var i = 0; i < tokens.length; i++) {
      if (text.contains(tokens[i])) {
        token = tokens[i];
        infos = text.split(token);
        break;
      }
    }
    if (infos.isEmpty) {
      infos = [text];
    }
    for (var i = 0; i < infos.length; i++) {
      final info = infos[i];
      children.add(TextSpan(
          text: info,
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: fontSize.toDouble(),
              fontWeight: FontWeight.normal)));
      if (i != infos.length - 1) {
        Color color = Colors.green;
        if (token == "[info]" || token == '[INFO]') {
          color = Colors.green;
        } else if (token == '[error]' || token == '[ERROR]') {
          color = Colors.red;
        } else if (token == '[warn]' ||
            token == '[WARN]' ||
            token == '[warning]' ||
            token == '[WARNING]') {
          color = Colors.yellow;
        }
        children.add(TextSpan(
            text: token,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: fontSize.toDouble(),
            )));
      }
    }
    final TextSpan textSpan = TextSpan(children: children);
    return SelectableText.rich(textSpan);
  }

  void reset() {
    loading = false;
    fontSize = 18;
    searchDone = false;
    searchResult = [];
    focusNode.unfocus();
    setState(() {});
  }

  Slider get slider => Slider(
      focusNode: focusNode,
      value: fontSize.toDouble(),
      min: 12,
      max: 32,
      divisions: 20,
      label: "$fontSize",
      onChanged: (double value) {
        setState(() {
          fontSize = value.toInt();
        });
      });

  @override
  Widget build(BuildContext context) {
    CupertinoSearchTextField textField = CupertinoSearchTextField(
        controller: controller,
        style: TextStyle(
            color: prefs.themeMode == ThemeMode.light
                ? Colors.black
                : Colors.white),
        onSuffixTap: () {
          controller.text = " ";
          setState(() {
            searchResult.clear();
            searchDone = false;
          });
        },
        placeholder:
            "Please enter the keywords, separate multiple keywords with semicolons (;)");
    final bool isDark = prefs.themeMode == ThemeMode.dark;
    ListView view = ListView.separated(
      controller: scrollController,
      itemCount: searchResult.length,
      itemBuilder: (BuildContext context, int index) {
        final text = searchResult[index];
        return highlightText(text);
      },
      separatorBuilder: (BuildContext context, int index) {
        return const Text("");
      },
    );
    // Widget view = SingleChildScrollView(
    //   child: widgetWrapResult(),
    // );
    Widget myButtonSearch = ElevatedButton.icon(
        onPressed: loading ? null : _search,
        icon: const Icon(Icons.search),
        label:
            SizedBox(width: 50, child: loading ? searchLoading : sizeBoxText));

    final IconButton buttonResetFontSize =
        IconButton(onPressed: reset, icon: const Icon(Icons.refresh));
    final AppBar appBar = AppBar(
      title: textField,
      leadingWidth: 0,
      leading: null,
      toolbarHeight: kMinInteractiveDimension,
      actions: [
        myButtonSearch,
        const SizedBox(width: 20),
        buttonResetFontSize,
        slider,
        Align(
          alignment: AlignmentDirectional.center,
          child: Text("$fontSize"),
        ),
        const SizedBox(width: 5),
        IconButton(
            onPressed: () {
              if (searchResult.isEmpty) {
                myToast(context, "no result");
                return;
              }
              saveContent(searchResult.join('\n'), "fsearch.log");
            },
            icon: Icon(Icons.save_alt,
                color: isDark ? Colors.white70 : Colors.black)),
        const SizedBox(width: 10),
      ],
    );

    final body = (searchResult.isEmpty && searchDone) ? noResult : view;
    return Scaffold(
      body: Padding(padding: const EdgeInsets.all(10), child: body),
      appBar: appBar,
    );
  }
}
