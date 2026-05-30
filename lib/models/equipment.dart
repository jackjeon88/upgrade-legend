// lib/models/equipment.dart

enum ItemGrade { normal, magic, rare, unique, epic, legendary }

enum ItemSlot { weapon, helmet, armor, gloves, shoes, shirt, cape, belt, ring1, ring2, necklace }

enum WeaponType { sword, blade, axe, spear, bow }

extension ItemGradeExt on ItemGrade {
  String get name {
    switch (this) {
      case ItemGrade.normal: return '노멀';
      case ItemGrade.magic: return '매직';
      case ItemGrade.rare: return '레어';
      case ItemGrade.unique: return '유니크';
      case ItemGrade.epic: return '에픽';
      case ItemGrade.legendary: return '레전더리';
    }
  }

  int get maxEnhance {
    switch (this) {
      case ItemGrade.normal: return 5;
      case ItemGrade.magic: return 8;
      case ItemGrade.rare: return 11;
      case ItemGrade.unique: return 14;
      case ItemGrade.epic: return 17;
      case ItemGrade.legendary: return 20;
    }
  }

  int get finalStageStart {
    switch (this) {
      case ItemGrade.normal: return 999; // 노멀은 최종강화단계 없음
      case ItemGrade.magic: return 6;
      case ItemGrade.rare: return 9;
      case ItemGrade.unique: return 12;
      case ItemGrade.epic: return 15;
      case ItemGrade.legendary: return 18;
    }
  }
}

extension ItemSlotExt on ItemSlot {
  String get displayName {
    switch (this) {
      case ItemSlot.weapon: return '무기';
      case ItemSlot.helmet: return '투구';
      case ItemSlot.armor: return '갑옷';
      case ItemSlot.gloves: return '장갑';
      case ItemSlot.shoes: return '신발';
      case ItemSlot.shirt: return '티셔츠';
      case ItemSlot.cape: return '망토';
      case ItemSlot.belt: return '벨트';
      case ItemSlot.ring1: return '반지1';
      case ItemSlot.ring2: return '반지2';
      case ItemSlot.necklace: return '목걸이';
    }
  }

  String get emoji {
    switch (this) {
      case ItemSlot.weapon: return '⚔️';
      case ItemSlot.helmet: return '🪖';
      case ItemSlot.armor: return '🧥';
      case ItemSlot.gloves: return '🧤';
      case ItemSlot.shoes: return '👢';
      case ItemSlot.shirt: return '👕';
      case ItemSlot.cape: return '🧣';
      case ItemSlot.belt: return '🔗';
      case ItemSlot.ring1: return '💍';
      case ItemSlot.ring2: return '💍';
      case ItemSlot.necklace: return '📿';
    }
  }

  // 슬롯별 스탯 비율 (공격력/방어력/체력/마력/민첩) — 합계 1.0
  // 무기는 공격력 위주, 방어구는 방어력/체력, 악세서리는 마력/민첩
  StatRatio get statRatio {
    switch (this) {
      case ItemSlot.weapon:
        return const StatRatio(atk: 0.70, def: 0.05, hp: 0.05, mag: 0.10, agi: 0.10);
      case ItemSlot.helmet:
        return const StatRatio(atk: 0.05, def: 0.30, hp: 0.45, mag: 0.10, agi: 0.10);
      case ItemSlot.armor:
        return const StatRatio(atk: 0.05, def: 0.45, hp: 0.35, mag: 0.05, agi: 0.10);
      case ItemSlot.gloves:
        return const StatRatio(atk: 0.25, def: 0.15, hp: 0.10, mag: 0.20, agi: 0.30);
      case ItemSlot.shoes:
        return const StatRatio(atk: 0.10, def: 0.10, hp: 0.15, mag: 0.10, agi: 0.55);
      case ItemSlot.shirt:
        return const StatRatio(atk: 0.10, def: 0.25, hp: 0.40, mag: 0.15, agi: 0.10);
      case ItemSlot.cape:
        return const StatRatio(atk: 0.10, def: 0.20, hp: 0.20, mag: 0.30, agi: 0.20);
      case ItemSlot.belt:
        return const StatRatio(atk: 0.15, def: 0.25, hp: 0.30, mag: 0.15, agi: 0.15);
      case ItemSlot.ring1:
        return const StatRatio(atk: 0.15, def: 0.10, hp: 0.10, mag: 0.45, agi: 0.20);
      case ItemSlot.ring2:
        return const StatRatio(atk: 0.20, def: 0.10, hp: 0.10, mag: 0.40, agi: 0.20);
      case ItemSlot.necklace:
        return const StatRatio(atk: 0.15, def: 0.10, hp: 0.15, mag: 0.35, agi: 0.25);
    }
  }
}

// 스탯 비율 데이터 클래스
class StatRatio {
  final double atk; // 공격력
  final double def; // 방어력
  final double hp;  // 체력
  final double mag; // 마력
  final double agi; // 민첩

  const StatRatio({
    required this.atk,
    required this.def,
    required this.hp,
    required this.mag,
    required this.agi,
  });
}

// 스탯 값 데이터 클래스
class StatValues {
  final int atk;
  final int def;
  final int hp;
  final int mag;
  final int agi;

  const StatValues({
    required this.atk,
    required this.def,
    required this.hp,
    required this.mag,
    required this.agi,
  });

  // 두 스탯 합산
  StatValues operator +(StatValues other) {
    return StatValues(
      atk: atk + other.atk,
      def: def + other.def,
      hp: hp + other.hp,
      mag: mag + other.mag,
      agi: agi + other.agi,
    );
  }

  static const StatValues zero = StatValues(atk: 0, def: 0, hp: 0, mag: 0, agi: 0);
}

class EnhanceData {
  final int goldCost;
  final int stoneCost;
  final double successRate;
  final double destroyRate;

  const EnhanceData({
    required this.goldCost,
    required this.stoneCost,
    required this.successRate,
    required this.destroyRate,
  });
}

class Equipment {
  final String id;
  final String name;
  final ItemGrade grade;
  final ItemSlot slot;
  final WeaponType? weaponType;
  int enhanceLevel;
  final int basePower;

  Equipment({
    required this.id,
    required this.name,
    required this.grade,
    required this.slot,
    this.weaponType,
    this.enhanceLevel = 0,
    required this.basePower,
  });

  int get power => (basePower * (1 + enhanceLevel * 0.3)).toInt();

  bool get isMaxEnhance => enhanceLevel >= grade.maxEnhance;

  bool get isFinalStage => enhanceLevel >= grade.finalStageStart;

  // 가짜 스탯 계산 — power 기반으로 슬롯 비율 적용
  // 강화 수치에 따라 자동으로 올라감 (power가 올라가니까)
  StatValues get fakeStats {
    final p = power.toDouble();
    final ratio = slot.statRatio;
    return StatValues(
      atk: (p * ratio.atk).toInt(),
      def: (p * ratio.def).toInt(),
      hp:  (p * ratio.hp * 5).toInt(),  // 체력은 숫자 크게 보이게 x5
      mag: (p * ratio.mag).toInt(),
      agi: (p * ratio.agi).toInt(),
    );
  }

  Equipment copyWith({int? enhanceLevel}) {
    return Equipment(
      id: id,
      name: name,
      grade: grade,
      slot: slot,
      weaponType: weaponType,
      enhanceLevel: enhanceLevel ?? this.enhanceLevel,
      basePower: basePower,
    );
  }
}
