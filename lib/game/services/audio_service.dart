import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioService {
  static final AudioPlayer _bgm = AudioPlayer();
  static final AudioPlayer _sfx = AudioPlayer();
  static bool _initialized = false;
  static bool musicEnabled = true;
  static bool sfxEnabled = true;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await _bgm.setReleaseMode(ReleaseMode.loop);
      await _bgm.setVolume(0.4);
      await _sfx.setVolume(0.5);
      _initialized = true;
    } catch (e) {
      debugPrint('Audio init failed: $e');
    }
  }

  /// Web browsers block audio until user taps — call this on PLAY / first move.
  static Future<void> playBgm() async {
    if (!_initialized || !musicEnabled) return;
    try {
      await _bgm.stop();
      await _bgm.play(AssetSource('audio/bgm_loop.wav'));
    } catch (e) {
      debugPrint('BGM play failed: $e');
    }
  }

  static Future<void> stopBgm() async {
    try {
      await _bgm.stop();
    } catch (_) {}
  }

  static Future<void> playMove() async {
    if (!_initialized || !sfxEnabled) return;
    try {
      await _sfx.stop();
      await _sfx.play(AssetSource('audio/move.wav'));
    } catch (_) {}
  }

  static Future<void> playWin() async {
    if (!_initialized || !sfxEnabled) return;
    try {
      await _sfx.stop();
      await _sfx.play(AssetSource('audio/win.wav'));
    } catch (_) {}
  }

  static Future<void> playBlock() async {
    if (!_initialized || !sfxEnabled) return;
    try {
      await _sfx.stop();
      await _sfx.play(AssetSource('audio/move.wav'));
      await _sfx.setVolume(0.25);
      await Future.delayed(const Duration(milliseconds: 80));
      await _sfx.setVolume(0.5);
    } catch (_) {}
  }

  static Future<void> playCollect() async {
    if (!_initialized || !sfxEnabled) return;
    try {
      await _sfx.stop();
      await _sfx.play(AssetSource('audio/win.wav'));
      await _sfx.setVolume(0.3);
      await Future.delayed(const Duration(milliseconds: 120));
      await _sfx.setVolume(0.5);
    } catch (_) {}
  }

  static void hapticMove() {
    HapticFeedback.lightImpact();
  }

  static void hapticBlock() {
    HapticFeedback.mediumImpact();
  }

  static void hapticWin() {
    HapticFeedback.heavyImpact();
  }

  static Future<void> toggleMusic() async {
    musicEnabled = !musicEnabled;
    if (musicEnabled) {
      await playBgm();
    } else {
      await stopBgm();
    }
  }
}
