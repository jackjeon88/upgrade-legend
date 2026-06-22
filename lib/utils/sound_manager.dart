// lib/utils/sound_manager.dart

import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();

  // 공통: 재생 전 초기화 후 재생
  static Future<void> _play(String path) async {
    await _player.stop(); // 이전 재생 중단
    await _player.play(AssetSource(path));
  }

  // 강화 성공 효과음
  static Future<void> playSuccess() async {
    await _play('sounds/enhance_success.mp3');
  }

  // 강화 실패 효과음
  static Future<void> playFail() async {
    await _play('sounds/enhance_fail.mp3');
  }

  // 뽑기 효과음
  static Future<void> playGacha() async {
    await _play('sounds/gacha.mp3');
  }
}