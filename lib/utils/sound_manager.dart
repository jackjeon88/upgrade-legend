// lib/utils/sound_manager.dart

import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();

  // 강화 성공 효과음
  static Future<void> playSuccess() async {
    await _player.play(AssetSource('sounds/enhance_success.mp3'));
  }

  // 강화 실패 효과음
  static Future<void> playFail() async {
    await _player.play(AssetSource('sounds/enhance_fail.mp3'));
  }

  // 뽑기 효과음
  static Future<void> playGacha() async {
    await _player.play(AssetSource('sounds/gacha.mp3'));
  }
}
