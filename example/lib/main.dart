import 'package:flutter/material.dart';

import 'home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: const Color(0xFFffd54f),
        primaryColorDark: const Color(0xFFffc107),
        primaryColorLight: const Color(0xFFffecb3),
        dividerColor: const Color(0xFFBDBDBD),
      ),
      home: HomeScreen(),
    );
  }
}
