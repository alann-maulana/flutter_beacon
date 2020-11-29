import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'app_scanning.dart' as s;

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: s.MyApp(),
    ),
  );
}
