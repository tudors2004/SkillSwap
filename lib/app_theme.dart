import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primaryColor = Color(0xFF9B3A7B);
  static const Color _lightScaffoldBackgroundColor = Color(0xFFF8F4ED);
  static const Color _darkScaffoldBackgroundColor = Color(0xFF121212);
  static const Color _darkCardColor = Color(0xFF1E1E1E);

  static final ThemeData lightTheme = ThemeData.from(
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      secondary: _lightScaffoldBackgroundColor,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      background: _lightScaffoldBackgroundColor,
      surface: Colors.white,
      surfaceTint: Colors.transparent,
      brightness: Brightness.light,
    ),
  ).copyWith(
    scaffoldBackgroundColor: _lightScaffoldBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightScaffoldBackgroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.black54,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
    ),
  );

  static final ThemeData darkTheme = ThemeData.from(
    colorScheme: const ColorScheme.dark(
      primary: _primaryColor,
      secondary: _darkScaffoldBackgroundColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      background: _darkScaffoldBackgroundColor,
      surface: _darkCardColor,
      surfaceTint: Colors.transparent,
      brightness: Brightness.dark,
    ),
  ).copyWith(
    scaffoldBackgroundColor: _darkScaffoldBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkScaffoldBackgroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _darkCardColor,
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkCardColor,
      hintStyle: const TextStyle(color: Colors.white54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
    ),
  );
}
