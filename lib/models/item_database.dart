import 'dart:math';
import 'equipment.dart';

// 슬롯별 아이템 이름 데이터베이스 (세트 정비 완료)
const Map<ItemSlot, Map<ItemGrade, List<String>>> itemNames = {
  ItemSlot.weapon: {
    ItemGrade.normal: ['낡은 검', '낡은 도', '낡은 도끼', '낡은 창', '낡은 활'],
    ItemGrade.magic: ['용병의 검', '용병의 도', '용병의 도끼', '용병의 창', '용병의 활', '강철의 검', '강철의 도', '강철의 도끼', '강철의 창', '강철의 활', '사냥꾼의 검', '사냥꾼의 도', '사냥꾼의 도끼', '사냥꾼의 창', '사냥꾼의 활'],
    ItemGrade.rare: ['기사단의 검', '기사단의 도', '기사단의 도끼', '기사단의 창', '기사단의 활', '서릿발 검', '서릿발 도', '서릿발 도끼', '서릿발 창', '서릿발 활', '화염 검', '화염 도', '화염 도끼', '화염 창', '화염 활', '폭풍 검', '폭풍 도', '폭풍 도끼', '폭풍 창', '폭풍 활'],
    ItemGrade.unique: ['흑기사단의 검', '흑기사단의 도', '흑기사단의 도끼', '흑기사단의 창', '흑기사단의 활', '처형자의 검', '처형자의 도', '처형자의 도끼', '처형자의 창', '처형자의 활', '달빛 검', '달빛 도', '달빛 도끼', '달빛 창', '달빛 활', '뇌전 검', '뇌전 도', '뇌전 도끼', '뇌전 창', '뇌전 활', '수호자의 검', '수호자의 도', '수호자의 도끼', '수호자의 창', '수호자의 활'],
    ItemGrade.epic: ['심연의 검', '심연의 도', '심연의 도끼', '심연의 창', '심연의 활', '파멸의 검', '파멸의 도', '파멸의 도끼', '파멸의 창', '파멸의 활', '어둠의 검', '어둠의 도', '어둠의 도끼', '어둠의 창', '어둠의 활', '용암의 검', '용암의 도', '용암의 도끼', '용암의 창', '용암의 활', '천공의 검', '천공의 도', '천공의 도끼', '천공의 창', '천공의 활'],
    ItemGrade.legendary: ['신왕의 검', '신왕의 도', '신왕의 도끼', '신왕의 창', '신왕의 활', '멸절의 검', '멸절의 도', '멸절의 도끼', '멸절의 창', '멸절의 활', '창세의 검', '창세의 도', '창세의 도끼', '창세의 창', '창세의 활', '용왕의 검', '용왕의 도', '용왕의 도끼', '용왕의 창', '용왕의 활', '천계의 검', '천계의 도', '천계의 도끼', '천계의 창', '천계의 활'],
  },
  ItemSlot.helmet: {
    ItemGrade.normal: ['낡은 투구', '낡은 두건', '낡은 모자'],
    ItemGrade.magic: ['용병의 투구', '강철의 투구', '사냥꾼의 투구'],
    ItemGrade.rare: ['기사단의 투구', '서릿발 투구', '화염 투구', '폭풍 투구'],
    ItemGrade.unique: ['흑기사단의 투구', '처형자의 투구', '달빛 투구', '뇌전 투구', '수호자의 투구'],
    ItemGrade.epic: ['심연의 투구', '파멸의 투구', '어둠의 투구', '용암의 투구', '천공의 투구'],
    ItemGrade.legendary: ['신왕의 투구', '멸절의 투구', '창세의 투구', '용왕의 투구', '천계의 투구'],
  },
  ItemSlot.armor: {
    ItemGrade.normal: ['낡은 갑옷', '낡은 흉갑'],
    ItemGrade.magic: ['용병의 갑옷', '강철의 갑옷', '사냥꾼의 갑옷'],
    ItemGrade.rare: ['기사단의 갑옷', '서릿발 갑옷', '화염 갑옷', '폭풍 갑옷'],
    ItemGrade.unique: ['흑기사단의 갑옷', '처형자의 갑옷', '달빛 갑옷', '뇌전 갑옷', '수호자의 갑옷'],
    ItemGrade.epic: ['심연의 갑옷', '파멸의 갑옷', '어둠의 갑옷', '용암의 갑옷', '천공의 갑옷'],
    ItemGrade.legendary: ['신왕의 갑옷', '멸절의 갑옷', '창세의 갑옷', '용왕의 갑옷', '천계의 갑옷'],
  },
  ItemSlot.gloves: {
    ItemGrade.normal: ['낡은 장갑', '낡은 건틀릿'],
    ItemGrade.magic: ['용병의 장갑', '강철의 장갑', '사냥꾼의 장갑'],
    ItemGrade.rare: ['기사단의 장갑', '서릿발 장갑', '화염 장갑', '폭풍 장갑'],
    ItemGrade.unique: ['흑기사단의 건틀릿', '처형자의 장갑', '달빛 장갑', '뇌전 장갑', '수호자의 장갑'],
    ItemGrade.epic: ['심연의 건틀릿', '파멸의 장갑', '어둠의 장갑', '용암의 장갑', '천공의 장갑'],
    ItemGrade.legendary: ['신왕의 건틀릿', '멸절의 장갑', '창세의 장갑', '용왕의 장갑', '천계의 장갑'],
  },
  ItemSlot.shoes: {
    ItemGrade.normal: ['낡은 신발', '낡은 부츠'],
    ItemGrade.magic: ['용병의 부츠', '강철의 부츠', '사냥꾼의 부츠'],
    ItemGrade.rare: ['기사단의 부츠', '서릿발 부츠', '화염 부츠', '폭풍 부츠'],
    ItemGrade.unique: ['흑기사단의 부츠', '처형자의 부츠', '달빛 부츠', '뇌전 부츠', '수호자의 부츠'],
    ItemGrade.epic: ['심연의 부츠', '파멸의 부츠', '어둠의 부츠', '용암의 부츠', '천공의 부츠'],
    ItemGrade.legendary: ['신왕의 부츠', '멸절의 부츠', '창세의 부츠', '용왕의 부츠', '천계의 부츠'],
  },
  ItemSlot.shirt: {
    ItemGrade.normal: ['낡은 셔츠', '낡은 로브'],
    ItemGrade.magic: ['용병의 로브', '강철의 로브', '사냥꾼의 셔츠'],
    ItemGrade.rare: ['기사단의 로브', '서릿발 로브', '화염 로브', '폭풍 로브'],
    ItemGrade.unique: ['흑기사단의 로브', '처형자의 로브', '달빛 로브', '뇌전 로브', '수호자의 로브'],
    ItemGrade.epic: ['심연의 로브', '파멸의 로브', '어둠의 로브', '용암의 로브', '천공의 로브'],
    ItemGrade.legendary: ['신왕의 로브', '멸절의 로브', '창세의 로브', '용왕의 로브', '천계의 로브'],
  },
  ItemSlot.cape: {
    ItemGrade.normal: ['낡은 망토'],
    ItemGrade.magic: ['용병의 망토', '강철의 망토', '사냥꾼의 망토'],
    ItemGrade.rare: ['기사단의 망토', '서릿발 망토', '화염 망토', '폭풍 망토'],
    ItemGrade.unique: ['흑기사단의 망토', '처형자의 망토', '달빛 망토', '뇌전 망토', '수호자의 망토'],
    ItemGrade.epic: ['심연의 망토', '파멸의 망토', '어둠의 망토', '용암의 망토', '천공의 망토'],
    ItemGrade.legendary: ['신왕의 망토', '멸절의 망토', '창세의 망토', '용왕의 망토', '천계의 망토'],
  },
  ItemSlot.belt: {
    ItemGrade.normal: ['낡은 벨트'],
    ItemGrade.magic: ['용병의 벨트', '강철의 벨트', '사냥꾼의 벨트'],
    ItemGrade.rare: ['기사단의 벨트', '서릿발 벨트', '화염 벨트', '폭풍 벨트'],
    ItemGrade.unique: ['흑기사단의 벨트', '처형자의 벨트', '달빛 벨트', '뇌전 벨트', '수호자의 벨트'],
    ItemGrade.epic: ['심연의 벨트', '파멸의 벨트', '어둠의 벨트', '용암의 벨트', '천공의 벨트'],
    ItemGrade.legendary: ['신왕의 벨트', '멸절의 벨트', '창세의 벨트', '용왕의 벨트', '천계의 벨트'],
  },
  ItemSlot.ring1: {
    ItemGrade.normal: ['낡은 반지', '나무 반지'],
    ItemGrade.magic: ['용병의 반지', '강철의 반지', '사냥꾼의 반지'],
    ItemGrade.rare: ['기사단의 반지', '서릿발 반지', '화염 반지', '폭풍 반지'],
    ItemGrade.unique: ['흑기사단의 반지', '처형자의 반지', '달빛 반지', '뇌전 반지', '수호자의 반지'],
    ItemGrade.epic: ['심연의 반지', '파멸의 반지', '어둠의 반지', '용암의 반지', '천공의 반지'],
    ItemGrade.legendary: ['신왕의 반지', '멸절의 반지', '창세의 반지', '용왕의 반지', '천계의 반지'],
  },
  ItemSlot.ring2: {
    ItemGrade.normal: ['낡은 반지', '나무 반지'],
    ItemGrade.magic: ['용병의 반지', '강철의 반지', '사냥꾼의 반지'],
    ItemGrade.rare: ['기사단의 반지', '서릿발 반지', '화염 반지', '폭풍 반지'],
    ItemGrade.unique: ['흑기사단의 반지', '처형자의 반지', '달빛 반지', '뇌전 반지', '수호자의 반지'],
    ItemGrade.epic: ['심연의 반지', '파멸의 반지', '어둠의 반지', '용암의 반지', '천공의 반지'],
    ItemGrade.legendary: ['신왕의 반지', '멸절의 반지', '창세의 반지', '용왕의 반지', '천계의 반지'],
  },
  ItemSlot.necklace: {
    ItemGrade.normal: ['낡은 목걸이', '가죽 목걸이'],
    ItemGrade.magic: ['용병의 목걸이', '강철의 목걸이', '사냥꾼의 목걸이'],
    ItemGrade.rare: ['기사단의 목걸이', '서릿발 목걸이', '화염 목걸이', '폭풍 목걸이'],
    ItemGrade.unique: ['흑기사단의 목걸이', '처형자의 목걸이', '달빛 목걸이', '뇌전 목걸이', '수호자의 목걸이'],
    ItemGrade.epic: ['심연의 목걸이', '파멸의 목걸이', '어둠의 목걸이', '용암의 목걸이', '천공의 목걸이'],
    ItemGrade.legendary: ['신왕의 목걸이', '멸절의 목걸이', '창세의 목걸이', '용왕의 목걸이', '천계의 목걸이'],
  },
};
const List<double> goldBox100Rates = [0.20, 0.35, 0.30, 0.10, 0.04, 0.01];
const List<double> diamondBox100Rates = [0.0, 0.10, 0.35, 0.35, 0.15, 0.05];


