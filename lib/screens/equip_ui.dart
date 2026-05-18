import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../models/game_state.dart';
import '../models/set_system.dart';

class EquipmentUI extends StatefulWidget {
  final GameState gameState;
  final Function(Equipment, int) onEquipTap;

  const EquipmentUI({
    super.key,
    required this.gameState,
    required this.onEquipTap,
  });

  @override
  State<EquipmentUI> createState() => _EquipmentUIState();
}

class _EquipmentUIState extends State<EquipmentUI> {
  String? _hoveredId;

  Equipment? _getEquip(ItemSlot slot) {
    try {
      return widget.gameState.equipped.firstWhere((e) => e.slot == slot);
    } catch (_) {
      return null;
    }
  }

  int _getEquipIndex(ItemSlot slot) {
    return widget.gameState.equipped.indexWhere((e) => e.slot == slot);
  }

  Color _gradeColor(ItemGrade? grade) {
    switch (grade) {
      case ItemGrade.normal: return Colors.grey;
      case ItemGrade.magic: return Colors.green;
      case ItemGrade.rare: return Colors.blue;
      case ItemGrade.unique: return Colors.purple;
      case ItemGrade.epic: return Colors.orange;
      case ItemGrade.legendary: return Colors.red;
      default: return Colors.grey;
    }
  }

  // 해당 장비가 세트에 포함되어 있는지 확인
  SetStatus? _getSetStatus(Equipment equip) {
    final statuses = widget.gameState.setStatuses;
    final theme = extractTheme(equip);
    if (theme == null) return null;
    try {
      return statuses.firstWhere(
        (s) => s.theme == theme && s.grade == equip.grade,
      );
    } catch (_) {
      return null;
    }
  }

  bool _isComplete(Equipment equip) {
    final status = _getSetStatus(equip);
    return status?.isComplete ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // 세트 보너스 총합
    final totalSetBonus = calcTotalSetBonus(widget.gameState.equipped);
    final setStatuses = widget.gameState.setStatuses
        .where((s) => s.bonus > 0)
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 세트 보너스 표시
          if (totalSetBonus > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1A0A),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '✨ 세트 보너스 +$totalSetBonus',
                style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),

          // 행 1: 투구, 목걸이
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSlot(ItemSlot.helmet),
              const SizedBox(width: 8),
              _buildSlot(ItemSlot.necklace),
            ],
          ),
          const SizedBox(height: 8),
          // 행 2: 티셔츠, 갑옷, 망토
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSlot(ItemSlot.shirt),
              const SizedBox(width: 8),
              _buildSlot(ItemSlot.armor),
              const SizedBox(width: 8),
              _buildSlot(ItemSlot.cape),
            ],
          ),
          const SizedBox(height: 8),
          // 행 3: 무기, 벨트, 장갑
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSlot(ItemSlot.weapon),
              const SizedBox(width: 8),
              _buildSlot(ItemSlot.belt),
              const SizedBox(width: 8),
              _buildSlot(ItemSlot.gloves),
            ],
          ),
          const SizedBox(height: 8),
          // 행 4: 반지1, 신발, 반지2
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSlot(ItemSlot.ring1),
              const SizedBox(width: 8),
              _buildSlot(ItemSlot.shoes),
              const SizedBox(width: 8),
              _buildSlot(ItemSlot.ring2),
            ],
          ),

          // 호버링 시 세트 정보 팝업
          if (_hoveredId != null) _buildSetInfoPanel(setStatuses),
        ],
      ),
    );
  }

  Widget _buildSlot(ItemSlot slot) {
    final equip = _getEquip(slot);
    final index = _getEquipIndex(slot);
    final grade = equip?.grade;
    final color = _gradeColor(grade);
    final isHovered = _hoveredId == equip?.id;
    final complete = equip != null && _isComplete(equip);
    final setStatus = equip != null ? _getSetStatus(equip) : null;
    final inSet = setStatus != null && setStatus.count >= 3;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredId = equip?.id),
      onExit: (_) => setState(() => _hoveredId = null),
      child: GestureDetector(
        onTap: equip != null ? () => onEquipTap(equip, index) : null,
        onDoubleTap: equip != null ? () => widget.onEquipTap(equip, index) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 68,
          height: 76,
          decoration: BoxDecoration(
            color: isHovered
                ? color.withOpacity(0.15)
                : const Color(0xFF111118),
            border: Border.all(
              color: complete
                  ? Colors.white
                  : inSet
                      ? color
                      : equip != null
                          ? color.withOpacity(0.6)
                          : const Color(0xFF2A2A3A),
              width: complete ? 2.0 : inSet ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: complete
                ? [
                    BoxShadow(color: color.withOpacity(0.6), blurRadius: 12, spreadRadius: 2),
                    BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 6, spreadRadius: 0),
                  ]
                : inSet
                    ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                    : equip != null && grade != null && grade.index >= 4
                        ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 6)]
                        : null,
          ),
          child: equip != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
Text(slot.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 2),
                    Text(
                      equip.name,
                      style: TextStyle(
                        color: complete ? Colors.white : color,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '+${equip.enhanceLevel}',
                      style: TextStyle(
                        color: complete ? Colors.white : color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(slot.emoji,
                        style: const TextStyle(fontSize: 22, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(slot.displayName,
                        style: const TextStyle(color: Colors.grey, fontSize: 9)),
                  ],
                ),
        ),
      ),
    );
  }

  // onEquipTap getter (단순 tap용)
  void Function(Equipment, int) get onEquipTap => (equip, index) {
    setState(() => _hoveredId = null);
    widget.onEquipTap(equip, index);
  };

  Widget _buildSetInfoPanel(List<SetStatus> statuses) {
    // 호버된 장비의 세트 정보만 보여주기
    final hoveredEquip = widget.gameState.equipped
        .where((e) => e.id == _hoveredId)
        .toList();
    if (hoveredEquip.isEmpty) return const SizedBox();

    final equip = hoveredEquip.first;
    final theme = extractTheme(equip);
    if (theme == null) return const SizedBox();

    SetStatus? status;
    try {
      status = statuses.firstWhere(
          (s) => s.theme == theme && s.grade == equip.grade);
    } catch (_) {
      // 세트 없음 - 0개짜리
    }

    final count = status?.count ?? 1;
    final grade = equip.grade;
    final bonuses = setBonuses[grade] ?? [];
    final color = _gradeColor(grade);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A14),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[$theme] ${grade.name} 세트  $count / 10',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 6),
          ...List.generate(setStages.length, (i) {
            final stage = setStages[i];
            final bonus = bonuses.length > i ? bonuses[i] : 0;
            final active = count >= stage;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text(
                    active ? '✅' : '⬜',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$stage개: 전투력 +$bonus',
                    style: TextStyle(
                      color: active ? Colors.greenAccent : Colors.grey,
                      fontSize: 11,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (!active && count < stage)
                    Text(
                      '  (${stage - count}개 더)',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                ],
              ),
            );
          }),
          if (status?.isComplete == true)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('✨ 컴플리트! 던전 이펙트 강화 + 네온 효과 활성화',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}