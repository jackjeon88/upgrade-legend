// lib/models/game_state.dart
// ✅ 변경사항: attendance 필드 추가, claimAttendance() 메서드 추가

import 'dart:math';
import 'equipment.dart';
import 'enhance_data.dart';
import 'set_system.dart';
import 'attendance.dart';
import '../utils/sound_manager.dart';

enum EnhanceResult { success, fail, destroy }

class GameState {
  int gold;
  int diamond;
  int enhanceStone;
  int protectScroll;
  List<Equipment> inventory;
  List<Equipment> equipped;
  int totalEnhanceCount;
  int successCount;
  int failCount;
  int destroyCount;
  int totalGoldSpent;
    int premiumChargeCount = 0; // 110만 다이아 충전 횟수 (강화 성공률 부스터)

  // 피로도 시스템
  int energy;
  static const int maxEnergy = 200;
  static const int dungeonEnergyCost = 10;
  static const int energyRechargeSeconds = 300;
  DateTime lastEnergyUpdate;

  // ✅ 출석 시스템
  AttendanceState attendance;

  GameState({
    this.gold = 5000,
    this.diamond = 0,
    this.enhanceStone = 10,
    this.protectScroll = 0,
    List<Equipment>? inventory,
    List<Equipment>? equipped,
    this.totalEnhanceCount = 0,
    this.successCount = 0,
    this.failCount = 0,
    this.destroyCount = 0,
    this.totalGoldSpent = 0,
    this.energy = 200,
    this.premiumChargeCount = 0,

    DateTime? lastEnergyUpdate,
    AttendanceState? attendance,
  })  : inventory = inventory ?? [],
        equipped = equipped ?? _defaultEquipped(),
        lastEnergyUpdate = lastEnergyUpdate ?? DateTime.now(),
        attendance = attendance ?? const AttendanceState();

  static List<Equipment> _defaultEquipped() => [
        Equipment(id: 'eq_weapon',   name: '낡은 검',     grade: ItemGrade.normal, slot: ItemSlot.weapon,   weaponType: WeaponType.sword, basePower: 50),
        Equipment(id: 'eq_helmet',   name: '천 두건',     grade: ItemGrade.normal, slot: ItemSlot.helmet,   basePower: 20),
        Equipment(id: 'eq_armor',    name: '천 갑옷',     grade: ItemGrade.normal, slot: ItemSlot.armor,    basePower: 30),
        Equipment(id: 'eq_gloves',   name: '천 장갑',     grade: ItemGrade.normal, slot: ItemSlot.gloves,   basePower: 15),
        Equipment(id: 'eq_shoes',    name: '천 신발',     grade: ItemGrade.normal, slot: ItemSlot.shoes,    basePower: 15),
        Equipment(id: 'eq_shirt',    name: '낡은 셔츠',   grade: ItemGrade.normal, slot: ItemSlot.shirt,    basePower: 15),
        Equipment(id: 'eq_cape',     name: '낡은 망토',   grade: ItemGrade.normal, slot: ItemSlot.cape,     basePower: 15),
        Equipment(id: 'eq_belt',     name: '낡은 벨트',   grade: ItemGrade.normal, slot: ItemSlot.belt,     basePower: 15),
        Equipment(id: 'eq_ring1',    name: '나무 반지',   grade: ItemGrade.normal, slot: ItemSlot.ring1,    basePower: 10),
        Equipment(id: 'eq_ring2',    name: '나무 반지',   grade: ItemGrade.normal, slot: ItemSlot.ring2,    basePower: 10),
        Equipment(id: 'eq_necklace', name: '가죽 목걸이', grade: ItemGrade.normal, slot: ItemSlot.necklace, basePower: 10),
      ];

  int get totalPower =>
      equipped.fold(0, (sum, e) => sum + e.power) +
      calcTotalSetBonus(equipped);

  List<SetStatus> get setStatuses => calcSetStatus(equipped);

