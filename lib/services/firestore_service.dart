// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_state.dart';
import '../models/save_manager.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 유저 문서 경로: users/{uid}
  DocumentReference _userDoc(String uid) => _db.collection('users').doc(uid);

  // 처음 로그인 시 유저 초기화
  Future<void> initUserData(User user) async {
    final doc = await _userDoc(user.uid).get();
    if (!doc.exists) {
      // 새 유저 — 기본 프로필만 생성 (게임 데이터는 별도 저장)
      await _userDoc(user.uid).set({
        'uid': user.uid,
        'nickname': user.displayName ?? '용사',
        'email': user.email,
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      await _userDoc(user.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  // 게임 데이터 Firestore에 저장
  Future<void> saveGameData(String uid, Map<String, dynamic> gameData) async {
    try {
      await _userDoc(uid).set(
        {'gameData': gameData},
        SetOptions(merge: true), // 기존 필드 유지하면서 업데이트
      );
    } catch (e) {
      print('Firestore 저장 오류: $e');
    }
  }

  // Firestore에서 게임 데이터 불러오기
  Future<Map<String, dynamic>?> loadGameData(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['gameData'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Firestore 불러오기 오류: $e');
    }
    return null;
  }

  // 닉네임 변경
  Future<void> updateNickname(String uid, String nickname) async {
    await _userDoc(uid).update({'nickname': nickname});
  }
}