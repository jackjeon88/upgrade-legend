import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/item_database.dart';
import '../models/equipment.dart';
import '../utils/sound_manager.dart'; // 효과음

class ShopScreen extends StatefulWidget {
  final GameState gameState;
  final VoidCallback onStateChanged;

  const ShopScreen({
    super.key,
    required this.gameState,
    required this.onStateChanged,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _lastResult = '';

  String _formatNumber(int n) {
    if (n >= 1000000000) return '${(n / 1000000000).toStringAsFixed(1)}B';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Color _gradeColor(ItemGrade grade) {
    switch (grade) {
      case ItemGrade.normal: return Colors.grey;
      case ItemGrade.magic: return Colors.green;
      case ItemGrade.rare: return Colors.blue;
      case ItemGrade.unique: return Colors.purple;
      case ItemGrade.epic: return Colors.orange;
      case ItemGrade.legendary: return Colors.red;
    }
  }

/// 골드 상자 뽑기 실행
/// [isTen] 10연뽑, [isHundred] 100연뽑
/// 비용: 1회 10,000 / 10회 90,000 / 100회 800,000
void _openGoldBox({bool isTen = false, bool isHundred = false}) {
  final gs = widget.gameState;
  // 연뽑 종류에 따른 비용 계산
  final cost = isHundred ? 800000 : isTen ? 90000 : 10000;
  if (gs.gold < cost) {
    setState(() => _lastResult = '💰 골드가 부족합니다!');
    return;
  }
  gs.gold -= cost;
  final items = openGoldBox(isTen: isTen, isHundred: isHundred);
  gs.inventory.addAll(items);
  widget.onStateChanged();
  SoundManager.playGacha(); // 뽑기 효과음
  _showGachaResult(List.from(items), isGoldBox: true, isTen: isTen, isHundred: isHundred);
  }
/// 다이아 상자 뽑기 실행
/// [isTen] 10연뽑, [isHundred] 100연뽑
/// 비용: 1회 100 / 10회 900 / 100회 8,000
void _openDiamondBox({bool isTen = false, bool isHundred = false}) {
  final gs = widget.gameState;
  // 연뽑 종류에 따른 비용 계산
  final cost = isHundred ? 8000 : isTen ? 900 : 100;
  if (gs.diamond < cost) {
    setState(() => _lastResult = '💎 다이아가 부족합니다!');
    return;
  }
  gs.diamond -= cost;
  final items = openDiamondBox(isTen: isTen, isHundred: isHundred);
  gs.inventory.addAll(items);
  widget.onStateChanged();
  SoundManager.playGacha(); // 뽑기 효과음
  _showGachaResult(List.from(items), isGoldBox: false, isTen: isTen, isHundred: isHundred);
}

  void _buyStoneGold() {
    final gs = widget.gameState;
    if (gs.gold < 500) {
      setState(() => _lastResult = '💰 골드가 부족합니다!');
      return;
    }
    gs.gold -= 500;
    gs.enhanceStone += 1;
    widget.onStateChanged();
    setState(() => _lastResult = '🔮 강화석 1개 구매 완료!');
  }

  void _buyStoneDiamond() {
    final gs = widget.gameState;
    if (gs.diamond < 30) {
      setState(() => _lastResult = '💎 다이아가 부족합니다!');
      return;
    }
    gs.diamond -= 30;
    gs.enhanceStone += 10;
    widget.onStateChanged();
    setState(() => _lastResult = '🔮 강화석 10개 구매 완료!');
  }
/// 강화석 100개 구매 (다이아 250 / 10개짜리 30 x 10 = 300 대비 17% 할인)
void _buyStoneHundred() {
  final gs = widget.gameState;
  if (gs.diamond < 250) {
    setState(() => _lastResult = '💎 다이아가 부족합니다!');
    return;
  }
  gs.diamond -= 250;
  gs.enhanceStone += 100;
  widget.onStateChanged();
  setState(() => _lastResult = '🔮 강화석 100개 구매 완료! (💎250)');
}

/// 다이아 → 골드 환전 팝업
/// 팝업 닫지 않고 연속 환전 가능, 보유량 실시간 반영
void _exchangeDiamond() {
  final gs = widget.gameState;
  if (gs.diamond < 1) {
    setState(() => _lastResult = '💎 다이아가 없습니다!');
    return;
  }
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: const Text('💎 → 💰 환전',
            style: TextStyle(color: Color(0xFFF5C842))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 보유 다이아 실시간 표시
            Text('보유 다이아: ${gs.diamond} 💎',
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            const Text('💎 1 = 💰 1,000',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            _buildExchangeOption(10, gs, setDialogState: setDialogState),
            _buildExchangeOption(100, gs, setDialogState: setDialogState),
            _buildExchangeOption(500, gs, setDialogState: setDialogState),
            if (gs.diamond > 0)
              _buildExchangeOption(gs.diamond, gs,
                  label: '전체', setDialogState: setDialogState),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    ),
  );
}

  /// 환전 옵션 버튼
/// [amount] 환전할 다이아 수량
/// [label] 버튼 표시 텍스트 (없으면 amount 그대로 표시)
/// [setDialogState] 팝업 내 상태 갱신용 (실시간 다이아 업데이트)
Widget _buildExchangeOption(int amount, GameState gs, {
  String? label,
  StateSetter? setDialogState,
}) {
  final canExchange = gs.diamond >= amount;
  return GestureDetector(
    onTap: canExchange
        ? () {
            gs.exchangeDiamondToGold(amount);
            widget.onStateChanged();
            // 팝업 닫지 않고 내부 상태만 갱신
            setDialogState?.call(() {});
            setState(() => _lastResult =
                '💱 💎$amount → 💰${_formatNumber(amount * 1000)} 환전 완료!');
          }
        : null,
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: canExchange ? const Color(0xFF1A1A2A) : const Color(0xFF0A0A0F),
        border: Border.all(
            color: canExchange ? const Color(0xFF2A2A4A) : const Color(0xFF1A1A1A)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('💎 ${label ?? amount}',
              style: TextStyle(
                  color: canExchange ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold)),
          Text('→ 💰 ${_formatNumber(amount * 1000)}',
              style: TextStyle(
                  color: canExchange ? const Color(0xFFF5C842) : Colors.grey)),
        ],
      ),
    ),
  );
}


  /// 뽑기 결과 팝업 표시
/// [isGoldBox] 골드/다이아 상자 구분
/// [isTen] 10연뽑 여부, [isHundred] 100연뽑 여부

  /// 뽑기 결과 팝업 표시
/// [isGoldBox] 골드/다이아 상자 구분
/// [isTen] 10연뽑 여부, [isHundred] 100연뽑 여부
void _showGachaResult(List<Equipment> items, {
  required bool isGoldBox,
  required bool isTen,
  bool isHundred = false,
}) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final gs = widget.gameState;

/// 팝업 내 다시뽑기
/// [ten] 10연뽑 여부, [hundred] 100연뽑 여부
void _reroll(bool ten, bool hundred) {
  // 연뽑 종류에 따른 비용 계산
  final cost = isGoldBox
      ? (hundred ? 800000 : ten ? 90000 : 10000)
      : (hundred ? 8000 : ten ? 900 : 100);
  final hasEnough = isGoldBox ? gs.gold >= cost : gs.diamond >= cost;
  if (!hasEnough) { setDialogState(() {}); return; }

  // 비용 차감
  if (isGoldBox) gs.gold -= cost;
  else gs.diamond -= cost;

  // 새 아이템 생성 후 인벤토리 추가
final newItems = isGoldBox
      ? openGoldBox(isTen: ten, isHundred: hundred)
      : openDiamondBox(isTen: ten, isHundred: hundred);
  gs.inventory.addAll(newItems);
  widget.onStateChanged();
  SoundManager.playGacha(); // 다시뽑기 효과음
  setDialogState(() { items.clear(); items.addAll(newItems); });
}



          return AlertDialog(
            backgroundColor: const Color(0xFF111118),
            title: const Text('🎁 획득 아이템',
                style: TextStyle(color: Color(0xFFF5C842))),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2A),
                            border: Border.all(
                                color: _gradeColor(item.grade).withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            children: [
                              Text(item.slot.emoji,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name,
                                        style: TextStyle(
                                            color: _gradeColor(item.grade),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    Text(item.grade.name,
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 다시 뽑기 버튼
                 // 다시뽑기 버튼 3개: 1회 / 10회 / 100회
Row(
  children: [
    // 1회 다시뽑기
    Expanded(
      child: GestureDetector(
        onTap: () => _reroll(false, false),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isGoldBox
                ? (gs.gold >= 10000 ? const Color(0xFF2A3A1A) : const Color(0xFF0A0A0F))
                : (gs.diamond >= 100 ? const Color(0xFF1A1A3A) : const Color(0xFF0A0A0F)),
            border: Border.all(color: const Color(0xFF3A3A5A)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isGoldBox ? '1회\n💰10,000' : '1회\n💎100',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
      ),
    ),
    const SizedBox(width: 4),
    // 10회 다시뽑기
    Expanded(
      child: GestureDetector(
        onTap: () => _reroll(true, false),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isGoldBox
                ? (gs.gold >= 90000 ? const Color(0xFF2A3A1A) : const Color(0xFF0A0A0F))
                : (gs.diamond >= 900 ? const Color(0xFF1A1A3A) : const Color(0xFF0A0A0F)),
            border: Border.all(color: const Color(0xFF3A3A5A)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isGoldBox ? '10회\n💰90,000' : '10회\n💎900',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
      ),
    ),
    const SizedBox(width: 4),
    // 100회 다시뽑기 (최고 확률, 강조 표시)
    Expanded(
      child: GestureDetector(
        onTap: () => _reroll(false, true),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isGoldBox
                ? (gs.gold >= 800000 ? const Color(0xFF3A2A1A) : const Color(0xFF0A0A0F))
                : (gs.diamond >= 8000 ? const Color(0xFF2A1A3A) : const Color(0xFF0A0A0F)),
            border: Border.all(color: Colors.amber.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isGoldBox ? '100회\n💰800,000' : '100회\n💎8,000',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ),
  ],
),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('인벤토리로',
                    style: TextStyle(color: Color(0xFFF5C842))),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gameState;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_lastResult.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1A0A),
                border: Border.all(color: const Color(0xFF2A3A2A)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(_lastResult,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
            ),

          _buildSectionTitle('💰 골드 보물상자'),
          _buildRateInfo([
            '노멀 60% / 매직 28% / 레어 9%',
            '유니크 2.5% / 에픽 0.4% / 레전더리 0.1%',
          ]),
// 골드 상자 뽑기 버튼: 1회 / 10회 / 100회
Row(
  children: [
    Expanded(child: _buildShopButton(
      label: '1회 뽑기', price: '💰 10,000',
      canAfford: gs.gold >= 10000,
      onTap: () => _openGoldBox(),
      color: const Color(0xFF2A3A1A),
    )),
    const SizedBox(width: 6),
    Expanded(child: _buildShopButton(
      label: '10회 뽑기', price: '💰 90,000',
      subtitle: '확률 UP!',
      canAfford: gs.gold >= 90000,
      onTap: () => _openGoldBox(isTen: true),
      color: const Color(0xFF2A3A1A),
    )),
    const SizedBox(width: 6),
    Expanded(child: _buildShopButton(
      label: '100회 뽑기', price: '💰 850,000',
      subtitle: '🔥 최고 확률!',
      canAfford: gs.gold >= 850000,
      onTap: () => _openGoldBox(isHundred: true),
      color: const Color(0xFF3A2A1A),
    )),
  ],
),

          const SizedBox(height: 16),

          _buildSectionTitle('💎 다이아 보물상자'),
          _buildRateInfo([
            '매직 35% / 레어 40% / 유니크 18%',
            '에픽 5.5% / 레전더리 1.5%',
          ]),
        // 다이아 상자 뽑기 버튼: 1회 / 10회 / 100회
Row(
  children: [
    Expanded(child: _buildShopButton(
      label: '1회 뽑기', price: '💎 100',
      canAfford: gs.diamond >= 100,
      onTap: () => _openDiamondBox(),
      color: const Color(0xFF1A1A3A),
    )),
    const SizedBox(width: 6),
    Expanded(child: _buildShopButton(
      label: '10회 뽑기', price: '💎 900',
      subtitle: '확률 UP!',
      canAfford: gs.diamond >= 900,
      onTap: () => _openDiamondBox(isTen: true),
      color: const Color(0xFF1A1A3A),
    )),
    const SizedBox(width: 6),
    Expanded(child: _buildShopButton(
      label: '100회 뽑기', price: '💎 8,000',
      subtitle: '🔥 최고 확률!',
      canAfford: gs.diamond >= 8000,
      onTap: () => _openDiamondBox(isHundred: true),
      color: const Color(0xFF2A1A3A),
    )),
  ],
),

          const SizedBox(height: 16),

          _buildSectionTitle('🔮 강화석 구매'),
// 강화석 구매: 1개(골드) / 10개(다이아) / 100개(다이아 할인)
Row(
  children: [
    Expanded(child: _buildShopButton(
      label: '1개', price: '💰 500',
      canAfford: gs.gold >= 500,
      onTap: _buyStoneGold,
      color: const Color(0xFF2A2A1A),
    )),
    const SizedBox(width: 6),
    Expanded(child: _buildShopButton(
      label: '10개', price: '💎 30',
      canAfford: gs.diamond >= 30,
      onTap: _buyStoneDiamond,
      color: const Color(0xFF1A1A3A),
    )),
    const SizedBox(width: 6),
    Expanded(child: _buildShopButton(
      label: '100개', price: '💎 250',
      subtitle: '🔥 17% 할인!',
      canAfford: gs.diamond >= 250,
      onTap: _buyStoneHundred,
      color: const Color(0xFF2A1A3A),
    )),
  ],
),

          const SizedBox(height: 16),

          _buildSectionTitle('💱 다이아 → 골드 환전'),
          const Text('💎 1 = 💰 1,000',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _buildShopButton(
              label: '환전하기',
              price: '보유 💎 ${gs.diamond}',
              canAfford: gs.diamond > 0,
              onTap: _exchangeDiamond,
              color: const Color(0xFF1A2A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(
              color: Color(0xFFF5C842),
              fontWeight: FontWeight.bold,
              fontSize: 14)),
    );
  }

  Widget _buildRateInfo(List<String> lines) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        border: Border.all(color: const Color(0xFF2A2A3A)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map((l) => Text(l,
                style: const TextStyle(color: Colors.grey, fontSize: 11)))
            .toList(),
      ),
    );
  }

  Widget _buildShopButton({
    required String label,
    required String price,
    String? subtitle,
    required bool canAfford,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: canAfford ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: canAfford ? color : const Color(0xFF0A0A0F),
          border: Border.all(
              color: canAfford ? const Color(0xFF3A3A4A) : const Color(0xFF1A1A1A)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    color: canAfford ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 4),
            Text(price,
                style: TextStyle(
                    color: canAfford ? const Color(0xFFF5C842) : Colors.grey,
                    fontSize: 12)),
            if (subtitle != null)
              Text(subtitle,
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}