  void updateEnergy() {
    final now = DateTime.now();
    final elapsed = now.difference(lastEnergyUpdate).inSeconds;
    final recovered = elapsed ~/ energyRechargeSeconds;
    if (recovered > 0) {
      energy = (energy + recovered).clamp(0, maxEnergy);
      lastEnergyUpdate = lastEnergyUpdate
          .add(Duration(seconds: recovered * energyRechargeSeconds));
    }
  }

  int get secondsUntilNextEnergy {
    final elapsed = DateTime.now().difference(lastEnergyUpdate).inSeconds;
    return energyRechargeSeconds - (elapsed % energyRechargeSeconds);
  }

  bool get canEnterDungeon => energy >= dungeonEnergyCost;

  bool consumeEnergy() {
    updateEnergy();
    if (energy < dungeonEnergyCost) return false;
    energy -= dungeonEnergyCost;
    return true;
  }

  void rechargeEnergyWithDiamond() {
    if (diamond >= 30) {
      diamond -= 30;
      energy = maxEnergy;
    }
  }

  void exchangeDiamondToGold(int diamondAmount) {
    if (diamond >= diamondAmount) {
      diamond -= diamondAmount;
      gold += diamondAmount * 1000;
    }
  }

  // ✅ 출석 보상 수령
  // 반환값: 수령한 AttendanceReward (실패 시 null)
  AttendanceReward? claimAttendance() {
    if (!attendance.canClaimToday) return null;
    if (attendance.nextDay > 30) return null;

    final reward = getRewardForDay(attendance.nextDay);

    // 보상 지급
    gold += reward.gold;
    diamond += reward.diamond;

    // 출석 상태 업데이트
    final isCompleted = attendance.nextDay == 30;
    attendance = attendance.copyWith(
      currentDay: attendance.nextDay,
      lastClaimDate: DateTime.now(),
      isCompleted: isCompleted,
    );

    return reward;
  }

  EnhanceResult tryEnhance(Equipment equipment, {bool useProtect = false}) {
    final data = getEnhanceData(equipment.grade, equipment.enhanceLevel);
    if (data == null) return EnhanceResult.fail;
    if (gold < data.goldCost) return EnhanceResult.fail;
    if (enhanceStone < data.stoneCost) return EnhanceResult.fail;

    gold -= data.goldCost;
    enhanceStone -= data.stoneCost;
    totalGoldSpent += data.goldCost;
    totalEnhanceCount++;

    final random = Random();
    final roll = random.nextDouble();

    final boostedRate = (data.successRate + premiumChargeCount * 0.10).clamp(0.0, 1.0);
if (roll < boostedRate) {
      equipment.enhanceLevel++;
      successCount++;
      return EnhanceResult.success;
    }

// 방지권 사용 시 강화 시도마다 무조건 1개 소모
    if (useProtect && protectScroll > 0) {
      protectScroll--;
    }

    final destroyRoll = random.nextDouble();
    if (destroyRoll < data.destroyRate) {
      if (useProtect) {
        failCount++;
        return EnhanceResult.fail;
      }
      destroyCount++;
      return EnhanceResult.destroy;
    }

    failCount++;
    return EnhanceResult.fail;
  }

  void buyStoneWithGold() {
    if (gold >= 500) {
      gold -= 500;
      enhanceStone += 1;
    }
  }

  void buyStoneWithDiamond(int amount) {
    final cost = amount == 10 ? 30 : 50;
    if (diamond >= cost) {
      diamond -= cost;
      enhanceStone += amount;
    }
  }

  void buyProtectScroll() {
    if (diamond >= 50) {
      diamond -= 50;
      protectScroll += 3;
    }
  }

void chargeDiamond(int amount) {
  diamond += amount;
  // 110만 다이아 충전 시 카운트 증가
  if (amount == 1100000) premiumChargeCount++;
}
}
