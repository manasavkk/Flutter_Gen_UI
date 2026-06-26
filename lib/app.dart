import 'package:flutter/material.dart';
import 'package:genui_template/home_page.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          surface: const Color(0xFF12121A),
          primary: Colors.cyanAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF08080F),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
          titleMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardColor: const Color(0xFF1A1A2E),
        dividerColor: Colors.white12,
      ),
      home: const HomePage(),
    );
  }
}
