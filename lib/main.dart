import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fsearch_flutter/pages/home.dart';
import 'package:fsearch_flutter/util/global.dart';
import 'package:fsearch_flutter/util/prefs/prefs.dart';

import 'package:fsearch_flutter/widgets/restart_app.dart';

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
        primaryColor: Colors.blue,
        brightness: Brightness.dark,
        // useMaterial3: true
      ),
      theme: ThemeData(
          // colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          primaryColor: Colors.blueAccent,
          brightness: Brightness.light),
      home: const MyHomePage(),
    );
  }
}
