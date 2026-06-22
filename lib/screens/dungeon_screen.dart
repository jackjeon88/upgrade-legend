import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/item_database.dart';
import '../models/equipment.dart';
import 'dart:async';
import 'dart:math';

class DungeonScreen extends StatefulWidget {
  final GameState gameState;
  final VoidCallback onStateChanged;

  const DungeonScreen({
    super.key,
    required this.gameState,
    required this.onStateChanged,
  });

  @override
  State<DungeonScreen> createState() => _DungeonScreenState();
}

class _DungeonScreenState extends State<DungeonScreen>
    with TickerProviderStateMixin {
  bool _isClearing = false;
  bool _autoDungeon = false; // 자동 던전 토글

  Timer? _energyTimer;
  Timer? _progressTimer;
  double _battleProgress = 0.0;
  int _battleStage = 0; // 0:대기 1:입장 2:전투 3:클리어 4:실패
  String _battleMessage = '';
  String _monsterEmoji = '';
  String _dungeonEmoji = '';
  int _hitCount = 0;
  List<String> _battleEffects = [];

  late AnimationController _shakeController;
  late AnimationController _hitController;
  late Animation<double> _shakeAnim;
  late Animation<double> _hitAnim;

  final List<Map<String, dynamic>> _dungeons = [
    {
      'name': '초보자의 동굴', 'requiredPower': 0,
      'goldMin': 50, 'goldMax': 300,
      'emoji': '🕳️', 'monster': '🐀',
      'stoneMin': 0, 'stoneMax': 1,
      'diamondMin': 0, 'diamondMax': 0, 'diamondChance': 0.0,
      'dropTable': [
        {'grade': ItemGrade.normal, 'chance': 0.05},
      ],
    },
    {
      'name': '고블린 소굴', 'requiredPower': 2000,
      'goldMin': 300, 'goldMax': 800,
      'emoji': '👺', 'monster': '👺',
      'stoneMin': 0, 'stoneMax': 1,
      'diamondMin': 0, 'diamondMax': 0, 'diamondChance': 0.0,
      'dropTable': [
        {'grade': ItemGrade.normal, 'chance': 0.10},
        {'grade': ItemGrade.magic, 'chance': 0.02},
      ],
    },
    {
      'name': '해골 무덤', 'requiredPower': 6000,
      'goldMin': 800, 'goldMax': 2000,
      'emoji': '💀', 'monster': '💀',
      'stoneMin': 1, 'stoneMax': 2,
      'diamondMin': 0, 'diamondMax': 0, 'diamondChance': 0.0,
      'dropTable': [
        {'grade': ItemGrade.normal, 'chance': 0.15},
        {'grade': ItemGrade.magic, 'chance': 0.05},
      ],
    },
    {
      'name': '오크 요새', 'requiredPower': 15000,
      'goldMin': 2000, 'goldMax': 5000,
      'emoji': '🏰', 'monster': '👊',
      'stoneMin': 1, 'stoneMax': 2,
      'diamondMin': 1, 'diamondMax': 1, 'diamondChance': 0.10,
      'dropTable': [
        {'grade': ItemGrade.magic, 'chance': 0.10},
        {'grade': ItemGrade.rare, 'chance': 0.02},
      ],
    },
    {
      'name': '트롤 동굴', 'requiredPower': 35000,
      'goldMin': 5000, 'goldMax': 12000,
      'emoji': '👹', 'monster': '👹',
      'stoneMin': 2, 'stoneMax': 3,
      'diamondMin': 1, 'diamondMax': 2, 'diamondChance': 0.20,
      'dropTable': [
        {'grade': ItemGrade.magic, 'chance': 0.15},
        {'grade': ItemGrade.rare, 'chance': 0.05},
      ],
    },
    {
      'name': '드래곤 둥지', 'requiredPower': 80000,
      'goldMin': 12000, 'goldMax': 30000,
      'emoji': '🐉', 'monster': '🐉',
      'stoneMin': 2, 'stoneMax': 4,
      'diamondMin': 2, 'diamondMax': 3, 'diamondChance': 0.30,
      'dropTable': [
        {'grade': ItemGrade.rare, 'chance': 0.10},
        {'grade': ItemGrade.unique, 'chance': 0.01},
      ],
    },
    {
      'name': '마왕의 성', 'requiredPower': 160000,
      'goldMin': 30000, 'goldMax': 80000,
      'emoji': '👿', 'monster': '👿',
      'stoneMin': 3, 'stoneMax': 5,
      'diamondMin': 3, 'diamondMax': 5, 'diamondChance': 0.40,
      'dropTable': [
        {'grade': ItemGrade.rare, 'chance': 0.15},
        {'grade': ItemGrade.unique, 'chance': 0.03},
      ],
    },
    {
      'name': '신계의 탑', 'requiredPower': 350000,
      'goldMin': 80000, 'goldMax': 200000,
      'emoji': '🗼', 'monster': '⚡',
      'stoneMin': 4, 'stoneMax': 6,
      'diamondMin': 5, 'diamondMax': 10, 'diamondChance': 0.50,
      'dropTable': [
        {'grade': ItemGrade.unique, 'chance': 0.05},
        {'grade': ItemGrade.epic, 'chance': 0.01},
      ],
    },
  ];

  List<String> _getWeaponEffects(GameState gs) {
    final weapon = gs.equipped.where((e) => e.slot == ItemSlot.weapon).toList();
    if (weapon.isEmpty) return ['⚔️'];
    final w = weapon.first;
    if (w.grade == ItemGrade.legendary) return ['⚡', '💥', '🌟', '✨'];
    if (w.grade == ItemGrade.epic) return ['💥', '🔥', '✨'];
    if (w.grade == ItemGrade.unique) return ['🔥', '💫'];
    if (w.grade == ItemGrade.rare) return ['💫', '⚔️'];
    return ['⚔️', '🗡️'];
  }

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _shakeAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticInOut),
    );
    _hitController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _hitAnim = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _hitController, curve: Curves.easeOut),
    );
    _energyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      widget.gameState.updateEnergy();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _autoDungeon = false; // dispose 시 자동 던전 중단
    _energyTimer?.cancel();
    _progressTimer?.cancel();
    _shakeController.dispose();
    _hitController.dispose();
    super.dispose();
  }

  int _calcClearTimeMs(int power, int required) {
    const base = 5000;
    const minTime = 1500;
    final effectivePower = power <= 0 ? 1 : power;
    final effectiveRequired = required <= 0 ? 100 : required;
    final ratio = effectivePower / effectiveRequired;
    return max(minTime, (base / ratio).toInt());
  }

  /// 자동 던전 — 에너지 소진까지 최고 던전 반복
  Future<void> _startAutoDungeon() async {
    if (_autoDungeon) {
      setState(() => _autoDungeon = false);
      return;
    }
    setState(() => _autoDungeon = true);

    while (_autoDungeon && mounted) {
      final gs = widget.gameState;
      final power = gs.totalPower;

      // 에너지 부족 시 중단
      if (!gs.canEnterDungeon) {
        setState(() => _autoDungeon = false);
        break;
      }

      // 클리어 가능한 최고 던전 선택
      final available = _dungeons
          .where((d) => power >= (d['requiredPower'] as int))
          .toList();
      if (available.isEmpty) {
        setState(() => _autoDungeon = false);
        break;
      }
      final best = available.last;

      // 던전 입장 후 완료까지 대기
      final clearTimeMs = _calcClearTimeMs(power, best['requiredPower'] as int);
      _enterDungeon(best);
      await Future.delayed(Duration(milliseconds: clearTimeMs + 1500));

      // 다음 진입 전 짧은 대기
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _enterDungeon(Map<String, dynamic> dungeon) async {
    if (_isClearing) return;
    final power = widget.gameState.totalPower;
    final required = dungeon['requiredPower'] as int;

    if (!widget.gameState.consumeEnergy()) {
      setState(() {
        _battleStage = 4;
        _battleMessage = '⚡ 에너지가 부족합니다!';
      });
      return;
    }
    widget.onStateChanged();

    final clearTimeMs = _calcClearTimeMs(power, required);
    final effects = _getWeaponEffects(widget.gameState);

    setState(() {
      _isClearing = true;
      _battleStage = 1;
      _battleProgress = 0.0;
      _battleMessage = '${dungeon['emoji']} ${dungeon['name']} 입장...';
      _monsterEmoji = dungeon['monster'];
      _dungeonEmoji = dungeon['emoji'];
      _hitCount = 0;
      _battleEffects = [];
    });

    await Future.delayed(const Duration(milliseconds: 700));

    if (power < required) {
      setState(() {
        _isClearing = false;
        _battleStage = 4;
        _battleMessage = '💔 전투력 부족! (필요: ${_formatNumber(required)})';
      });
      _shakeController.forward(from: 0);
      widget.gameState.energy += GameState.dungeonEnergyCost;
      widget.onStateChanged();
      return;
    }

    setState(() {
      _battleStage = 2;
      _battleMessage = '${dungeon['monster']} 전투 중...';
    });

    final totalTicks = 20;
    final tickMs = clearTimeMs ~/ totalTicks;
    int tick = 0;
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(Duration(milliseconds: tickMs), (t) {
      if (!mounted) { t.cancel(); return; }
      tick++;
      setState(() {
        _battleProgress = tick / totalTicks;
        if (tick % 4 == 0) {
          _hitCount++;
          final effect = effects[_hitCount % effects.length];
          _battleEffects = [..._battleEffects, effect];
          if (_battleEffects.length > 5) _battleEffects.removeAt(0);
        }
        if (tick % 4 == 0) {
          _battleMessage = _hitMessages[_hitCount % _hitMessages.length];
        }
      });
      _hitController.forward(from: 0);

      if (tick >= totalTicks) {
        t.cancel();
        _onClearComplete(dungeon, power, clearTimeMs);
      }
    });
  }

  final List<String> _hitMessages = [
    '⚔️ 강타!', '💥 크리티컬!', '🔥 불꽃 공격!',
    '⚡ 번개 강타!', '💫 연속 공격!', '🌟 필살기!',
  ];

  void _onClearComplete(Map<String, dynamic> dungeon, int power, int clearTimeMs) async {
    final random = Random();
    final required = dungeon['requiredPower'] as int;
    final goldMin = dungeon['goldMin'] as int;
    final goldMax = dungeon['goldMax'] as int;
    final stoneMin = dungeon['stoneMin'] as int;
    final stoneMax = dungeon['stoneMax'] as int;
    final diamondChance = (dungeon['diamondChance'] ?? 0.0) as double;
    final diamondMin = (dungeon['diamondMin'] ?? 0) as int;
    final diamondMax = (dungeon['diamondMax'] ?? 0) as int;

    final base = random.nextInt(goldMax - goldMin) + goldMin;
    final effectiveRequired = required <= 0 ? 100 : required;
    final bonus = power >= effectiveRequired * 2 ? (base * 0.3).toInt() : 0;
    final totalGold = base + bonus;

    final stoneDrop = stoneMin + random.nextInt(stoneMax - stoneMin + 1);

    int diamondDrop = 0;
    if (diamondChance > 0 && random.nextDouble() < diamondChance) {
      diamondDrop = diamondMin + random.nextInt(diamondMax - diamondMin + 1);
    }

    Equipment? droppedItem;
    final dropTable = dungeon['dropTable'] as List;
    for (final drop in dropTable) {
      if (random.nextDouble() < (drop['chance'] as double)) {
        droppedItem = generateItem(drop['grade'] as ItemGrade);
        break;
      }
    }

    widget.gameState.gold += totalGold;
    widget.gameState.enhanceStone += stoneDrop;
    if (diamondDrop > 0) widget.gameState.diamond += diamondDrop;
    if (droppedItem != null) widget.gameState.inventory.add(droppedItem);
    widget.onStateChanged();

    final baseClearTimeMs = _calcClearTimeMs(
        required <= 0 ? 100 : required, required <= 0 ? 100 : required);
    final actualSec = (clearTimeMs / 1000).toStringAsFixed(1);
    final savedSec = ((baseClearTimeMs - clearTimeMs) / 1000).toStringAsFixed(1);

    String timeMsg = '⏱ ${actualSec}초';
    if (baseClearTimeMs > clearTimeMs) {
      timeMsg += ' (-${savedSec}초 단축)';
    }

    String msg = '🏆 클리어!  $timeMsg\n💰 +${_formatNumber(totalGold)}';
    if (stoneDrop > 0) msg += '  🔮 +$stoneDrop';
    if (diamondDrop > 0) msg += '  💎 +$diamondDrop';
    if (droppedItem != null) msg += '\n🎁 ${droppedItem.name} 획득!';

    setState(() {
      _isClearing = false;
      _battleStage = 3;
      _battleProgress = 1.0;
      _battleMessage = msg;
    });
  }

  String _formatNumber(int n) {
    if (n >= 1000000000) return '${(n / 1000000000).toStringAsFixed(1)}B';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '${m}분 ${s}초' : '${s}초';
  }

  Color _stageColor() {
    switch (_battleStage) {
      case 1: return Colors.blue;
      case 2: return Colors.orange;
      case 3: return Colors.green;
      case 4: return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gameState;
    final power = gs.totalPower;

    return Column(
      children: [
        // 전투력 + 에너지
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF111118),
            border: Border.all(color: const Color(0xFF2A2A3A)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [
                    const Text('⚡ 전투력',
                        style: TextStyle(color: Colors.grey, fontSize: 11)),
                    Text(_formatNumber(power),
                        style: const TextStyle(
                            color: Color(0xFFF5C842),
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ]),
                  Column(children: [
                    const Text('🔋 에너지',
                        style: TextStyle(color: Colors.grey, fontSize: 11)),
                    Text('${gs.energy} / ${GameState.maxEnergy}',
                        style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: gs.energy / GameState.maxEnergy,
                  backgroundColor: const Color(0xFF2A2A3A),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  minHeight: 8,
                ),
              ),
              if (gs.energy < GameState.maxEnergy) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('다음 회복: ${_formatTime(gs.secondsUntilNextEnergy)}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11)),
                    GestureDetector(
                      onTap: () {
                        if (gs.diamond >= 30) {
                          gs.rechargeEnergyWithDiamond();
                          widget.onStateChanged();
                          setState(() {});
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B0000),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('💎 30 즉시 충전',
                            style:
                                TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // 전투 애니메이션 패널
        if (_battleStage > 0)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A14),
              border: Border.all(color: _stageColor().withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                if (_battleStage == 2)
                  SizedBox(
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _shakeAnim,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(
                                _battleStage == 4 ? _shakeAnim.value : 0, 0),
                            child: ScaleTransition(
                              scale: _hitAnim,
                              child: Text(_monsterEmoji,
                                  style: const TextStyle(fontSize: 40)),
                            ),
                          ),
                        ),
                        ..._battleEffects.asMap().entries.map((e) => Positioned(
                              left: 20.0 + e.key * 25,
                              top: 0,
                              child: Text(e.value,
                                  style: const TextStyle(fontSize: 20)),
                            )),
                      ],
                    ),
                  ),
                if (_battleStage == 3)
                  const Text('🏆', style: TextStyle(fontSize: 40)),
                if (_battleStage == 4)
                  const Text('💔', style: TextStyle(fontSize: 40)),
                if (_battleStage == 1)
                  Text(_dungeonEmoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                if (_battleStage == 2)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _battleProgress,
                      backgroundColor: const Color(0xFF2A2A3A),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_stageColor()),
                      minHeight: 6,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  _battleMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _stageColor(),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // ── 자동 던전 토글 ──
        GestureDetector(
          onTap: _startAutoDungeon,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: _autoDungeon
                  ? const Color(0xFF1A2A1A)
                  : const Color(0xFF111118),
              border: Border.all(
                  color: _autoDungeon
                      ? Colors.greenAccent
                      : const Color(0xFF2A2A3A)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _autoDungeon ? '⚡ 자동 던전 진행 중...' : '⚡ 자동 던전',
                      style: TextStyle(
                          color: _autoDungeon
                              ? Colors.greenAccent
                              : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                    const Text('에너지 소진까지 최고 던전 자동 반복',
                        style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
                Switch(
                  value: _autoDungeon,
                  onChanged: (_) => _startAutoDungeon(),
                  activeColor: Colors.greenAccent,
                  inactiveThumbColor: Colors.grey,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 던전 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _dungeons.length,
            itemBuilder: (context, index) {
              final dungeon = _dungeons[index];
              final required = dungeon['requiredPower'] as int;
              final powerOk = power >= required;
              final canEnter =
                  powerOk && gs.canEnterDungeon && !_isClearing;
              final clearTimeMs = _calcClearTimeMs(power, required);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF111118),
                  border: Border.all(
                    color: powerOk
                        ? const Color(0xFF2A4A2A)
                        : const Color(0xFF2A2A3A),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Text(dungeon['emoji'],
                      style: const TextStyle(fontSize: 28)),
                  title: Text(dungeon['name'],
                      style: TextStyle(
                        color: powerOk ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      )),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        powerOk
                            ? '💰 ${_formatNumber(dungeon['goldMin'])}~${_formatNumber(dungeon['goldMax'])}'
                                '  🔮 ${dungeon['stoneMin']}~${dungeon['stoneMax']}개'
                                '${((dungeon['diamondChance'] ?? 0.0) as double) > 0 ? '  💎 ${dungeon['diamondMin']}~${dungeon['diamondMax']} (${(((dungeon['diamondChance'] ?? 0.0) as double) * 100).toInt()}%)' : ''}'
                            : '필요 전투력: ${_formatNumber(required)}',
                        style: TextStyle(
                          color: powerOk ? Colors.green : Colors.red,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        powerOk
                            ? '⏱ 예상 ${(clearTimeMs / 1000).toStringAsFixed(1)}초  ⚡ ${GameState.dungeonEnergyCost} 소모'
                            : '⚡ ${GameState.dungeonEnergyCost} 소모',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: canEnter ? () => _enterDungeon(dungeon) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canEnter
                          ? const Color(0xFF2A4A2A)
                          : const Color(0xFF2A2A3A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      _isClearing
                          ? '...'
                          : !powerOk
                              ? '🔒'
                              : !gs.canEnterDungeon
                                  ? '⚡부족'
                                  : '입장',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}