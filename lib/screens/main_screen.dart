import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../models/game_state.dart';
import '../models/enhance_data.dart';
import '../models/save_manager.dart';
import 'dungeon_screen.dart';
import 'shop_screen.dart';
import '../models/set_system.dart';
import 'equip_ui.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  GameState _gameState = GameState();
  Equipment? _selectedEquip;
  final List<String> _logs = [];
  int _currentTab = 0;
  bool _isLoading = true;
  // 인벤토리 정렬/필터
  String _sortBy = 'grade'; // grade, enhance, slot
  ItemGrade? _filterGrade;
  ItemSlot? _filterSlot;
  bool _multiSelect = false;
  Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    final saved = await SaveManager.load();
    setState(() {
      if (saved != null) _gameState = saved;
      _isLoading = false;
    });
  }

  Future<void> _saveGame() async {
    await SaveManager.save(_gameState);
  }

  void _selectEquip(Equipment equip) {
    setState(() {
      _selectedEquip = equip;
    });
  }

  void _doEnhance() {
    if (_selectedEquip == null) return;
    final equip = _selectedEquip!;
    if (equip.isMaxEnhance) return;

    final useProtect = _gameState.protectScroll > 0;
    final result = _gameState.tryEnhance(equip, useProtect: useProtect);

    setState(() {
      String log = '';
      switch (result) {
        case EnhanceResult.success:
          log = '✅ ${equip.name} +${equip.enhanceLevel} 강화 성공!';
          break;
        case EnhanceResult.fail:
          log = '❌ ${equip.name} 강화 실패...';
          break;
        case EnhanceResult.destroy:
          log = '💥 ${equip.name} 파괴!! +${equip.enhanceLevel}로 감소';
          break;
      }
      _logs.insert(0, log);
      if (_logs.length > 50) _logs.removeLast();
    });
    _saveGame();
  }

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFF5C842)),
              SizedBox(height: 16),
              Text('불러오는 중...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCurrencyBar(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A3A))),
      ),
      child: Column(
        children: [
          const Text('⚔️ 업그레이드 레전드 ⚔️',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF5C842))),
          const SizedBox(height: 4),
          Text('전투력: ${_formatNumber(_gameState.totalPower)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCurrencyBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A3A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCurrency('💰', '골드', _formatNumber(_gameState.gold), _showGoldDialog),
          _buildCurrency('💎', '다이아', _formatNumber(_gameState.diamond), _showDiamondDialog),
          _buildCurrency('🔮', '강화석', _gameState.enhanceStone.toString(), _showStoneDialog),
          _buildCurrency('🛡️', '방지권', _gameState.protectScroll.toString(), _showProtectDialog),
        ],
      ),
    );
  }

  Widget _buildCurrency(String icon, String name, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFFF5C842),
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          Text(name, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['⚔️ 강화', '🏰 던전', '🛒 상점', '🎒 인벤토리'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A3A))),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _currentTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? const Color(0xFFF5C842)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFF5C842) : Colors.grey,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case 0:
        return _buildEnhanceTab();
      case 1:
        return DungeonScreen(
          gameState: _gameState,
          onStateChanged: () { setState(() {}); _saveGame(); },
        );
      case 2:
        return ShopScreen(
          gameState: _gameState,
          onStateChanged: () { setState(() {}); _saveGame(); },
        );
      case 3:
        return _buildInventoryTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildEnhanceTab() {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽: 장비 부위별 UI
        // 왼쪽: 장비 부위별 UI
SizedBox(
  width: 260,
  child: Column(
    children: [
      GestureDetector(
        onTap: _showSetEquipDialog,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2A),
            border: Border.all(color: Colors.purple.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Center(
            child: Text('✨ 세트 자동 장착',
                style: TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          child: EquipmentUI(
            gameState: _gameState,
            onEquipTap: (equip, index) {
              setState(() => _selectedEquip = equip);
              _showEquipOptions(equip, index);
            },
          ),
        ),
      ),
    ],
  ),
),
              // 오른쪽: 강화 패널
              Expanded(child: _buildUpgradePanel()),
            ],
          ),
        ),
        _buildLogPanel(),
      ],
    );
  }

  Widget _buildEquipList() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFF2A2A3A))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('장착 장비',
                    style: TextStyle(
                        color: Color(0xFFF5C842),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                GestureDetector(
                  onTap: _showSetEquipDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2A),
                      border: Border.all(color: const Color(0xFF4A4A6A)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('세트 장착',
                        style: TextStyle(color: Colors.purple, fontSize: 10)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _gameState.equipped.length,
              itemBuilder: (context, index) {
                final equip = _gameState.equipped[index];
                final isSelected = _selectedEquip?.id == equip.id;
                return GestureDetector(
                  onTap: () => _selectEquip(equip),
                  onDoubleTap: () => _showEquipOptions(equip, index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1A1A0A) : const Color(0xFF111118),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFF5C842)
                            : const Color(0xFF2A2A3A),
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        Text(equip.slot.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${equip.name} +${equip.enhanceLevel}',
                                style: TextStyle(
                                    color: _gradeColor(equip.grade),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(equip.grade.name,
                                  style: const TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradePanel() {
    if (_selectedEquip == null) {
      return const Center(
        child: Text('← 장비를 선택하세요\n(더블클릭 시 교체/해제)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    final equip = _selectedEquip!;
    final data = getEnhanceData(equip.grade, equip.enhanceLevel);
    final canEnhance = data != null &&
        _gameState.gold >= data.goldCost &&
        _gameState.enhanceStone >= data.stoneCost &&
        !equip.isMaxEnhance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111118),
              border: Border.all(color: const Color(0xFF2A2A3A)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(equip.slot.emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(equip.name,
                    style: TextStyle(
                        color: _gradeColor(equip.grade),
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('+${equip.enhanceLevel}',
                    style: TextStyle(
                        color: _gradeColor(equip.grade),
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                Text('전투력 +${equip.power}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (data != null && !equip.isMaxEnhance) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111118),
                border: Border.all(color: const Color(0xFF2A2A3A)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow('성공률',
                      '${(data.successRate * 100).toStringAsFixed(2)}%',
                      data.successRate > 0.5
                          ? Colors.green
                          : data.successRate > 0.2
                              ? Colors.orange
                              : Colors.red),
                  _buildInfoRow('필요 골드', '${_formatNumber(data.goldCost)} G',
                      _gameState.gold >= data.goldCost ? Colors.white70 : Colors.red),
                  _buildInfoRow('필요 강화석', '${data.stoneCost}개',
                      _gameState.enhanceStone >= data.stoneCost ? Colors.white70 : Colors.red),
                  if (data.destroyRate > 0)
                    _buildInfoRow('파괴 확률',
                        '${(data.destroyRate * 100).toStringAsFixed(0)}%', Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canEnhance ? _doEnhance : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5C842),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('강화',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          ] else if (equip.isMaxEnhance) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111118),
                border: Border.all(color: const Color(0xFFF5C842)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '최대 강화 달성!\n${equip.grade.name} +${equip.grade.maxEnhance}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFF5C842), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value,
              style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLogPanel() {
    return Container(
      height: 100,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2A2A3A))),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('강화 기록',
                  style: TextStyle(
                      color: Color(0xFFF5C842),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                Color logColor = Colors.grey;
                if (log.startsWith('✅')) logColor = Colors.green;
                if (log.startsWith('❌')) logColor = Colors.red;
                if (log.startsWith('💥')) logColor = Colors.orange;
                return Text(log, style: TextStyle(color: logColor, fontSize: 11));
              },
            ),
          ),
        ],
      ),
    );
  }

  // _buildInventoryTab 교체용 코드
// main_screen.dart의 _buildInventoryTab 메서드 전체를 아래로 교체

  Widget _buildInventoryTab() {
    final inventory = _gameState.inventory;

    // 필터 적용
    var filtered = inventory.where((item) {
      if (_filterGrade != null && item.grade != _filterGrade) return false;
      if (_filterSlot != null && item.slot != _filterSlot) return false;
      return true;
    }).toList();

    // 정렬 적용
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'grade':
          final g = b.grade.index.compareTo(a.grade.index);
          return g != 0 ? g : b.enhanceLevel.compareTo(a.enhanceLevel);
        case 'enhance':
          return b.enhanceLevel.compareTo(a.enhanceLevel);
        case 'slot':
          return a.slot.index.compareTo(b.slot.index);
        default:
          return 0;
      }
    });

    return Column(
      children: [
        // 툴바
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF2A2A3A))),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // 아이템 수
                  Text('총 ${inventory.length}개',
                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const Spacer(),
                  // 다중선택 토글
                  GestureDetector(
                    onTap: () => setState(() {
                      _multiSelect = !_multiSelect;
                      if (!_multiSelect) _selectedItems.clear();
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _multiSelect ? const Color(0xFF2A2A4A) : const Color(0xFF1A1A2A),
                        border: Border.all(
                            color: _multiSelect ? Colors.purple : const Color(0xFF2A2A3A)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('선택 판매',
                          style: TextStyle(
                              color: _multiSelect ? Colors.purple : Colors.grey,
                              fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // 선택 판매 버튼
                  if (_multiSelect && _selectedItems.isNotEmpty)
                    GestureDetector(
                      onTap: _sellSelected,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A1A1A),
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${_selectedItems.length}개 판매',
                            style: const TextStyle(color: Colors.red, fontSize: 11)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  // 정렬
                  const Text('정렬: ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  _buildSortBtn('등급', 'grade'),
                  const SizedBox(width: 4),
                  _buildSortBtn('강화', 'enhance'),
                  const SizedBox(width: 4),
                  _buildSortBtn('슬롯', 'slot'),
                  const Spacer(),
                  // 필터 초기화
                  if (_filterGrade != null || _filterSlot != null)
                    GestureDetector(
                      onTap: () => setState(() {
                        _filterGrade = null;
                        _filterSlot = null;
                      }),
                      child: const Text('✕ 필터',
                          style: TextStyle(color: Colors.red, fontSize: 11)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // 등급 필터
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('등급: ', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ...ItemGrade.values.map((g) => _buildGradeFilterBtn(g)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 아이템 그리드
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('아이템이 없습니다', style: TextStyle(color: Colors.grey)),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isSelected = _selectedItems.contains(item.id);
                    return GestureDetector(
                      onTap: () {
                        if (_multiSelect) {
                          setState(() {
                            if (isSelected) _selectedItems.remove(item.id);
                            else _selectedItems.add(item.id);
                          });
                        } else {
                          final realIndex = inventory.indexOf(item);
                          _showItemDialog(item, realIndex);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2A1A2A)
                              : const Color(0xFF111118),
                          border: Border.all(
                            color: isSelected
                                ? Colors.purple
                                : _gradeColor(item.grade).withOpacity(0.6),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(item.slot.emoji, style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(item.name,
                                    style: TextStyle(
                                        color: _gradeColor(item.grade),
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                Text('+${item.enhanceLevel}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 7)),
                              ],
                            ),
                            if (_multiSelect && isSelected)
                              const Positioned(
                                top: 2, right: 2,
                                child: Text('✓', style: TextStyle(color: Colors.purple, fontSize: 10)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSortBtn(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A2A1A) : const Color(0xFF111118),
          border: Border.all(
              color: isSelected ? const Color(0xFFF5C842) : const Color(0xFF2A2A3A)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? const Color(0xFFF5C842) : Colors.grey,
                fontSize: 10)),
      ),
    );
  }

  Widget _buildGradeFilterBtn(ItemGrade grade) {
    final isSelected = _filterGrade == grade;
    final color = _gradeColor(grade);
    return GestureDetector(
      onTap: () => setState(() => _filterGrade = isSelected ? null : grade),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : const Color(0xFF111118),
          border: Border.all(color: isSelected ? color : const Color(0xFF2A2A3A)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(grade.name,
            style: TextStyle(color: isSelected ? color : Colors.grey, fontSize: 10)),
      ),
    );
  }

  void _sellSelected() {
    setState(() {
      int totalGold = 0;
      _gameState.inventory.removeWhere((item) {
        if (_selectedItems.contains(item.id)) {
          totalGold += _getSellPrice(item);
          return true;
        }
        return false;
      });
      _gameState.gold += totalGold;
      _selectedItems.clear();
      _multiSelect = false;
    });
    _saveGame();
  }

  void _showItemDialog(Equipment item, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: Text(item.name,
            style: TextStyle(color: _gradeColor(item.grade), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.slot.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text('등급: ${item.grade.name}', style: const TextStyle(color: Colors.grey)),
            Text('슬롯: ${item.slot.displayName}', style: const TextStyle(color: Colors.grey)),
            Text('전투력: +${item.power}',
                style: const TextStyle(color: Color(0xFFF5C842))),
            const SizedBox(height: 8),
            Text('판매가: 💰 ${_formatNumber(_getSellPrice(item))}',
                style: const TextStyle(color: Colors.greenAccent)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _gameState.gold += _getSellPrice(item);
                _gameState.inventory.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('판매', style: TextStyle(color: Color(0xFFF5C842))),
          ),
          TextButton(
            onPressed: () {
              _equipItem(item, index);
              Navigator.pop(context);
            },
            child: const Text('장착', style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  int _getSellPrice(Equipment item) {
    final base = {
      ItemGrade.normal: 500,
      ItemGrade.magic: 2000,
      ItemGrade.rare: 8000,
      ItemGrade.unique: 30000,
      ItemGrade.epic: 150000,
      ItemGrade.legendary: 800000,
    }[item.grade] ?? 500;
    return base + (item.enhanceLevel * base * 0.5).toInt();
  }

  void _equipItem(Equipment newItem, int inventoryIndex) {
    setState(() {
      final slotIndex = _gameState.equipped.indexWhere((e) => e.slot == newItem.slot);
      if (slotIndex != -1) {
        final old = _gameState.equipped[slotIndex];
        _gameState.inventory[inventoryIndex] = old;
        _gameState.equipped[slotIndex] = newItem;
      } else {
        _gameState.equipped.add(newItem);
        _gameState.inventory.removeAt(inventoryIndex);
      }
    });
  }

  // 장비 옵션 (더블클릭)
  void _showEquipOptions(Equipment equip, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: Text('${equip.name} +${equip.enhanceLevel}',
            style: TextStyle(color: _gradeColor(equip.grade), fontWeight: FontWeight.bold, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(equip.slot.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text('등급: ${equip.grade.name}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text('전투력: +${equip.power}', style: const TextStyle(color: Color(0xFFF5C842), fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(color: Colors.grey)),
          ),
          if (_gameState.inventory.any((i) => i.slot == equip.slot))
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showSlotSwapDialog(equip, index);
              },
              child: const Text('교체', style: TextStyle(color: Colors.blue)),
            ),
          TextButton(
            onPressed: () {
              setState(() {
                _gameState.inventory.add(equip);
                _gameState.equipped[index] = _getDefaultEquip(equip.slot);
                if (_selectedEquip?.id == equip.id) _selectedEquip = null;
              });
              Navigator.pop(context);
            },
            child: const Text('해제', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _showSlotSwapDialog(Equipment equipped, int equippedIndex) {
    final sameSlot = _gameState.inventory.where((i) => i.slot == equipped.slot).toList();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: const Text('교체할 아이템 선택', style: TextStyle(color: Color(0xFFF5C842))),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sameSlot.length,
            itemBuilder: (context, index) {
              final item = sameSlot[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    final invIndex = _gameState.inventory.indexOf(item);
                    _gameState.inventory[invIndex] = equipped;
                    _gameState.equipped[equippedIndex] = item;
                    if (_selectedEquip?.id == equipped.id) _selectedEquip = item;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2A),
                    border: Border.all(color: _gradeColor(item.grade).withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: [
                      Text(item.slot.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item.name} +${item.enhanceLevel}',
                                style: TextStyle(
                                    color: _gradeColor(item.grade),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            Text('전투력 +${item.power}',
                                style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Equipment _getDefaultEquip(ItemSlot slot) {
    final defaults = {
      ItemSlot.weapon: Equipment(id: 'eq_weapon', name: '낡은 검', grade: ItemGrade.normal, slot: ItemSlot.weapon, weaponType: WeaponType.sword, basePower: 50),
      ItemSlot.helmet: Equipment(id: 'eq_helmet', name: '천 두건', grade: ItemGrade.normal, slot: ItemSlot.helmet, basePower: 20),
      ItemSlot.armor: Equipment(id: 'eq_armor', name: '천 갑옷', grade: ItemGrade.normal, slot: ItemSlot.armor, basePower: 30),
      ItemSlot.gloves: Equipment(id: 'eq_gloves', name: '천 장갑', grade: ItemGrade.normal, slot: ItemSlot.gloves, basePower: 15),
      ItemSlot.shoes: Equipment(id: 'eq_shoes', name: '천 신발', grade: ItemGrade.normal, slot: ItemSlot.shoes, basePower: 15),
      ItemSlot.shirt: Equipment(id: 'eq_shirt', name: '낡은 셔츠', grade: ItemGrade.normal, slot: ItemSlot.shirt, basePower: 15),
      ItemSlot.cape: Equipment(id: 'eq_cape', name: '낡은 망토', grade: ItemGrade.normal, slot: ItemSlot.cape, basePower: 15),
      ItemSlot.belt: Equipment(id: 'eq_belt', name: '낡은 벨트', grade: ItemGrade.normal, slot: ItemSlot.belt, basePower: 15),
      ItemSlot.ring1: Equipment(id: 'eq_ring1', name: '나무 반지', grade: ItemGrade.normal, slot: ItemSlot.ring1, basePower: 10),
      ItemSlot.ring2: Equipment(id: 'eq_ring2', name: '나무 반지', grade: ItemGrade.normal, slot: ItemSlot.ring2, basePower: 10),
      ItemSlot.necklace: Equipment(id: 'eq_necklace', name: '가죽 목걸이', grade: ItemGrade.normal, slot: ItemSlot.necklace, basePower: 10),
    };
    return defaults[slot] ?? Equipment(id: 'default', name: '빈 슬롯', grade: ItemGrade.normal, slot: slot, basePower: 0);
  }

  // 인벤토리에서 세트 목록 파악
Map<String, List<Equipment>> _getInventorySetGroups() {
  final Map<String, List<Equipment>> groups = {};
  
  // 슬롯 중복 제거: 인벤토리 + 장착 합치되 같은 슬롯은 강화 높은 거 1개만
  final allItems = [..._gameState.inventory, ..._gameState.equipped];
  
  for (final item in allItems) {
    final theme = extractTheme(item);
    if (theme == null) continue;
    final key = '${item.grade.index}_$theme';
    groups.putIfAbsent(key, () => []).add(item);
  }
  
  // 각 그룹에서 슬롯별로 최고 강화 1개만 남기기
  for (final key in groups.keys) {
    final items = groups[key]!;
    final Map<ItemSlot, Equipment> bySlot = {};
    for (final item in items) {
      if (!bySlot.containsKey(item.slot) ||
          item.enhanceLevel > bySlot[item.slot]!.enhanceLevel) {
        bySlot[item.slot] = item;
      }
    }
    groups[key] = bySlot.values.toList();
  }
  
  return groups;
}

  void _showSetEquipDialog() {
    final groups = _getInventorySetGroups();
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('세트 아이템이 없습니다')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: const Text('⚔️ 세트 자동 장착',
            style: TextStyle(color: Color(0xFFF5C842))),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: groups.entries.map((entry) {
              final items = entry.value;
              final first = items.first;
              final theme = extractTheme(first)!;
              final grade = first.grade;
              final count = items.length;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _autoEquipSet(theme, grade);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2A),
                    border: Border.all(
                        color: _gradeColor(grade).withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '[$theme] ${grade.name} 세트',
                            style: TextStyle(
                                color: _gradeColor(grade),
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          Text('${count > 11 ? 11 : count} / 11 슬롯',
    style: TextStyle(
        color: count >= 11 ? Colors.green : Colors.grey, fontSize: 11)),
                        ],
                      ),
                      Text('장착 →',
                          style: TextStyle(
                              color: _gradeColor(grade), fontSize: 12)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _autoEquipSet(String theme, ItemGrade grade) {
    setState(() {
      // 인벤토리 + 현재 장착 장비에서 해당 세트 아이템 수집
      final allItems = [
        ..._gameState.inventory,
        ..._gameState.equipped,
      ].where((e) => extractTheme(e) == theme && e.grade == grade).toList();

      // 슬롯별로 강화 수치 높은 순 정렬
      final Map<ItemSlot, List<Equipment>> bySlot = {};
      for (final item in allItems) {
        bySlot.putIfAbsent(item.slot, () => []).add(item);
      }
      for (final slot in bySlot.keys) {
        bySlot[slot]!.sort((a, b) => b.enhanceLevel.compareTo(a.enhanceLevel));
      }

      // 각 슬롯에 최고 강화 장비 장착
      for (final entry in bySlot.entries) {
        final slot = entry.key;
        final best = entry.value.first;
        final equippedIndex = _gameState.equipped.indexWhere((e) => e.slot == slot);

        if (equippedIndex != -1) {
          final current = _gameState.equipped[equippedIndex];
          if (current.id != best.id) {
            // 현재 장착 장비를 인벤토리로
            if (!_gameState.equipped.contains(current)) continue;
            _gameState.inventory.remove(best);
            final currentInInv = _gameState.inventory.indexWhere((e) => e.id == current.id);
            if (currentInInv == -1) _gameState.inventory.add(current);
            _gameState.equipped[equippedIndex] = best;
          }
        }
      }

      // 선택된 장비 초기화
      _selectedEquip = null;
    });
    _saveGame();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('[$theme] ${grade.name} 세트 자동 장착 완료!'),
        backgroundColor: const Color(0xFF1A2A1A),
      ),
    );
  }


  // 재화 바 팝업들
  void _showGoldDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: const Text('💰 골드 획득 방법', style: TextStyle(color: Color(0xFFF5C842))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogRow('🏰 던전 클리어', '골드 드롭'),
            _buildDialogRow('🎒 장비 판매', '인벤토리에서 판매'),
            _buildDialogRow('💎 다이아 환전', '💎1 = 💰1,000'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentTab = 2);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2A1A),
                  border: Border.all(color: const Color(0xFF2A4A2A)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('→ 상점으로 이동',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.greenAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showDiamondDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: const Text('💎 다이아 충전', style: TextStyle(color: Color(0xFFF5C842))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildChargeOption('100 💎', '₩990', 100),
            _buildChargeOption('550 💎 (+50)', '₩4,900', 550),
            _buildChargeOption('1,200 💎 (+200) ⭐', '₩9,900', 1200),
            _buildChargeOption('6,500 💎 (+1000)', '₩49,900', 6500),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('다음에 할게요', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _showStoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: const Text('🔮 강화석 구매', style: TextStyle(color: Color(0xFFF5C842))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                if (_gameState.gold >= 500) {
                  setState(() {
                    _gameState.gold -= 500;
                    _gameState.enhanceStone += 1;
                  });
                  Navigator.pop(context);
                }
              },
              child: _buildPurchaseRow('강화석 1개', '💰 500', _gameState.gold >= 500),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                if (_gameState.diamond >= 30) {
                  setState(() {
                    _gameState.diamond -= 30;
                    _gameState.enhanceStone += 10;
                  });
                  Navigator.pop(context);
                }
              },
              child: _buildPurchaseRow('강화석 10개', '💎 30', _gameState.diamond >= 30),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showProtectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: const Text('🛡️ 파괴방지권 구매', style: TextStyle(color: Color(0xFFF5C842))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('파괴방지권은 강화 실패 시\n장비 파괴를 막아줍니다.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                if (_gameState.diamond >= 50) {
                  setState(() {
                    _gameState.diamond -= 50;
                    _gameState.protectScroll += 3;
                  });
                  Navigator.pop(context);
                }
              },
              child: _buildPurchaseRow('파괴방지권 3개', '💎 50', _gameState.diamond >= 50),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value, style: const TextStyle(color: Color(0xFFF5C842), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPurchaseRow(String label, String price, bool canAfford) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: canAfford ? const Color(0xFF1A1A2A) : const Color(0xFF0A0A0F),
        border: Border.all(color: canAfford ? const Color(0xFF3A3A5A) : const Color(0xFF1A1A1A)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: canAfford ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
          Text(price, style: TextStyle(color: canAfford ? const Color(0xFFF5C842) : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChargeOption(String label, String price, int amount) {
    return GestureDetector(
      onTap: () {
        setState(() => _gameState.chargeDiamond(amount));
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2A),
          border: Border.all(color: const Color(0xFF2A2A3A)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFFF5C842), fontWeight: FontWeight.bold)),
            Text(price, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}