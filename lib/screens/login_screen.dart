import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // START 텍스트 깜빡임 애니메이션
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _blinkAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  // 이미 로그인된 유저 → 바로 게임으로
  // 로그인 안 된 유저 → Google 로그인 후 게임으로
  Future<void> _handleTap() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // 이미 로그인된 상태 → 바로 메인 화면
      _goToMain();
    } else {
      // 로그인 필요
      setState(() => _isLoading = true);
      final user = await _authService.signInWithGoogle();
      if (mounted) {
        setState(() => _isLoading = false);
        if (user != null) {
          _goToMain();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인에 실패했습니다. 다시 시도해주세요.')),
          );
        }
      }
    }
  }

  void _goToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      body: GestureDetector(
        onTap: _isLoading ? null : _handleTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 배경 이미지
            Image.asset(
              'assets/images/login_bg.jpg',
              fit: BoxFit.cover,
            ),

            // 하단 그라디언트
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xBB000000),
                    Color(0xEE000000),
                  ],
                  stops: [0.0, 0.5, 0.75, 1.0],
                ),
              ),
            ),

            // 콘텐츠
            SafeArea(
              child: Column(
                children: [
                  // 상단 로고
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: MediaQuery.of(context).size.height * 0.28,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const Spacer(),

                  // 하단 영역
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 60),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 로딩 중일 때
                        if (_isLoading)
                          const CircularProgressIndicator(
                            color: Color(0xFFF5C842),
                          )
                        else ...[
                          // START 깜빡임 텍스트
                          FadeTransition(
                            opacity: _blinkAnimation,
                            child: Text(
                              isLoggedIn ? '- TOUCH TO START -' : '- TOUCH TO LOGIN -',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF5C842),
                                letterSpacing: 3,
                                shadows: [
                                  Shadow(
                                    color: Color(0xFFF5C842),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 로그인 상태 표시
                          if (isLoggedIn)
                            Text(
                              '${FirebaseAuth.instance.currentUser!.displayName ?? '용사'}님 환영합니다',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            )
                          else
                            const Text(
                              'Google 계정으로 로그인이 필요합니다',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}