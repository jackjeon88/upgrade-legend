import 'equipment.dart';

// 세트 테마 이름 (등급별 5개)
const Map<ItemGrade, List<String>> setThemes = {
  ItemGrade.normal: ['낡은'],
  ItemGrade.magic: ['용병', '강철', '사냥꾼'],
  ItemGrade.rare: ['기사단', '서릿발', '화염', '폭풍'],
  ItemGrade.unique: ['흑기사단', '처형자', '달빛', '뇌전', '수호자'],
  ItemGrade.epic: ['심연', '파멸', '어둠', '용암', '천공'],
  ItemGrade.legendary: ['신왕', '멸절', '창세', '용왕', '천계'],
};

// 세트 보너스 (등급별, 3/5/7/9/10개)
const Map<ItemGrade, List<int>> setBonuses = {
  ItemGrade.normal: [10, 30, 50, 80, 100],
  ItemGrade.magic: [60, 170, 280, 450, 560],
  ItemGrade.rare: [220, 660, 1100, 1760, 2200],
  ItemGrade.unique: [750, 2240, 3730, 5970, 7460],
  ItemGrade.epic: [2500, 7500, 12500, 20010, 25010],
  ItemGrade.legendary: [8610, 25830, 43050, 68880, 86100],
};

const List<int> setStages = [3, 5, 7, 9, 11];

// 아이템 이름에서 테마 추출
String? extractTheme(Equipment equip) {
  final themes = setThemes[equip.grade];
  if (themes == null) return null;
  for (final theme in themes) {
    if (equip.name.contains(theme)) return theme;
  }
  return null;
}

// 착용 장비에서 세트 현황 계산
class SetStatus {
  final ItemGrade grade;
  final String theme;
  final int count;
  final int bonus;
  final bool isComplete;
  final List<Equipment> members;

  const SetStatus({
    required this.grade,
    required this.theme,
    required this.count,
    required this.bonus,
    required this.isComplete,
    required this.members,
  });

  // 다음 단계까지 몇 개 필요한지
  int? get nextStageCount {
    for (final stage in setStages) {
      if (count < stage) return stage - count;
    }
    return null;
  }

  int? get nextStageBonus {
    for (int i = 0; i < setStages.length; i++) {
      if (count < setStages[i]) {
        return setBonuses[grade]?[i];
      }
    }
    return null;
  }
}

// 현재 착용 장비 기준 세트 현황 계산
List<SetStatus> calcSetStatus(List<Equipment> equipped) {
  // 등급+테마별로 그룹핑
  final Map<String, List<Equipment>> groups = {};
  for (final equip in equipped) {
    final theme = extractTheme(equip);
    if (theme == null) continue;
    final key = '${equip.grade.index}_$theme';
    groups.putIfAbsent(key, () => []).add(equip);
  }

  final result = <SetStatus>[];
  for (final entry in groups.entries) {
    final members = entry.value;
    final count = members.length;
    final grade = members.first.grade;
    final theme = extractTheme(members.first)!;

    // 현재 단계 보너스 계산
    int bonus = 0;
    for (int i = setStages.length - 1; i >= 0; i--) {
      if (count >= setStages[i]) {
        bonus = setBonuses[grade]?[i] ?? 0;
        break;
      }
    }

    result.add(SetStatus(
      grade: grade,
      theme: theme,
      count: count,
      bonus: bonus,
      isComplete: count >= 11,
      members: members,
    ));
  }

  // 보너스 큰 순서로 정렬
  result.sort((a, b) => b.bonus.compareTo(a.bonus));
  return result;
}

// 총 세트 보너스 전투력
int calcTotalSetBonus(List<Equipment> equipped) {
  final statuses = calcSetStatus(equipped);
  return statuses.fold(0, (sum, s) => sum + s.bonus);
}