// 기본 전투력 (등급별)
const Map<ItemGrade, int> basePowerByGrade = {
  ItemGrade.normal: 20,
  ItemGrade.magic: 80,
  ItemGrade.rare: 250,
  ItemGrade.unique: 700,
  ItemGrade.epic: 2000,
  ItemGrade.legendary: 6000,
};

// 판매 가격 (등급별)
const Map<ItemGrade, int> sellPriceByGrade = {
  ItemGrade.normal: 500,
  ItemGrade.magic: 2000,
  ItemGrade.rare: 8000,
  ItemGrade.unique: 30000,
  ItemGrade.epic: 150000,
  ItemGrade.legendary: 800000,
};

// 골드 상자 확률
const List<double> goldBoxRates = [0.60, 0.28, 0.09, 0.025, 0.004, 0.001];
const List<double> goldBox10Rates = [0.40, 0.35, 0.17, 0.055, 0.019, 0.006];
// 다이아 상자 확률
const List<double> diamondBoxRates = [0.0, 0.35, 0.40, 0.18, 0.055, 0.015];
const List<double> diamondBox10Rates = [0.0, 0.20, 0.40, 0.27, 0.10, 0.03];

final _random = Random();

ItemGrade _rollGrade(List<double> rates) {
  final roll = _random.nextDouble();
  double cumulative = 0;
  for (int i = 0; i < rates.length; i++) {
    cumulative += rates[i];
    if (roll < cumulative) return ItemGrade.values[i];
  }
  return ItemGrade.normal;
}

