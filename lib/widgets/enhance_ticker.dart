// lib/widgets/enhance_ticker.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class EnhanceTicker extends StatefulWidget {
  /// 외부에서 실제 강화 결과를 추가할 때 사용
  final Stream<TickerMessage> messageStream;

  const EnhanceTicker({super.key, required this.messageStream});

  @override
  State<EnhanceTicker> createState() => _EnhanceTickerState();
}

class _EnhanceTickerState extends State<EnhanceTicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<TickerMessage> _queue = [];
  TickerMessage? _current;
  StreamSubscription? _sub;
  Timer? _fakeTimer;

  final _rng = Random();

  // 랜덤 닉네임 풀
  static const List<String> _nickPool = [
    '전사왕', '마법사킹', '용사님', '강화왕', '레전드', '파괴자', '최강자',
    '어둠기사', '불꽃검사', '번개술사', '드래곤슬레이어', '신화전사', '절대강자',
    '무적검객', '천하제일', '폭풍기사', '심연의왕', '창세신', '멸절자', '용왕',
    'shadow', 'blade', 'storm', 'dark', 'legend', 'ultra', 'hyper',
    'alpha', 'omega', 'zerus', 'kairo', 'strao', 'nexon', 'blaze',
    'frost', 'lunar', 'solar', 'astro', 'viper', 'raven',
  ];

  static const List<String> _gradeNames = [
    '노멀', '매직', '레어', '유니크', '에픽', '레전더리'
  ];

  static const List<int> _maxEnhance = [5, 8, 11, 14, 17, 20];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _animation = Tween<double>(begin: 1.0, end: -1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _showNext();
      }
    });

    // 실제 강화 결과 수신
    _sub = widget.messageStream.listen((msg) {
      _queue.insert(0, msg); // 내 결과는 맨 앞에
      if (_current == null) _showNext();
    });

    // 가짜 알림 주기적 생성 (8~15초마다)
    _scheduleFake();
  }

  void _scheduleFake() {
    final delay = 8 + _rng.nextInt(8); // 8~15초
    _fakeTimer = Timer(Duration(seconds: delay), () {
      _queue.add(_generateFake());
      if (_current == null) _showNext();
      _scheduleFake();
    });
  }

  TickerMessage _generateFake() {
    final nick = _nickPool[_rng.nextInt(_nickPool.length)];
    final maskedNick = nick.length > 3
        ? '${nick.substring(0, nick.length - 3)}***'
        : '${nick[0]}***';

    // 레전더리/에픽 위주로 (풍자 포인트)
    final gradeWeights = [0, 0, 1, 3, 8, 12]; // 노멀/매직은 0
    final totalWeight = gradeWeights.reduce((a, b) => a + b);
    int roll = _rng.nextInt(totalWeight);
    int gradeIndex = 0;
    for (int i = 0; i < gradeWeights.length; i++) {
      roll -= gradeWeights[i];
      if (roll < 0) { gradeIndex = i; break; }
    }

    final maxLv = _maxEnhance[gradeIndex];
    // 높은 강화 수치 위주 (있어보이게)
    final level = max(maxLv - 4, _rng.nextInt(maxLv) + 1);
    final isSuccess = _rng.nextDouble() < 0.6;
    final isDestroy = !isSuccess && _rng.nextDouble() < 0.3;

    return TickerMessage(
      nickname: maskedNick,
      grade: _gradeNames[gradeIndex],
      gradeIndex: gradeIndex,
      level: level,
      type: isDestroy
          ? TickerType.destroy
          : isSuccess
              ? TickerType.success
              : TickerType.fail,
    );
  }

  void _showNext() {
    if (_queue.isEmpty) {
      setState(() => _current = null);
      return;
    }
    setState(() => _current = _queue.removeAt(0));
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _sub?.cancel();
    _fakeTimer?.cancel();
    super.dispose();
  }

  Color _gradeColor(int index) {
    const colors = [
      Colors.grey,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.red,
    ];
    return colors[index.clamp(0, 5)];
  }

  @override
  Widget build(BuildContext context) {
    if (_current == null) return const SizedBox(height: 28);

    final msg = _current!;
    final text = _buildText(msg);
    final color = _gradeColor(msg.gradeIndex);

    return Container(
      height: 28,
      color: const Color(0xFF0A0A14),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return FractionalTranslation(
            translation: Offset(_animation.value, 0),
            child: child,
          );
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4,
                  height: 14,
                  color: color,
                  margin: const EdgeInsets.only(right: 6),
                ),
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: color.withOpacity(0.5), blurRadius: 6),
                    ],
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildText(TickerMessage msg) {
    switch (msg.type) {
      case TickerType.success:
        return '${msg.nickname}님이 ${msg.grade} +${msg.level} 강화 성공! 🎉';
      case TickerType.fail:
        return '${msg.nickname}님의 ${msg.grade} +${msg.level} 강화 실패... 😢';
      case TickerType.destroy:
        return '${msg.nickname}님의 ${msg.grade} 장비가 파괴되었습니다 💥';
    }
  }
}

// ── 데이터 모델 ──

enum TickerType { success, fail, destroy }

class TickerMessage {
  final String nickname;
  final String grade;
  final int gradeIndex;
  final int level;
  final TickerType type;

  const TickerMessage({
    required this.nickname,
    required this.grade,
    required this.gradeIndex,
    required this.level,
    required this.type,
  });
}
