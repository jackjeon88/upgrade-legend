// lib/models/save_manager.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'equipment.dart';
import 'game_state.dart';
import 'attendance.dart';
import '../services/firestore_service.dart';

class SaveManager {
  static const String _key = 'game_save';

  // 게임 상태 저장 (로컬 + Firestore 동시 저장)
  static Future<void> save(GameState state) async {
    final data = _encodeState(state);

    // 1) 로컬 저장 (오프라인 대비)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));

    // 2) Firestore 저장 (로그인된 경우에만)
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirestoreService().saveGameData(uid, data);
    }
  }

  // 게임 상태 불러오기 (Firestore 우선, 없으면 로컬)
  static Future<GameState?> load() async {
    try {
      // 1) 로그인된 경우 Firestore에서 먼저 불러오기
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final cloudData = await FirestoreService().loadGameData(uid);
        if (cloudData != null) {
          // Firestore 데이터를 로컬에도 동기화
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_key, jsonEncode(cloudData));
          return _decodeState(cloudData);
        }
      }

      // 2) Firestore에 없으면 로컬 저장 데이터 사용
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return _decodeState(data);
    } catch (e) {
      print('불러오기 오류: $e');
      return null;
    }
  }

  // 저장 데이터 삭제
  static Future<void> delete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // GameState → Map
  static Map<String, dynamic> _encodeState(GameState s) {
    return {
      'gold': s.gold,
      'diamond': s.diamond,
      'enhanceStone': s.enhanceStone,
      'protectScroll': s.protectScroll,
      'energy': s.energy,
      'lastEnergyUpdate': s.lastEnergyUpdate.toIso8601String(),
      'totalEnhanceCount': s.totalEnhanceCount,
      'successCount': s.successCount,
      'failCount': s.failCount,
      'destroyCount': s.destroyCount,
      'totalGoldSpent': s.totalGoldSpent,
      'equipped': s.equipped.map(_encodeEquip).toList(),
      'inventory': s.inventory.map(_encodeEquip).toList(),
      'attendance': s.attendance.toJson(),
      'premiumChargeCount': s.premiumChargeCount,
    };
  }

  // Map → GameState
  static GameState _decodeState(Map<String, dynamic> data) {
    return GameState(
      gold: data['gold'] ?? 5000,
      diamond: data['diamond'] ?? 0,
      enhanceStone: data['enhanceStone'] ?? 10,
      protectScroll: data['protectScroll'] ?? 0,
      energy: data['energy'] ?? 200,
      lastEnergyUpdate: data['lastEnergyUpdate'] != null
          ? DateTime.parse(data['lastEnergyUpdate'])
          : DateTime.now(),
      totalEnhanceCount: data['totalEnhanceCount'] ?? 0,
      successCount: data['successCount'] ?? 0,
      failCount: data['failCount'] ?? 0,
      destroyCount: data['destroyCount'] ?? 0,
      totalGoldSpent: data['totalGoldSpent'] ?? 0,
      equipped: (data['equipped'] as List?)
              ?.map((e) => _decodeEquip(e as Map<String, dynamic>))
              .toList() ??
          [],
      inventory: (data['inventory'] as List?)
              ?.map((e) => _decodeEquip(e as Map<String, dynamic>))
              .toList() ??
          [],
      attendance: data['attendance'] != null
          ? AttendanceState.fromJson(data['attendance'])
          : const AttendanceState(),
      premiumChargeCount: data['premiumChargeCount'] ?? 0,
    );
  }

  // Equipment → Map
  static Map<String, dynamic> _encodeEquip(Equipment e) {
    return {
      'id': e.id,
      'name': e.name,
      'grade': e.grade.index,
      'slot': e.slot.index,
      'weaponType': e.weaponType?.index,
      'enhanceLevel': e.enhanceLevel,
      'basePower': e.basePower,
    };
  }

  // Map → Equipment
  static Equipment _decodeEquip(Map<String, dynamic> data) {
    return Equipment(
      id: data['id'] ?? 'unknown',
      name: data['name'] ?? '알 수 없는 아이템',
      grade: ItemGrade.values[data['grade'] ?? 0],
      slot: ItemSlot.values[data['slot'] ?? 0],
      weaponType: data['weaponType'] != null
          ? WeaponType.values[data['weaponType']]
          : null,
      enhanceLevel: data['enhanceLevel'] ?? 0,
      basePower: data['basePower'] ?? 10,
    );
  }
}