import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:fsearch_flutter/service/search_ws_no_web.dart'
    if (dart.library.html) 'package:fsearch_flutter/service/search_ws_web.dart';

import 'package:fsearch_flutter/util/util.dart';

import '../util/prefs/prefs.dart';

class TextSearchRegion extends StatefulWidget {
  const TextSearchRegion(
      {super.key,
      required this.appName,
      required this.searchPathSSE,
      required this.nodeId,
      required this.files});

  final String appName;
  final String searchPathSSE;
  final int nodeId;
  final List<String> files;

  @override
  State<StatefulWidget> createState() {
    return TextSearchRegionState();
  }
}

class TextSearchRegionState extends State<TextSearchRegion> {
  List<String> searchResult = [];

  final controller = TextEditingController(text: " ");
  StreamSubscription? subscription;

  Future<void> _search() async {
    if (loading) {
      setState(() {
        loading = false;
      });
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
    myPrint("search start");

    setState(() {
      searchResult.clear();
      searchDone = false;
      loading = true;
    });
    if (searchResult.isNotEmpty) {
      scrollController.jumpTo(0);
    }
    await subscription?.cancel();
    subscription = await searchText(
        appName: widget.appName,
        searchPathSSE: widget.searchPathSSE,
        nodeId: widget.nodeId,
        kw: kw,
        files: widget.files,
        onData: (data) {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            setState(() {
              searchResult.add(data);
            });
          });
        },
        onClose: () {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            myPrint("search close");
            setState(() {
              searchDone = true;
              loading = false;
            });
          });
        });
  }

  ScrollController scrollController = ScrollController();
  bool searchDone = false;
  bool loading = false;

  @override
  void dispose() {
    super.dispose();
    myPrint("dispose search");
    scrollController.dispose();
    controller.dispose();
    subscription?.cancel();
  }

  FocusNode focusNode = FocusNode();
  int fontSize = 18;
  Widget noResult = Center(
      child: SelectableText("no result",
          style: TextStyle(
              color: prefs.themeMode == ThemeMode.light
                  ? Colors.black
                  : Colors.white,
              fontSize: 48)));

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
        if (text != '') {
          List<InlineSpan>? children = [];
          String token = '[info]';
          List<String> infos = text.split(token);
          if (infos.length == 1) {
            token = '[error]';
            infos = text.split(token);
          }

          if (infos.length == 1) {
            token = '[INFO]';
            infos = text.split(token);
          }
          if (infos.length == 1) {
            token = '[warn]';
            infos = text.split(token);
          }
          if (infos.length == 1) {
            token = '[warning]';
            infos = text.split(token);
          }
          if (infos.length == 1) {
            token = '[WARN]';
            infos = text.split(token);
          }

          if (infos.length == 1) {
            token = '[ERROR]';
            infos = text.split(token);
          }
          if (infos.length == 1) {
            token = '[debug]';
            infos = text.split(token);
          }
          if (infos.length == 1) {
            token = '[DEBUG]';
            infos = text.split(token);
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
              Color color;
              if (token == '[error]' || token == '[ERROR]') {
                color = Colors.red;
              } else {
                color = Colors.green;
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

        return SelectableText(
          text,
          style: TextStyle(
              fontSize: fontSize.toDouble(),
              // color: Colors.white,
              height: 1.37),
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return const Text("\n");
      },
    );
    // Widget view = SingleChildScrollView(
    //   child: widgetWrapResult(),
    // );
    Widget myButtonSearch = ElevatedButton.icon(
        onPressed: _search,
        icon: const Icon(Icons.search),
        label:
            SizedBox(width: 50, child: loading ? searchLoading : sizeBoxText));
    final Slider slider = Slider(
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
    IconButton buttonResetFontSize = IconButton(
        onPressed: () {
          setState(() {
            subscription?.cancel();
            loading = false;
            fontSize = 18;
            searchDone = false;
            searchResult = [];
            focusNode.unfocus();
          });
        },
        icon: const Icon(Icons.refresh));
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
    // final body =
    //     (searchResult.isEmpty && controller.text != "") ? noResult : view;
    final body = (searchResult.isEmpty && searchDone) ? noResult : view;
    return Scaffold(
      body: Padding(padding: const EdgeInsets.all(10), child: body),
      appBar: appBar,
    );
  }
}
