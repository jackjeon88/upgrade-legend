// lib/screens/attendance_screen.dart

import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/attendance.dart';
import '../models/save_manager.dart';

class AttendanceScreen extends StatefulWidget {
  final GameState gameState;
  final VoidCallback onRewardClaimed;

  const AttendanceScreen({
    super.key,
    required this.gameState,
    required this.onRewardClaimed,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  AttendanceReward? _lastReward;

  void _claim() async {
    final reward = widget.gameState.claimAttendance();
    if (reward == null) return;

    await SaveManager.save(widget.gameState);
    widget.onRewardClaimed();

    setState(() => _lastReward = reward);

    if (!mounted) return;
    _showRewardDialog(reward);
  }

  void _showRewardDialog(AttendanceReward reward) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          reward.isMilestone ? '🎉 대박 보상!' : '✅ 출석 완료!',
          style: TextStyle(
            color: reward.isMilestone ? Colors.amber : Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${reward.day}일차 보상',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (reward.gold > 0)
              _rewardRow('💰', '골드', _formatNumber(reward.gold)),
            if (reward.diamond > 0)
              _rewardRow('💎', '다이아', _formatNumber(reward.diamond)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  Widget _rewardRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$emoji ', style: const TextStyle(fontSize: 20)),
          Text(
            '$label +$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(n % 10000 == 0 ? 0 : 1)}만';
    return n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final attendance = widget.gameState.attendance;
    final canClaim = attendance.canClaimToday;
    final currentDay = attendance.currentDay;
    final isCompleted = attendance.isCompleted;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('📅 출석 보상', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 상단 상태
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E1E2E),
            child: Column(
              children: [
                Text(
                  isCompleted
                      ? '🎊 30일 출석 완주!'
                      : canClaim
                          ? '오늘 보상을 받으세요!'
                          : '내일 또 오세요 👋',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  isCompleted
                      ? '한 달 동안 수고했어요!'
                      : '$currentDay / 30일 완료',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                if (canClaim && !isCompleted) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _claim,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      '${currentDay + 1}일차 보상 받기',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 30일 달력 그리드
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: 30,
              itemBuilder: (context, index) {
                final day = index + 1;
                final reward = getRewardForDay(day);
                final isClaimed = day <= currentDay;
                final isNext = day == currentDay + 1;
                final isMilestone = reward.isMilestone;

                return _DayCell(
                  day: day,
                  reward: reward,
                  isClaimed: isClaimed,
                  isNext: isNext && canClaim,
                  isMilestone: isMilestone,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final AttendanceReward reward;
  final bool isClaimed;
  final bool isNext;
  final bool isMilestone;

  const _DayCell({
    required this.day,
    required this.reward,
    required this.isClaimed,
    required this.isNext,
    required this.isMilestone,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;

    if (isClaimed) {
      borderColor = Colors.green.shade700;
      bgColor = Colors.green.shade900.withOpacity(0.4);
    } else if (isNext) {
      borderColor = Colors.amber;
      bgColor = Colors.amber.withOpacity(0.15);
    } else if (isMilestone) {
      borderColor = Colors.orange.shade400;
      bgColor = Colors.orange.withOpacity(0.08);
    } else {
      borderColor = Colors.white12;
      bgColor = const Color(0xFF1E1E2E);
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isMilestone || isNext ? 2 : 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 일차
          Text(
            '$day일',
            style: TextStyle(
              color: isClaimed ? Colors.green.shade300 : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),

          // 체크 or 보상 아이콘
          if (isClaimed)
            const Icon(Icons.check_circle, color: Colors.green, size: 22)
          else ...[
            if (reward.diamond > 0)
              Text('💎', style: TextStyle(fontSize: isMilestone ? 18 : 14))
            else
              Text('💰', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            if (reward.diamond > 0)
              Text(
                _short(reward.diamond),
                style: TextStyle(
                  color: Colors.cyan.shade300,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (reward.gold > 0)
              Text(
                _short(reward.gold),
                style: const TextStyle(color: Colors.yellow, fontSize: 9),
              ),
          ],
        ],
      ),
    );
  }

  String _short(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(0)}만';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}천';
    return '$n';
  }
}
