// lib/app/app.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../presentation/providers/app_state.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/player_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/splash_screen.dart';

class OttKingApp extends StatelessWidget {
  const OttKingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode =
        context.select<AppState, ThemeMode>((s) => s.themeMode);

    return MaterialApp(
      title: 'NEXTPLAY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: '/splash',
      
      navigatorObservers: [
        HomeScreen.routeObserver,
        PlayerScreen.routeObserver,
        SettingsScreen.routeObserver,
      ],
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/home': (_) => const HomeScreen(),
        '/player': (_) => const PlayerScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
