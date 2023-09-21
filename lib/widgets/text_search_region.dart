import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:fsearch_flutter/service/search_ws_no_web.dart'
    if (dart.library.html) 'package:fsearch_flutter/service/search_ws_web.dart';

import 'package:fsearch_flutter/util/util.dart';
import 'package:fsearch_flutter/widgets/loading_button.dart';

import '../util/prefs/prefs.dart';

class TextSearchRegion extends StatefulWidget {
  const TextSearchRegion(
      {super.key,
      required this.appName,
      required this.searchPathWS,
      required this.nodeId,
      required this.files});

  final String appName;
  final String searchPathWS;
  final int nodeId;
  final List<String> files;

  @override
  State<StatefulWidget> createState() {
    return TextSearchRegionState();
  }
}

class TextSearchRegionState extends State<TextSearchRegion> {
  List<String> searchResult = [];

  final controller = TextEditingController();
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
    if (controller.text == "") {
      myToast(context, "please enter the keywords");
      return;
    }
    List<String> kw = [];
    final splits = controller.text.split(";");
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
    });
    if (searchResult.isNotEmpty) {
      scrollController.jumpTo(0);
    }
    await subscription?.cancel();
    subscription = await searchText(
        appName: widget.appName,
        searchPathWS: widget.searchPathWS,
        nodeId: widget.nodeId,
        kw: kw,
        files: widget.files,
        onData: (data) {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            setState(() {
              searchResult.add(data);
              myPrint(searchResult.length);
            });
          });
        },
        onClose: () {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            setState(() {
              searchDone = true;
              loading=false;
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
    subscription?.cancel();
  }

  FocusNode focusNode = FocusNode();
  int fontSize = 18;
  Widget noResult = Center(
      child: SelectableText("无结果",
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

  @override
  Widget build(BuildContext context) {
    CupertinoSearchTextField textField = CupertinoSearchTextField(
        controller: controller,
        style: TextStyle(
            color: prefs.themeMode == ThemeMode.light
                ? Colors.black
                : Colors.white),
        onSuffixTap: () {
          controller.text = "";
          setState(() {
            searchResult.clear();
          });
        },
        placeholder:
            "Please enter the keywords, separate multiple keywords with semicolons (;)");
    // MyButton myButtonSearch = MyButton(
    //     text: "Search",
    //     onPressed: _search,
    //     buttonStyleBtn: ButtonStyleBtn.elevatedButtonIcon,
    //     width: 50);
    final view = ListView.separated(
      controller: scrollController,
      itemCount: searchResult.length,
      itemBuilder: (BuildContext context, int index) {
        return SelectableText(
          searchResult[index],
          style: TextStyle(
              fontSize: fontSize.toDouble(),
              // color: Colors.white,
              height: 1.37),
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return const Divider();
      },
    );
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
        Text("$fontSize"),
        const SizedBox(width: 5),
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