ItemSlot _randomSlot() {
  final slots = ItemSlot.values;
  return slots[_random.nextInt(slots.length)];
}

String _randomName(ItemSlot slot, ItemGrade grade) {
  final names = itemNames[slot]?[grade] ?? ['알 수 없는 아이템'];
  return names[_random.nextInt(names.length)];
}

Equipment generateItem(ItemGrade grade, {ItemSlot? slot}) {
  final s = slot ?? _randomSlot();
  final name = _randomName(s, grade);
  final base = basePowerByGrade[grade] ?? 20;
  // ±15% 랜덤 변동 — 같은 등급이라도 아이템마다 전투력이 미묘하게 다름
  final variation = 0.85 + _random.nextDouble() * 0.30; // 0.85 ~ 1.15
  final finalPower = (base * variation).toInt();
  return Equipment(
    id: 'inv_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(9999)}',
    name: name,
    grade: grade,
    slot: s,
    basePower: finalPower,
  );
}

/// 골드 상자 열기
/// [isTen] 10연뽑 여부, [isHundred] 100연뽑 여부
/// 10연뽑: 레어 이상 확률 상승 / 100연뽑: 유니크 이상 대폭 상승
List<Equipment> openGoldBox({bool isTen = false, bool isHundred = false}) {
  // 연뽑 수에 따라 확률 테이블 선택
  final rates = isHundred ? goldBox100Rates : isTen ? goldBox10Rates : goldBoxRates;
  // 연뽑 수에 따라 뽑기 횟수 결정
  final count = isHundred ? 100 : isTen ? 10 : 1;
  return List.generate(count, (_) => generateItem(_rollGrade(rates)));
}

/// 다이아 상자 열기
/// [isTen] 10연뽑 여부, [isHundred] 100연뽑 여부
/// 노멀 없음, 100연뽑 시 유니크 이상 집중
List<Equipment> openDiamondBox({bool isTen = false, bool isHundred = false}) {
  // 연뽑 수에 따라 확률 테이블 선택
  final rates = isHundred ? diamondBox100Rates : isTen ? diamondBox10Rates : diamondBoxRates;
  // 연뽑 수에 따라 뽑기 횟수 결정
  final count = isHundred ? 100 : isTen ? 10 : 1;
  return List.generate(count, (_) => generateItem(_rollGrade(rates)));
}
int getSellPrice(Equipment equip) {
  final base = sellPriceByGrade[equip.grade] ?? 500;
  return base + (equip.enhanceLevel * base * 0.5).toInt();
}