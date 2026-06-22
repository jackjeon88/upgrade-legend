// lib/widgets/stat_bottom_sheet.dart

import 'package:flutter/material.dart';
import '../models/equipment.dart';

// 전투력 숫자 눌렀을 때 올라오는 스탯 바텀시트
void showStatBottomSheet(BuildContext context, List<Equipment> equipped, int premiumChargeCount) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _StatBottomSheet(
      equipped: equipped,
      premiumChargeCount: premiumChargeCount,
    ),
  );
}

class _StatBottomSheet extends StatelessWidget {
  final List<Equipment> equipped;
  final int premiumChargeCount;

  const _StatBottomSheet({
    required this.equipped,
    required this.premiumChargeCount,
  });

  // 장착 장비 전체 스탯 합산
  StatValues get _totalStats {
    return equipped.fold(
      StatValues.zero,
      (sum, e) => sum + e.fakeStats,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _totalStats;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // 타이틀
          const Text(
            '⚔️ 캐릭터 스탯',
            style: TextStyle(
              color: Color(0xFFF5C842),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '장착 장비 기준 합산 스탯',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 20),

          // 스탯 목록
          _statRow('⚔️ 공격력', stats.atk, Colors.redAccent),
          _statRow('🛡️ 방어력', stats.def, Colors.blueAccent),
          _statRow('❤️ 체력',   stats.hp,  Colors.pinkAccent),
          _statRow('✨ 마력',   stats.mag, Colors.purpleAccent),
          _statRow('💨 민첩',   stats.agi, Colors.greenAccent),
          const SizedBox(height: 12),

          // 구분선
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          // 숨겨진 강화 성공률 부스터
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
  '🔮 +@화.확ㄹㅠㄹ 보ㅈㅓㅇ%',
  style: TextStyle(color: Colors.white70, fontSize: 13),
),
                  const SizedBox(width: 6),
                  const Tooltip(
                    message: '특별한 조건에서 활성화되는 숨겨진 보정입니다',
                    child: Icon(Icons.help_outline, color: Colors.white30, size: 14),
                  ),
                ],
              ),
              // 110만 다이아 충전 횟수 x10% 표시
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  border: Border.all(color: Colors.purple.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+${(premiumChargeCount * 10).clamp(0, 100)}%',
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 풍자 포인트 설명
          const Text(
            '* +???% 자동 적용됩니다.',
            style: TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // 스탯 한 줄
  Widget _statRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Row(
            children: [
              // 스탯 바
              Container(
                width: 100,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (value / 50000).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 60,
                child: Text(
                  _format(value),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _format(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}만';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}천';
    return '$n';
  }
}
