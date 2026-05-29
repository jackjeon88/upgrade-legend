import 'dart:math';
import 'equipment.dart';
import 'enhance_data.dart';
import 'set_system.dart';

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

  // 피로도 시스템
  int energy;
  static const int maxEnergy = 200;
// 던전 1회 입장 에너지 소모량 (기존 30 → 10으로 감소)
  static const int dungeonEnergyCost = 10;
  static const int energyRechargeSeconds = 300;
  DateTime lastEnergyUpdate;

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
    DateTime? lastEnergyUpdate,
  })  : inventory = inventory ?? [],
        equipped = equipped ?? _defaultEquipped(),
        lastEnergyUpdate = lastEnergyUpdate ?? DateTime.now();

  static List<Equipment> _defaultEquipped() => [
        Equipment(id: 'eq_weapon', name: '낡은 검', grade: ItemGrade.normal, slot: ItemSlot.weapon, weaponType: WeaponType.sword, basePower: 50),
        Equipment(id: 'eq_helmet', name: '천 두건', grade: ItemGrade.normal, slot: ItemSlot.helmet, basePower: 20),
        Equipment(id: 'eq_armor', name: '천 갑옷', grade: ItemGrade.normal, slot: ItemSlot.armor, basePower: 30),
        Equipment(id: 'eq_gloves', name: '천 장갑', grade: ItemGrade.normal, slot: ItemSlot.gloves, basePower: 15),
        Equipment(id: 'eq_shoes', name: '천 신발', grade: ItemGrade.normal, slot: ItemSlot.shoes, basePower: 15),
        Equipment(id: 'eq_shirt', name: '낡은 셔츠', grade: ItemGrade.normal, slot: ItemSlot.shirt, basePower: 15),
        Equipment(id: 'eq_cape', name: '낡은 망토', grade: ItemGrade.normal, slot: ItemSlot.cape, basePower: 15),
        Equipment(id: 'eq_belt', name: '낡은 벨트', grade: ItemGrade.normal, slot: ItemSlot.belt, basePower: 15),
        Equipment(id: 'eq_ring1', name: '나무 반지', grade: ItemGrade.normal, slot: ItemSlot.ring1, basePower: 10),
        Equipment(id: 'eq_ring2', name: '나무 반지', grade: ItemGrade.normal, slot: ItemSlot.ring2, basePower: 10),
        Equipment(id: 'eq_necklace', name: '가죽 목걸이', grade: ItemGrade.normal, slot: ItemSlot.necklace, basePower: 10),
      ];

  // 기본 전투력 + 세트 보너스
  int get totalPower =>
      equipped.fold(0, (sum, e) => sum + e.power) +
      calcTotalSetBonus(equipped);

  // 세트 현황
  List<SetStatus> get setStatuses => calcSetStatus(equipped);

  // 에너지 자연회복
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

 /// 강화 시도
/// [useProtect] 파괴방지권 사용 여부
/// - 성공: 강화 수치 +1
/// - 실패 + 파괴 판정 + 방지권 있음: 그냥 실패 (수치 유지)
/// - 실패 + 파괴 판정 + 방지권 없음: 장비 완전 삭제
EnhanceResult tryEnhance(Equipment equipment, {bool useProtect = false}) {
  final data = getEnhanceData(equipment.grade, equipment.enhanceLevel);
  if (data == null) return EnhanceResult.fail;
  if (gold < data.goldCost) return EnhanceResult.fail;
  if (enhanceStone < data.stoneCost) return EnhanceResult.fail;

  // 재료 차감
  gold -= data.goldCost;
  enhanceStone -= data.stoneCost;
  totalGoldSpent += data.goldCost;
  totalEnhanceCount++;

  final random = Random();
  final roll = random.nextDouble();

  // 성공 판정
  if (roll < data.successRate) {
    equipment.enhanceLevel++;
    successCount++;
    return EnhanceResult.success;
  }

  // 실패 → 파괴 판정
  final destroyRoll = random.nextDouble();
  if (destroyRoll < data.destroyRate) {
    // 파괴 판정 성공
    if (useProtect && protectScroll > 0) {
      // 방지권 있으면 소모 후 그냥 실패 (수치 유지)
      protectScroll--;
      failCount++;
      return EnhanceResult.fail;
    }
    // 방지권 없으면 완전 삭제
    destroyCount++;
    return EnhanceResult.destroy;
  }

  // 일반 실패 (파괴 판정 안 뜸)
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
  }
}