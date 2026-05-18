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