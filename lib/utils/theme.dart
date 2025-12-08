import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF000B58);
  static const Color darkBlue = Color(0xFF003161);
  static const Color teal = Color(0xFF006A67);
  static const Color paleYellow = Color(0xFFFDEB9E);

  static final ThemeData themeData = ThemeData(
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: teal,
      surface: paleYellow,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    useMaterial3: true,
  );
}
