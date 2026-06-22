import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../models/game_state.dart';
import '../models/enhance_data.dart';
import '../models/save_manager.dart';
import 'dungeon_screen.dart';
import 'shop_screen.dart';
import '../models/set_system.dart';
import 'equip_ui.dart';
import 'attendance_screen.dart';
import 'dart:async';
import '../widgets/enhance_ticker.dart';
import '../widgets/stat_bottom_sheet.dart';
import '../utils/sound_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  GameState _gameState = GameState();
  Equipment? _selectedEquip;
  final List<String> _logs = [];
  final _tickerController = StreamController<TickerMessage>.broadcast();
  int _currentTab = 0;
  bool _isLoading = true;

  // 인벤토리 정렬/필터
  String _sortBy = 'grade';
  ItemGrade? _filterGrade;
  ItemSlot? _filterSlot;
  bool _multiSelect = false;
  bool _showDuplicates = false; // 중복 아이템 필터
  Set<String> _selectedItems = {};

  // 강화 토글
  bool _autoProtect = false;
  bool _autoEnhance = false;
  bool _isAutoEnhancing = false;

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

  @override
  void dispose() {
    _tickerController.close();
    super.dispose();
  }

  Future<void> _saveGame() async {
    await SaveManager.save(_gameState);
  }

  void _selectEquip(Equipment equip) {
    setState(() => _selectedEquip = equip);
  }

  // ── 강화 관련 ──

  void _doEnhance() {
    if (_selectedEquip == null) return;
    final equip = _selectedEquip!;
    if (equip.isMaxEnhance) return;

    final data = getEnhanceData(equip.grade, equip.enhanceLevel);
    if (data == null) return;

    final needGold = _gameState.gold < data.goldCost;
    final needStone = _gameState.enhanceStone < data.stoneCost;
    if (needGold || needStone) {
      _showInsufficientDialog(needGold, needStone, data.goldCost, data.stoneCost);
      return;
    }

    if (_autoProtect) {
      if (data.destroyRate > 0 && _gameState.protectScroll == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🛡️ 방지권이 없어 강화를 중단했습니다.'),
            backgroundColor: Color(0xFF2A1A1A),
          ),
        );
        return;
      }
      _executeEnhance(equip, useProtect: data.destroyRate > 0);
      return;
    }

    if (data.destroyRate > 0) {
      _showProtectScrollPopup(equip, data);
    } else {
      _executeEnhance(equip, useProtect: false);
    }
  }

  Future<void> _startAutoEnhance() async {
    if (_isAutoEnhancing) {
      setState(() {
        _autoEnhance = false;
        _isAutoEnhancing = false;
      });
      return;
    }

    setState(() {
      _autoEnhance = true;
      _isAutoEnhancing = true;
    });

    while (_autoEnhance && _isAutoEnhancing) {
      if (_selectedEquip == null) break;
      final equip = _selectedEquip!;

      if (equip.isMaxEnhance) {
        _logs.insert(0, '🏆 최대 강화 달성! 자동 강화 중단.');
        break;
      }

      final data = getEnhanceData(equip.grade, equip.enhanceLevel);
      if (data == null) break;

      if (_gameState.gold < data.goldCost) {
        _logs.insert(0, '⛔ 골드 부족으로 자동 강화 중단.');
        break;
      }

      if (_gameState.enhanceStone < data.stoneCost) {
        _logs.insert(0, '⛔ 강화석 부족으로 자동 강화 중단.');
        break;
      }

      if (_autoProtect && data.destroyRate > 0 && _gameState.protectScroll == 0) {
        _logs.insert(0, '⛔ 방지권 부족으로 자동 강화 중단.');
        break;
      }

      final useProtect = _autoProtect && data.destroyRate > 0;
      _executeEnhance(equip, useProtect: useProtect);

      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) break;

      if (_selectedEquip?.isMaxEnhance == true) {
        _logs.insert(0, '🏆 최대 강화 달성! 자동 강화 중단.');
        break;
      }
    }

    if (mounted) {
      setState(() {
        _autoEnhance = false;
        _isAutoEnhancing = false;
      });
    }
  }

  void _stopAutoEnhance() {
    setState(() {
      _autoEnhance = false;
      _isAutoEnhancing = false;
    });
  }

  void _showInsufficientDialog(bool needGold, bool needStone, int goldCost, int stoneCost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: const Text('⚠️ 재료 부족', style: TextStyle(color: Colors.redAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (needGold)
              Text(
                '💰 골드 부족 (필요: ${_formatNumber(goldCost)} / 보유: ${_formatNumber(_gameState.gold)})',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            if (needStone)
              Text(
                '🪨 강화석 부족 (필요: $stoneCost / 보유: ${_gameState.enhanceStone})',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            const SizedBox(height: 12),
            const Text('상점에서 구매하시겠습니까?',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _currentTab = 2);
            },
            child: const Text('상점으로', style: TextStyle(color: Color(0xFFF5C842))),
          ),
        ],
      ),
    );
  }

  void _showProtectScrollPopup(Equipment equip, dynamic data) {
    final hasScroll = _gameState.protectScroll > 0;
    final canBuy = _gameState.diamond >= 50;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: Row(
          children: [
            const Text('⚠️ ', style: TextStyle(fontSize: 20)),
            Text('파괴 확률 ${(data.destroyRate * 100).toStringAsFixed(0)}% 감지',
                style: const TextStyle(
                    color: Colors.orange, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A14),
                border: Border.all(color: const Color(0xFF2A2A3A)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('보유 방지권', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text('🛡️ ${_gameState.protectScroll}개',
                      style: TextStyle(
                          color: hasScroll ? Colors.white : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (hasScroll) ...[
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _executeEnhance(equip, useProtect: true);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2A1A),
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🛡️ 방지권 사용하고 강화',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (!hasScroll) ...[
              if (canBuy) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _gameState.diamond -= 50;
                      _gameState.protectScroll += 3;
                    });
                    _executeEnhance(equip, useProtect: true);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2A),
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('💎 50으로 방지권 3개 구매 후 강화',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (!canBuy) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0A0A),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('⚠️ 방지권 없음 (💎 부족)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
                const SizedBox(height: 8),
              ],
            ],
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _executeEnhance(equip, useProtect: false);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0A0A),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('🎲 방지권 없이 강화 (파괴 위험)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ),
          ],
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

  void _executeEnhance(Equipment equip, {required bool useProtect}) {
    final result = _gameState.tryEnhance(equip, useProtect: useProtect);

    setState(() {
      switch (result) {
        case EnhanceResult.success:
          SoundManager.playSuccess();
          _logs.insert(0, '✅ ${equip.name} +${equip.enhanceLevel} 강화 성공!');
          _tickerController.add(TickerMessage(
            nickname: '나',
            grade: equip.grade.name,
            gradeIndex: equip.grade.index,
            level: equip.enhanceLevel,
            type: TickerType.success,
          ));
          break;
        case EnhanceResult.fail:
          SoundManager.playFail();
          _logs.insert(0, '❌ ${equip.name} 강화 실패...');
          _tickerController.add(TickerMessage(
            nickname: '나',
            grade: equip.grade.name,
            gradeIndex: equip.grade.index,
            level: equip.enhanceLevel,
            type: TickerType.fail,
          ));
          break;
        case EnhanceResult.destroy:
          SoundManager.playFail();
          _logs.insert(0, '💥 ${equip.name} 완전 파괴!');
          _tickerController.add(TickerMessage(
            nickname: '나',
            grade: equip.grade.name,
            gradeIndex: equip.grade.index,
            level: equip.enhanceLevel,
            type: TickerType.destroy,
          ));
          break;
      }
      if (_logs.length > 50) _logs.removeLast();
    });
    _saveGame();
  }

  // ── 유틸 ──

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

  // ── 빌드 ──

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
            EnhanceTicker(messageStream: _tickerController.stream),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final canClaim = _gameState.attendance.canClaimToday &&
        !_gameState.attendance.isCompleted;
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
          GestureDetector(
            onTap: () => showStatBottomSheet(
                context, _gameState.equipped, _gameState.premiumChargeCount),
            child: Text(
              '전투력: ${_formatNumber(_gameState.totalPower)} 📊',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceScreen(
                    gameState: _gameState,
                    onRewardClaimed: () => setState(() {}),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: canClaim
                    ? Colors.amber.withOpacity(0.2)
                    : const Color(0xFF1A1A2A),
                border: Border.all(
                    color: canClaim ? Colors.amber : const Color(0xFF2A2A3A)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                canClaim
                    ? '📅 출석 보상 받기!'
                    : '📅 출석 (${_gameState.attendance.currentDay}/30일)',
                style: TextStyle(
                  color: canClaim ? Colors.amber : Colors.grey,
                  fontSize: 11,
                  fontWeight: canClaim ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
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
          border: Border(bottom: BorderSide(color: Color(0xFF2A2A3A)))),
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
                      color: isSelected ? const Color(0xFFF5C842) : Colors.transparent,
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
      case 0: return _buildEnhanceTab();
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
      case 3: return _buildInventoryTab();
      default: return const SizedBox();
    }
  }

  Widget _buildEnhanceTab() {
    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              GestureDetector(
                onTap: _showSetEquipDialog,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2A),
                    border: Border.all(color: Colors.purple.withOpacity(0.6)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Center(
                    child: Text('✨ 세트 자동 장착',
                        style: TextStyle(
                            color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              Expanded(
                child: EquipmentUI(
                  gameState: _gameState,
                  onEquipTap: (equip, index) {
                    setState(() => _selectedEquip = equip);
                    _showEquipOptions(equip, index);
                  },
                ),
              ),
            ],
          ),
        ),
        _buildLogPanel(),
      ],
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
                    style: TextStyle(color: _gradeColor(equip.grade), fontSize: 16, fontWeight: FontWeight.bold)),
                Text('+${equip.enhanceLevel}',
                    style: TextStyle(color: _gradeColor(equip.grade), fontSize: 28, fontWeight: FontWeight.bold)),
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
                  _buildInfoRow('성공률', '${(data.successRate * 100).toStringAsFixed(2)}% +???',
                      data.successRate > 0.5 ? Colors.green : data.successRate > 0.2 ? Colors.orange : Colors.red),
                  _buildInfoRow('필요 골드', '${_formatNumber(data.goldCost)} G',
                      _gameState.gold >= data.goldCost ? Colors.white70 : Colors.red),
                  _buildInfoRow('필요 강화석', '${data.stoneCost}개',
                      _gameState.enhanceStone >= data.stoneCost ? Colors.white70 : Colors.red),
                  if (data.destroyRate > 0)
                    _buildInfoRow('파괴 확률', '${(data.destroyRate * 100).toStringAsFixed(0)}%', Colors.red),
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
                child: const Text('강화', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
          Text(value, style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLogPanel() {
    return Container(
      height: 100,
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF2A2A3A)))),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('강화 기록',
                  style: TextStyle(color: Color(0xFFF5C842), fontSize: 11, fontWeight: FontWeight.bold)),
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

  // ── 인벤토리 탭 ──

  Widget _buildInventoryTab() {
    final inventory = _gameState.inventory;

    // 필터 적용
    var filtered = inventory.where((item) {
      if (_filterGrade != null && item.grade != _filterGrade) return false;
      if (_filterSlot != null && item.slot != _filterSlot) return false;
      return true;
    }).toList();

    // 정렬
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'grade':
          final g = b.grade.index.compareTo(a.grade.index);
          return g != 0 ? g : b.enhanceLevel.compareTo(a.enhanceLevel);
        case 'enhance': return b.enhanceLevel.compareTo(a.enhanceLevel);
        case 'slot': return a.slot.index.compareTo(b.slot.index);
        default: return 0;
      }
    });

    // 같은 이름+등급+강화레벨 기준으로 그룹화
    final Map<String, List<Equipment>> groupMap = {};
    for (final item in filtered) {
      final key = '${item.name}_${item.grade.index}_${item.enhanceLevel}';
      groupMap.putIfAbsent(key, () => []).add(item);
    }

    // 중복 필터 ON이면 2개 이상인 그룹만
    var groups = groupMap.values.toList();
    if (_showDuplicates) {
      groups = groups.where((g) => g.length >= 2).toList();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF2A2A3A)))),
          child: Column(
            children: [
              Row(
                children: [
                  Text('총 ${inventory.length}개 (${groups.length}종)',
                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const Spacer(),
                  if (_filterGrade != null || _filterSlot != null || _showDuplicates)
                    GestureDetector(
                      onTap: () => setState(() {
                        _filterGrade = null;
                        _filterSlot = null;
                        _showDuplicates = false;
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A1A1A),
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('✕ 필터', style: TextStyle(color: Colors.red, fontSize: 11)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('정렬: ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  _buildSortBtn('등급', 'grade'),
                  const SizedBox(width: 4),
                  _buildSortBtn('강화', 'enhance'),
                  const SizedBox(width: 4),
                  _buildSortBtn('슬롯', 'slot'),
                  const SizedBox(width: 8),
                  // 중복 필터 버튼
                  GestureDetector(
                    onTap: () => setState(() => _showDuplicates = !_showDuplicates),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _showDuplicates ? Colors.orange.withOpacity(0.2) : const Color(0xFF111118),
                        border: Border.all(
                            color: _showDuplicates ? Colors.orange : const Color(0xFF2A2A3A)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('중복',
                          style: TextStyle(
                              color: _showDuplicates ? Colors.orange : Colors.grey,
                              fontSize: 10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
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
        Expanded(
          child: groups.isEmpty
              ? const Center(child: Text('아이템이 없습니다', style: TextStyle(color: Colors.grey)))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5, childAspectRatio: 0.75,
                    crossAxisSpacing: 6, mainAxisSpacing: 6,
                  ),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final item = group.first;
                    final count = group.length;

                    return GestureDetector(
                      onTap: () => _showStackedItemDialog(group),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF111118),
                          border: Border.all(
                            color: _gradeColor(item.grade).withOpacity(0.7),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(item.slot.emoji,
                                    style: const TextStyle(fontSize: 20)),
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
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 9)),
                              ],
                            ),
                            // 수량 뱃지
                            if (count > 1)
                              Positioned(
                                top: 3, right: 3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: _gradeColor(item.grade),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('x$count',
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold)),
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
    );
  }

  /// 스택된 아이템 탭 시 팝업 — 슬라이더로 수량 선택 후 판매/장착
  void _showStackedItemDialog(List<Equipment> group) {
    final item = group.first;
    final count = group.length;
    int sellCount = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF111118),
          title: Text(item.name,
              style: TextStyle(
                  color: _gradeColor(item.grade), fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.slot.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 4),
              Text('등급: ${item.grade.name}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text('강화: +${item.enhanceLevel}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('전투력: +${item.power}',
                  style: const TextStyle(color: Color(0xFFF5C842), fontSize: 12)),
              _buildStatSection(item),
              const Divider(color: Colors.white12),
              // 수량 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('보유 수량', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('$count개', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              // 판매 수량 슬라이더
              const Text('판매 수량', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Slider(
                value: sellCount.toDouble(),
                min: 1,
                max: count.toDouble(),
                divisions: count - 1,
                activeColor: const Color(0xFFF5C842),
                inactiveColor: Colors.white12,
                onChanged: (v) => setDialogState(() => sellCount = v.toInt()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$sellCount개 판매',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('💰 ${_formatNumber(_getSellPrice(item) * sellCount)}',
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기', style: TextStyle(color: Colors.grey)),
            ),
            // 장착 (1개만)
            TextButton(
              onPressed: () {
                final invIndex = _gameState.inventory.indexOf(item);
                if (invIndex != -1) {
                  _equipItem(item, invIndex);
                  Navigator.pop(context);
                }
              },
              child: const Text('장착', style: TextStyle(color: Colors.greenAccent)),
            ),
            // 판매
            TextButton(
              onPressed: () {
                setState(() {
                  int sold = 0;
                  _gameState.inventory.removeWhere((i) {
                    if (sold < sellCount &&
                        i.name == item.name &&
                        i.grade == item.grade &&
                        i.enhanceLevel == item.enhanceLevel) {
                      _gameState.gold += _getSellPrice(i);
                      sold++;
                      return true;
                    }
                    return false;
                  });
                });
                _saveGame();
                Navigator.pop(context);
              },
              child: const Text('판매', style: TextStyle(color: Color(0xFFF5C842))),
            ),
          ],
        ),
      ),
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
          border: Border.all(color: isSelected ? const Color(0xFFF5C842) : const Color(0xFF2A2A3A)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(color: isSelected ? const Color(0xFFF5C842) : Colors.grey, fontSize: 10)),
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

  // ── 아이템 다이얼로그 ──

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
            Text('전투력: +${item.power}', style: const TextStyle(color: Color(0xFFF5C842))),
            const SizedBox(height: 8),
            _buildStatSection(item),
            const SizedBox(height: 4),
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
            onPressed: () { _equipItem(item, index); Navigator.pop(context); },
            child: const Text('장착', style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSection(Equipment item) {
    final s = item.fakeStats;
    return Column(
      children: [
        const Divider(color: Colors.white12),
        const SizedBox(height: 4),
        const Text('스탯', style: TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 6),
        _statLine('⚔️ 공격력', s.atk, Colors.redAccent),
        _statLine('🛡️ 방어력', s.def, Colors.blueAccent),
        _statLine('❤️ 체력', s.hp, Colors.pinkAccent),
        _statLine('✨ 마력', s.mag, Colors.purpleAccent),
        _statLine('💨 민첩', s.agi, Colors.greenAccent),
      ],
    );
  }

  Widget _statLine(String label, int value, Color color) {
    final formatted = value >= 10000
        ? '${(value / 10000).toStringAsFixed(1)}만'
        : value >= 1000
            ? '${(value / 1000).toStringAsFixed(1)}천'
            : '$value';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          Text(formatted, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  int _getSellPrice(Equipment item) {
    final base = {
      ItemGrade.normal: 500, ItemGrade.magic: 2000, ItemGrade.rare: 8000,
      ItemGrade.unique: 30000, ItemGrade.epic: 150000, ItemGrade.legendary: 800000,
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
            const SizedBox(height: 4),
            Text('등급: ${equip.grade.name}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text('전투력: +${equip.power}', style: const TextStyle(color: Color(0xFFF5C842), fontSize: 12)),
            _buildStatSection(equip),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(color: Colors.grey)),
          ),
          if (_gameState.inventory.any((i) => i.slot == equip.slot))
            TextButton(
              onPressed: () { Navigator.pop(context); _showSlotSwapDialog(equip, index); },
              child: const Text('교체', style: TextStyle(color: Colors.blue)),
            ),
          TextButton(
            onPressed: () {
              setState(() {
                _gameState.inventory.add(equip);
                _gameState.equipped[index] = _getDefaultEquip(equip.slot);
                if (_selectedEquip?.id == equip.id) _selectedEquip = null;
              });
              _saveGame();
              Navigator.pop(context);
            },
            child: const Text('해제', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); _showEnhancePopup(equip); },
            child: const Text('강화', style: TextStyle(color: Color(0xFFF5C842))),
          ),
        ],
      ),
    );
  }

  void _showEnhancePopup(Equipment equip) {
    setState(() => _selectedEquip = equip);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // 최신 equip 상태 참조
          final currentEquip = _selectedEquip;
          if (currentEquip == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
            return const SizedBox();
          }

          final data = getEnhanceData(currentEquip.grade, currentEquip.enhanceLevel);
          final canEnhance = data != null &&
              _gameState.gold >= data.goldCost &&
              _gameState.enhanceStone >= data.stoneCost &&
              !currentEquip.isMaxEnhance;

          // 자동 강화 중 주기적 갱신
          if (_isAutoEnhancing) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) setDialogState(() {});
            });
          }

          return PopScope(
            // 팝업 닫힐 때 자동 강화 중단
            onPopInvoked: (didPop) {
              if (didPop) _stopAutoEnhance();
            },
            child: AlertDialog(
              backgroundColor: const Color(0xFF111118),
              contentPadding: const EdgeInsets.all(16),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 장비 정보
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A14),
                        border: Border.all(color: const Color(0xFF2A2A3A)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(currentEquip.slot.emoji, style: const TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          Text(currentEquip.name,
                              style: TextStyle(color: _gradeColor(currentEquip.grade),
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('+${currentEquip.enhanceLevel}',
                              style: TextStyle(color: _gradeColor(currentEquip.grade),
                                  fontSize: 28, fontWeight: FontWeight.bold)),
                          Text('전투력 +${currentEquip.power}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (data != null && !currentEquip.isMaxEnhance) ...[
                      // 강화 정보
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A14),
                          border: Border.all(color: const Color(0xFF2A2A3A)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('성공률',
                                '${(data.successRate * 100).toStringAsFixed(2)}% +???',
                                data.successRate > 0.5 ? Colors.green
                                    : data.successRate > 0.2 ? Colors.orange : Colors.red),
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

                      // 토글 영역
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A14),
                          border: Border.all(color: const Color(0xFF2A2A3A)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // 방지권 자동 사용
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('🛡️ 방지권 자동 사용',
                                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text('보유: ${_gameState.protectScroll}개',
                                        style: TextStyle(
                                            color: _gameState.protectScroll > 0
                                                ? Colors.greenAccent : Colors.red,
                                            fontSize: 10)),
                                  ],
                                ),
                                Switch(
                                  value: _autoProtect,
                                  onChanged: (v) => setDialogState(() => setState(() => _autoProtect = v)),
                                  activeColor: Colors.greenAccent,
                                  inactiveThumbColor: Colors.grey,
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white12, height: 8),
                            // 자동 강화
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('⚡ 자동 강화',
                                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    const Text('소모품 소진까지 자동 반복',
                                        style: TextStyle(color: Colors.grey, fontSize: 10)),
                                  ],
                                ),
                                Switch(
                                  value: _isAutoEnhancing,
                                  onChanged: canEnhance
                                      ? (v) { setDialogState(() {}); _startAutoEnhance(); }
                                      : null,
                                  activeColor: Colors.orangeAccent,
                                  inactiveThumbColor: Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 강화 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: canEnhance && !_isAutoEnhancing
                              ? () async {
                                  _doEnhance();
                                  await Future.delayed(const Duration(milliseconds: 50));
                                  if (!mounted) return;
                                  setDialogState(() {});
                                  if (_selectedEquip?.isMaxEnhance == true) {
                                    Navigator.pop(context);
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isAutoEnhancing ? Colors.grey : const Color(0xFFF5C842),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: Text(
                            _isAutoEnhancing ? '자동 강화 중...' : '강화',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ] else if (currentEquip.isMaxEnhance) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111118),
                          border: Border.all(color: const Color(0xFFF5C842)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🏆 최대 강화 달성!\n${currentEquip.grade.name} +${currentEquip.grade.maxEnhance}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFF5C842), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _stopAutoEnhance();
                    Navigator.pop(context);
                  },
                  child: const Text('닫기', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          );
        },
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
                                style: TextStyle(color: _gradeColor(item.grade),
                                    fontWeight: FontWeight.bold, fontSize: 12)),
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

  // ── 세트 자동 장착 ──

  Map<String, List<Equipment>> _getInventorySetGroups() {
    final Map<String, List<Equipment>> groups = {};
    final allItems = [..._gameState.inventory, ..._gameState.equipped];
    for (final item in allItems) {
      final theme = extractTheme(item);
      if (theme == null) continue;
      final key = '${item.grade.index}_$theme';
      groups.putIfAbsent(key, () => []).add(item);
    }
    for (final key in groups.keys) {
      final items = groups[key]!;
      final Map<ItemSlot, Equipment> bySlot = {};
      for (final item in items) {
        if (!bySlot.containsKey(item.slot) || item.enhanceLevel > bySlot[item.slot]!.enhanceLevel) {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('세트 아이템이 없습니다')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: const Text('⚔️ 세트 자동 장착', style: TextStyle(color: Color(0xFFF5C842))),
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
                onTap: () { Navigator.pop(context); _autoEquipSet(theme, grade); },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2A),
                    border: Border.all(color: _gradeColor(grade).withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('[$theme] ${grade.name} 세트',
                              style: TextStyle(color: _gradeColor(grade), fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${count > 11 ? 11 : count} / 11 슬롯',
                              style: TextStyle(color: count >= 11 ? Colors.green : Colors.grey, fontSize: 11)),
                        ],
                      ),
                      Text('장착 →', style: TextStyle(color: _gradeColor(grade), fontSize: 12)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  void _autoEquipSet(String theme, ItemGrade grade) {
    setState(() {
      final allItems = [..._gameState.inventory, ..._gameState.equipped]
          .where((e) => extractTheme(e) == theme && e.grade == grade).toList();
      final Map<ItemSlot, List<Equipment>> bySlot = {};
      for (final item in allItems) { bySlot.putIfAbsent(item.slot, () => []).add(item); }
      for (final slot in bySlot.keys) { bySlot[slot]!.sort((a, b) => b.enhanceLevel.compareTo(a.enhanceLevel)); }
      for (final entry in bySlot.entries) {
        final slot = entry.key;
        final best = entry.value.first;
        final equippedIndex = _gameState.equipped.indexWhere((e) => e.slot == slot);
        if (equippedIndex != -1) {
          final current = _gameState.equipped[equippedIndex];
          if (current.id != best.id) {
            if (!_gameState.equipped.contains(current)) continue;
            _gameState.inventory.remove(best);
            final currentInInv = _gameState.inventory.indexWhere((e) => e.id == current.id);
            if (currentInInv == -1) _gameState.inventory.add(current);
            _gameState.equipped[equippedIndex] = best;
          }
        }
      }
      _selectedEquip = null;
    });
    _saveGame();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('[$theme] ${grade.name} 세트 자동 장착 완료!'), backgroundColor: const Color(0xFF1A2A1A)),
    );
  }

  // ── 재화 바 팝업들 ──

  void _showGoldDialog() {
    int exchangeAmount = 1;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF111118),
          title: const Text('💰 골드 획득 방법', style: TextStyle(color: Color(0xFFF5C842))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogRow('🏰 던전 클리어', '골드 드롭'),
              _buildDialogRow('🎒 장비 판매', '인벤토리에서 판매'),
              const Divider(color: Colors.white12),
              const SizedBox(height: 4),
              const Text('💎 다이아 → 💰 골드 환전', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Slider(
                value: exchangeAmount.toDouble(),
                min: 1,
                max: _gameState.diamond.toDouble().clamp(1, 10000),
                divisions: (_gameState.diamond.clamp(1, 10000) - 1).toInt(),
                activeColor: const Color(0xFFF5C842),
                inactiveColor: Colors.white12,
                onChanged: (v) => setDialogState(() => exchangeAmount = v.toInt()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('💎 $exchangeAmount', style: const TextStyle(color: Colors.blueAccent, fontSize: 13)),
                  const Text('→', style: TextStyle(color: Colors.white38)),
                  Text('💰 ${_formatNumber(exchangeAmount * 1000)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _gameState.diamond >= exchangeAmount
                    ? () {
                        setState(() {
                          _gameState.diamond -= exchangeAmount;
                          _gameState.gold += exchangeAmount * 1000;
                        });
                        Navigator.pop(context);
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _gameState.diamond >= exchangeAmount ? const Color(0xFF1A2A1A) : const Color(0xFF0A0A0F),
                    border: Border.all(color: _gameState.diamond >= exchangeAmount ? const Color(0xFF2A4A2A) : Colors.white12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _gameState.diamond >= exchangeAmount ? '환전하기' : '다이아 부족',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _gameState.diamond >= exchangeAmount ? Colors.greenAccent : Colors.white24),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기', style: TextStyle(color: Colors.grey))),
          ],
        ),
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
            _buildChargeOption('1,000 💎', '₩1,000', 1000),
            _buildChargeOption('40,000 💎 (+30,000) 🔥', '₩9,900', 40000),
            _buildChargeOption('1,100,000 💎 (+1,000,000) ⭐', '₩49,900', 1100000),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF2A2A3A)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () { Navigator.pop(context); _showCouponDialog(); },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2A),
                  border: Border.all(color: Colors.purple.withOpacity(0.6)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('🎟️ 쿠폰 코드 입력',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('다음에 할게요', style: TextStyle(color: Colors.grey, fontSize: 11))),
        ],
      ),
    );
  }

  void _showCouponDialog() {
    final controller = TextEditingController();
    const Map<String, int> validCoupons = {
      'UPGRADELEGEND': 100000, 'DIAMONDKING': 100000, 'LEGENDSTART': 100000,
    };
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          String? errorMsg;
          return AlertDialog(
            backgroundColor: const Color(0xFF111118),
            title: const Text('🎟️ 쿠폰 코드 입력', style: TextStyle(color: Color(0xFFF5C842))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('쿠폰 코드를 입력하세요.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: '예) LEGEND2024',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true, fillColor: const Color(0xFF0A0A14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A2A3A))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A2A3A))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.purple)),
                  ),
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey))),
              TextButton(
                onPressed: () {
                  final code = controller.text.trim().toUpperCase();
                  if (!validCoupons.containsKey(code)) {
                    setDialogState(() => errorMsg = '❌ 유효하지 않은 쿠폰 코드입니다.');
                    return;
                  }
                  final reward = validCoupons[code]!;
                  setState(() => _gameState.diamond += reward);
                  _saveGame();
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF111118),
                      title: const Text('🎟️ 쿠폰 적용 완료!',
                          style: TextStyle(color: Color(0xFFF5C842), fontWeight: FontWeight.bold)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 50)),
                          const SizedBox(height: 12),
                          const Text('쿠폰이 정상적으로 적용되었습니다.',
                              textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text('💎 ${_formatNumber(reward)}개 지급!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인', style: TextStyle(color: Color(0xFFF5C842)))),
                      ],
                    ),
                  );
                },
                child: const Text('확인', style: TextStyle(color: Color(0xFFF5C842))),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStoneDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF111118),
          title: const Text('🔮 강화석 구매', style: TextStyle(color: Color(0xFFF5C842))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (_gameState.gold >= 500) {
                    setState(() { _gameState.gold -= 500; _gameState.enhanceStone += 1; });
                    setDialogState(() {});
                  }
                },
                child: _buildPurchaseRow('강화석 1개', '💰 500', _gameState.gold >= 500),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  if (_gameState.diamond >= 30) {
                    setState(() { _gameState.diamond -= 30; _gameState.enhanceStone += 10; });
                    setDialogState(() {});
                  }
                },
                child: _buildPurchaseRow('강화석 10개', '💎 30', _gameState.diamond >= 30),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  if (_gameState.diamond >= 250) {
                    setState(() { _gameState.diamond -= 250; _gameState.enhanceStone += 100; });
                    setDialogState(() {});
                  }
                },
                child: _buildPurchaseRow('강화석 100개', '💎 250', _gameState.diamond >= 250),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기', style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  void _showProtectDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF111118),
          title: const Text('🛡️ 파괴방지권 구매', style: TextStyle(color: Color(0xFFF5C842))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('파괴방지권은 강화 시도마다 1개 소모됩니다.',
                  style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  if (_gameState.diamond >= 50) {
                    setState(() { _gameState.diamond -= 50; _gameState.protectScroll += 3; });
                    setDialogState(() {});
                  }
                },
                child: _buildPurchaseRow('파괴방지권 3개', '💎 50', _gameState.diamond >= 50),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  if (_gameState.diamond >= 450) {
                    setState(() { _gameState.diamond -= 450; _gameState.protectScroll += 30; });
                    setDialogState(() {});
                  }
                },
                child: _buildPurchaseRow('파괴방지권 30개', '💎 450', _gameState.diamond >= 450),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  if (_gameState.diamond >= 1400) {
                    setState(() { _gameState.diamond -= 1400; _gameState.protectScroll += 100; });
                    setDialogState(() {});
                  }
                },
                child: _buildPurchaseRow('파괴방지권 100개', '💎 1,400', _gameState.diamond >= 1400),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기', style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  // ── 공통 위젯 ──

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
      onTap: () { setState(() => _gameState.chargeDiamond(amount)); Navigator.pop(context); },
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