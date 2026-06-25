import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      // 항상 로그인 화면(타이틀)부터 시작
      home: const LoginScreen(),
    );
  }
}