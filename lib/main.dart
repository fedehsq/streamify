import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streamify/SourceSearch.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.select): ActivateIntent(),
      },
      child: MaterialApp(
        title: 'Flutter Demo',
        darkTheme: ThemeData(
          accentColor: Colors.red,
         // fontFamily: 'Poppins',
          brightness: Brightness.dark,
          dividerColor: Colors.transparent
          /* dark theme settings */
        ),
        themeMode: ThemeMode.dark,
        home: SourceSearch(),
      ),
    );
  }
}