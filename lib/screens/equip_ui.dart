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

  SetStatus? _getSetStatus(Equipment equip) {
    final statuses = widget.gameState.setStatuses;
    final theme = extractTheme(equip);
    if (theme == null) return null;
    try {
      return statuses.firstWhere((s) => s.theme == theme && s.grade == equip.grade);
    } catch (_) {
      return null;
    }
  }

  bool _isComplete(Equipment equip) => _getSetStatus(equip)?.isComplete ?? false;

  @override
  Widget build(BuildContext context) {
    final totalSetBonus = calcTotalSetBonus(widget.gameState.equipped);
    final setStatuses = widget.gameState.setStatuses.where((s) => s.bonus > 0).toList();

    return Column(
      children: [
        // 세트 보너스
        if (totalSetBonus > 0)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1A0A),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              '✨ 세트 보너스 +$totalSetBonus',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),

        // 캐릭터 + 장비 슬롯
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              // 슬롯 크기
              const slotSize = 44.0;

              return Stack(
                children: [
                  // 캐릭터 실루엣 (나중에 Image.asset으로 교체)
                  Center(
                    child: Container(
                      width: w * 0.45,
                      height: h * 0.95,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('캐릭터', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    ),
                  ),

                  // 투구 - 머리
                  _positioned(slot: ItemSlot.helmet, left: w/2 - slotSize/2, top: h * 0.02, size: slotSize, setStatuses: setStatuses),

                  // 목걸이 - 목
                  _positioned(slot: ItemSlot.necklace, left: w/2 - slotSize/2, top: h * 0.14, size: slotSize, setStatuses: setStatuses),

                  // 망토 - 왼쪽 어깨 바깥
                  _positioned(slot: ItemSlot.cape, left: w * 0.02, top: h * 0.14, size: slotSize, setStatuses: setStatuses),

                  // 티셔츠 - 몸통 좌
                  _positioned(slot: ItemSlot.shirt, left: w/2 - slotSize - 4, top: h * 0.26, size: slotSize, setStatuses: setStatuses),

                  // 갑옷 - 몸통 우
                  _positioned(slot: ItemSlot.armor, left: w/2 + 4, top: h * 0.26, size: slotSize, setStatuses: setStatuses),

                  // 반지1 - 왼쪽 팔꿈치
                  _positioned(slot: ItemSlot.ring1, left: w * 0.04, top: h * 0.40, size: slotSize, setStatuses: setStatuses),

                  // 반지2 - 오른쪽 팔꿈치
                  _positioned(slot: ItemSlot.ring2, right: w * 0.04, top: h * 0.40, size: slotSize, setStatuses: setStatuses),

                  // 벨트 - 허리
                  _positioned(slot: ItemSlot.belt, left: w/2 - slotSize/2, top: h * 0.52, size: slotSize, setStatuses: setStatuses),

                  // 무기 - 왼손
                  _positioned(slot: ItemSlot.weapon, left: w * 0.02, top: h * 0.56, size: slotSize, setStatuses: setStatuses),

                  // 장갑 - 오른손
                  _positioned(slot: ItemSlot.gloves, right: w * 0.02, top: h * 0.56, size: slotSize, setStatuses: setStatuses),

                  // 신발 - 발
                  _positioned(slot: ItemSlot.shoes, left: w/2 - slotSize/2, top: h * 0.82, size: slotSize, setStatuses: setStatuses),

                  // 호버링 세트 정보
                  if (_hoveredId != null)
                    Positioned(
                      bottom: 0,
                      left: 8,
                      right: 8,
                      child: _buildSetInfoPanel(setStatuses),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _positioned({
    required ItemSlot slot,
    double? left,
    double? right,
    required double top,
    required double size,
    required List<SetStatus> setStatuses,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: _buildSlot(slot, size, setStatuses),
    );
  }

  Widget _buildSlot(ItemSlot slot, double size, List<SetStatus> setStatuses) {
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
        onTap: equip != null ? () {
          setState(() => _hoveredId = null);
          widget.onEquipTap(equip, index);
        } : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isHovered
                ? color.withOpacity(0.2)
                : const Color(0xFF111118).withOpacity(0.9),
            border: Border.all(
              color: complete
                  ? Colors.white
                  : inSet
                      ? color
                      : equip != null
                          ? color.withOpacity(0.7)
                          : const Color(0xFF2A2A3A),
              width: complete ? 2.0 : inSet ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: complete
                ? [
                    BoxShadow(color: color.withOpacity(0.6), blurRadius: 12, spreadRadius: 2),
                    BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 6),
                  ]
                : inSet
                    ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                    : null,
          ),
          child: equip != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(slot.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 1),
                    Text(
                      equip.name,
                      style: TextStyle(color: complete ? Colors.white : color, fontSize: 6, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '+${equip.enhanceLevel}',
                      style: TextStyle(color: complete ? Colors.white : color, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(slot.emoji, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    Text(slot.displayName, style: const TextStyle(color: Colors.grey, fontSize: 6)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSetInfoPanel(List<SetStatus> statuses) {
    final hoveredEquip = widget.gameState.equipped.where((e) => e.id == _hoveredId).toList();
    if (hoveredEquip.isEmpty) return const SizedBox();
    final equip = hoveredEquip.first;
    final theme = extractTheme(equip);
    if (theme == null) return const SizedBox();

    SetStatus? status;
    try {
      status = statuses.firstWhere((s) => s.theme == theme && s.grade == equip.grade);
    } catch (_) {}

    final count = status?.count ?? 1;
    final grade = equip.grade;
    final bonuses = setBonuses[grade] ?? [];
    final color = _gradeColor(grade);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A14).withOpacity(0.95),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('[$theme] ${grade.name} 세트  $count / 11',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          ...List.generate(setStages.length, (i) {
            final stage = setStages[i];
            final bonus = bonuses.length > i ? bonuses[i] : 0;
            final active = count >= stage;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text(active ? '✅' : '⬜', style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 6),
                  Text('$stage개: 전투력 +$bonus',
                      style: TextStyle(
                          color: active ? Colors.greenAccent : Colors.grey,
                          fontSize: 11,
                          fontWeight: active ? FontWeight.bold : FontWeight.normal)),
                  if (!active && count < stage)
                    Text('  (${stage - count}개 더)', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            );
          }),
          if (status?.isComplete == true)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('✨ 컴플리트! 던전 이펙트 강화 + 네온 효과',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}