// lib/models/attendance.dart

class AttendanceReward {
  final int day;
  final int gold;
  final int diamond;
  final bool isMilestone; // 7, 14, 21, 30일 대박 보상

  const AttendanceReward({
    required this.day,
    this.gold = 0,
    this.diamond = 0,
    this.isMilestone = false,
  });
}

class AttendanceState {
  final int currentDay;         // 1~30, 수령 완료된 마지막 일차
  final DateTime? lastClaimDate; // 마지막 수령 날짜 (날짜만 비교)
  final bool isCompleted;       // 30일 완주 여부

  const AttendanceState({
    this.currentDay = 0,
    this.lastClaimDate,
    this.isCompleted = false,
  });

  /// 오늘 수령 가능한지
  bool get canClaimToday {
    if (isCompleted) return false;
    if (lastClaimDate == null) return true;
    final now = DateTime.now();
    final last = lastClaimDate!;
    return !(now.year == last.year &&
        now.month == last.month &&
        now.day == last.day);
  }

  /// 다음 수령할 일차 (1~30)
  int get nextDay => currentDay + 1;

  AttendanceState copyWith({
    int? currentDay,
    DateTime? lastClaimDate,
    bool? isCompleted,
  }) {
    return AttendanceState(
      currentDay: currentDay ?? this.currentDay,
      lastClaimDate: lastClaimDate ?? this.lastClaimDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentDay': currentDay,
        'lastClaimDate': lastClaimDate?.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory AttendanceState.fromJson(Map<String, dynamic> json) {
    return AttendanceState(
      currentDay: json['currentDay'] ?? 0,
      lastClaimDate: json['lastClaimDate'] != null
          ? DateTime.parse(json['lastClaimDate'])
          : null,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

/// 30일 보상 테이블
const List<AttendanceReward> attendanceRewards = [
  AttendanceReward(day: 1,  gold: 1000),
  AttendanceReward(day: 2,  gold: 2000),
  AttendanceReward(day: 3,  gold: 3000),
  AttendanceReward(day: 4,  gold: 5000),
  AttendanceReward(day: 5,  gold: 8000),
  AttendanceReward(day: 6,  gold: 10000),
  AttendanceReward(day: 7,  gold: 10000, diamond: 8000,  isMilestone: true),
  AttendanceReward(day: 8,  gold: 15000),
  AttendanceReward(day: 9,  gold: 15000),
  AttendanceReward(day: 10, gold: 20000),
  AttendanceReward(day: 11, gold: 20000),
  AttendanceReward(day: 12, gold: 25000),
  AttendanceReward(day: 13, gold: 25000),
  AttendanceReward(day: 14, gold: 30000, diamond: 16000, isMilestone: true),
  AttendanceReward(day: 15, gold: 30000),
  AttendanceReward(day: 16, gold: 30000),
  AttendanceReward(day: 17, gold: 40000),
  AttendanceReward(day: 18, gold: 40000),
  AttendanceReward(day: 19, gold: 50000),
  AttendanceReward(day: 20, gold: 50000),
  AttendanceReward(day: 21, gold: 50000, diamond: 24000, isMilestone: true),
  AttendanceReward(day: 22, gold: 50000),
  AttendanceReward(day: 23, gold: 60000),
  AttendanceReward(day: 24, gold: 60000),
  AttendanceReward(day: 25, gold: 70000),
  AttendanceReward(day: 26, gold: 70000),
  AttendanceReward(day: 27, gold: 80000),
  AttendanceReward(day: 28, gold: 80000),
  AttendanceReward(day: 29, gold: 100000),
  AttendanceReward(day: 30, gold: 100000, diamond: 32000, isMilestone: true),
];

/// 특정 일차 보상 반환 (1-indexed)
AttendanceReward getRewardForDay(int day) {
  assert(day >= 1 && day <= 30);
  return attendanceRewards[day - 1];
}
