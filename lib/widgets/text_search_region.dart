import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fsearch/service/search_ws_web.dart';
import 'package:fsearch/util/util.dart';

import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

import '../common/prefs/prefs.dart';
import '../common/queue.dart';

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
  final TextEditingController controller = TextEditingController(text: "");
  final placeHolder =
      "Please enter the keywords, separate multiple keywords with semicolons ;";
  ScrollController scrollController = ScrollController();
  bool loading = false;
  final FocusNode focusNode = FocusNode();
  String searchHTML = "";

  String get normalColor => isDark ? "#ffffff" : "#000000";

  String buildHTML() {
    return '<div id="container" style="font-size: ${prefs.searchHTMLFontSize}px; color: $normalColor;word-wrap:break-word;">$searchHTML</div>';
  }

  @override
  void dispose() {
    super.dispose();
    myPrint("dispose TextSearchRegionState");
    scrollController.dispose();
    controller.dispose();
    eventConsumer?.cancel();
  }

  void search() async {
    final result = await getSearchResultHTML(dataType: 'html');
    if (result == null) return;
    if (result == "") {
      // center h1 no result
      searchHTML = "<h1>No result</h1>";
      controllerW.loadHtmlString(buildHTML());
      return;
    }
    if (result != "") {
      searchHTML = result;
      controllerW.loadHtmlString(buildHTML());
    }
  }

  List<String> get kw {
    final text = controller.text.trim();
    List<String> kw = [];
    final splits = text.split(";");
    for (var ele in splits) {
      kw.add(ele.trim());
    }
    return kw;
  }

  Future<String?> getSearchResultHTML(
      {required String dataType, bool needLoading = true}) async {
    hiddenWebView = false;
    if (loading) {
      myToast(context, "Please wait for the current search to complete");
      return null;
    }
    if (widget.appName == "") {
      myToast(context, "Please select a app");
      return null;
    }
    if (widget.nodeId == 0 && widget.files.isEmpty) {
      myToast(
          context, "Please select at least one file when not selecting a host");
      return "";
    }
    if (needLoading) {
      setState(() {
        loading = true;
      });
    }
    prefs.setSelectFiles(widget.appName, widget.files);
    final result = await searchTextHTTP(
      appName: widget.appName,
      searchPathHTTP: widget.searchPathHTTP,
      nodeId: widget.nodeId,
      kw: kw,
      files: widget.files,
      dataType: dataType,
      fontSize: prefs.searchHTMLFontSize,
      normalColor: normalColor,
    );
    if (needLoading) {
      setState(() {
        loading = false;
      });
    }
    return result.trim();
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
  final controllerW = PlatformWebViewController(
    const PlatformWebViewControllerCreationParams(),
  );

  void eventHandler(Event event) {
    if (event.eventType == EventType.updateTheme) {
      controllerW.loadHtmlString(buildHTML());
    }
  }

  @override
  void initState() {
    super.initState();
    eventConsumer = consume(eventHandler);
    WebViewPlatform.instance ??= WebWebViewPlatform();
  }

  StreamSubscription<Event>? eventConsumer;

  void reset() {
    loading = false;
    searchHTML = "";
    controllerW.loadHtmlString("");
    setState(() {});
  }

  Slider get slider => Slider(
      focusNode: focusNode,
      value: prefs.searchHTMLFontSize.toDouble(),
      min: 12,
      max: 42,
      divisions: 30,
      label: "${prefs.searchHTMLFontSize}",
      onChanged: (double value) {
        prefs.searchHTMLFontSize = value.toInt();
        controllerW.loadHtmlString(buildHTML());
        setState(() {
          // id: container
        });
      });

  get isDark => prefs.themeMode == ThemeMode.dark;
  final overflowXList = ['auto', 'hidden', 'visible', 'scroll'];
  bool hiddenWebView = false;

  Widget get dropButtonOverflowX => DropdownButton<String>(
        value: prefs.searchHTMLOverflowX,
        onChanged: (String? newValue) {
          myPrint("newValue: $newValue");
          prefs.searchHTMLOverflowX = newValue ?? "auto";
          hiddenWebView = false;
          setState(() {});
          controllerW.loadHtmlString(buildHTML());
        },

        onTap: () {
          setState(() {
            hiddenWebView = true;
          });
        },
        // isExpanded: true,
        items: overflowXList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      );

  void downloadLog() async {
    final content =
        await getSearchResultHTML(dataType: 'text', needLoading: false);
    if (content == null) {
      return;
    }
    if (content == "") {
      myToast(context, "No result");
      return;
    }
    saveContent(content, "fsearch.log");
  }

  @override
  Widget build(BuildContext context) {
    final CupertinoSearchTextField textField = CupertinoSearchTextField(
        controller: controller,
        prefixIcon: Tooltip(
            message: placeHolder, child: const Icon(CupertinoIcons.search)),
        style: TextStyle(
            color: prefs.themeMode == ThemeMode.light
                ? Colors.black
                : Colors.white),
        onSuffixTap: () {
          controller.text = " ";
        },
        placeholder: placeHolder);
    final bool isDark = prefs.themeMode == ThemeMode.dark;
    Widget myButtonSearch = ElevatedButton.icon(
        onPressed: loading ? null : search,
        icon: const Icon(Icons.search),
        label:
            SizedBox(width: 50, child: loading ? searchLoading : sizeBoxText));

    final webView = loading
        ? const Center(child: CircularProgressIndicator())
        : PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controllerW),
          ).build(context);
    final row = Row(
      children: [
        Flexible(child: textField),
        const SizedBox(width: 10),

        myButtonSearch,
        const SizedBox(width: 10),
        // const Align(
        //   alignment: AlignmentDirectional.center,
        //   child: Text("overflow-x: "),
        // ),
        // overflow-x DropdownMenu
        // dropButtonOverflowX,
        slider,
        Align(
          alignment: AlignmentDirectional.center,
          child: Text("${prefs.searchHTMLFontSize}"),
        ),
        IconButton(
            onPressed: () {
              prefs.searchHTMLFontSize = 18;
              setState(() {});
              controllerW.loadHtmlString(buildHTML());
            },
            icon: const Icon(Icons.refresh)),
        const SizedBox(width: 10),
        IconButton(onPressed: reset, icon: const Icon(Icons.clear_all)),
        IconButton(
            onPressed: downloadLog,
            icon: Icon(Icons.save_alt,
                color: isDark ? Colors.white70 : Colors.black)),
        const SizedBox(width: 20),
      ],
    );

    return Column(
      children: [
        row,
        Expanded(child: hiddenWebView ? const Text("") : webView),
      ],
    );
  }
}
