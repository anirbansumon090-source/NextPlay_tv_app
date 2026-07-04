// lib/core/theme/app_theme.dart
// Professional Smart TV Dark Theme — no mobile-specific sizing

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Brand palette
 // static const Color primary   = Color(0xFF06B6D4); // cyan
 
 static const Color primary = Color(0xFF2196F3);

  static const Color accent    = Color(0xFFEF4444); // red (LIVE badge)
  static const Color gold      = Color(0xFFEAB308); // premium badge
  static const Color surface   = Color(0xFF0F172A); // deep navy
  static const Color card      = Color(0xFF1E293B); // card bg
  static const Color cardLight = Color(0xFF334155); // focused card
  static const Color border    = Color(0xFF1E3A8A);
  
  static Color snackbar = Color(0xFFFFFFFF);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: surface,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: accent,
          surface: surface,
          error: Color(0xFFEF4444),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: const TextTheme(
          displayLarge:   TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          headlineLarge:  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyLarge:      TextStyle(color: Colors.white70),
          bodyMedium:     TextStyle(color: Colors.white60),
          bodySmall:      TextStyle(color: Colors.white38),
        ),
        focusColor: primary,
        useMaterial3: true,
      );
}
