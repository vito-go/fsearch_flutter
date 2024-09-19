import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:fsearch/pages/home.dart';
import 'package:fsearch/util/util.dart';

import 'common/prefs/prefs.dart';
import 'common/queue.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initGlobalPrefs();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  void eventHandler(Event event) {
    if (event.eventType == EventType.updateTheme) {
      setState(() {});
    }
  }

  StreamSubscription<Event>? eventConsumer;

  @override
  dispose() {
    super.dispose();
    eventConsumer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    eventConsumer = consume(eventHandler);
    prefs.locationOrigin = html.window.location.origin;
    myPrint("locationOrigin=${prefs.locationOrigin}");
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final inversePrimary = Theme.of(context).colorScheme.inversePrimary;
    return MaterialApp(
      // navigatorObservers: [BannerObserver()],
      title: 'File Search',
      debugShowCheckedModeBanner: false,
      themeMode: prefs.themeMode,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(color: Colors.black54),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.grey,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.teal,
        ),
      ),
      theme: ThemeData(
        drawerTheme: const DrawerThemeData(
            // backgroundColor: Colors.orange.shade50,
            ),
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
        ),
        colorScheme: ColorScheme.fromSeed(
          primary: Colors.teal,
          seedColor: Colors.teal,
          // surface: Colors.blue.shade100,
        ),
        useMaterial3: true,
      ),
      home: const Home(),

      // scrollBehavior: MyCustomScrollBehavior(),
    );
  }
}
