import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const UpgradeLegendApp());
}

class UpgradeLegendApp extends StatelessWidget {
  const UpgradeLegendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '업그레이드 레전드',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF5C842),
          secondary: Color(0xFFE03030),
        ),
      ),
      home: const MainScreen(),
    );
  }
}