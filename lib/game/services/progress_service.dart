import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/level_data.dart';

class ProgressService {
  static const _prefix = 'echo_labyrinth_';
  static Set<int>? _completedCache;
  static Set<int>? _unlockedWorldsCache;

  /// Rebuild progress from stars + fix legacy save formats.
  static Future<void> syncFromStars() async {
    _completedCache = null;
    _unlockedWorldsCache = null;

    final prefs = await SharedPreferences.getInstance();
    final completed = await _loadCompletedFromPrefs(prefs);
    var changed = false;

    // Legacy: stars saved as 1..5 instead of 101..105
    for (var w = 1; w <= worlds.length; w++) {
      final count = worldsLevelCount(w);
      for (var l = 1; l <= count; l++) {
        final properId = levelId(w, l);
        final legacyId = l;
        final legacyStars = prefs.getInt('${_prefix}stars_$legacyId') ?? 0;
        final properStars = prefs.getInt('${_prefix}stars_$properId') ?? 0;
        if (legacyStars > 0 && properStars == 0) {
          await prefs.setInt('${_prefix}stars_$properId', legacyStars);
          changed = true;
        }
        if (legacyStars > 0) {
          if (!completed.contains(properId)) {
            completed.add(properId);
            changed = true;
          }
        }
      }
    }

    for (final key in prefs.getKeys()) {
      if (!key.startsWith('${_prefix}stars_')) continue;
      final id = int.tryParse(key.replaceFirst('${_prefix}stars_', ''));
      if (id == null) continue;
      final stars = prefs.getInt(key) ?? 0;
      if (stars > 0) {
        final normalizedId = _normalizeLevelId(id);
        if (!completed.contains(normalizedId)) {
          completed.add(normalizedId);
          changed = true;
        }
      }
    }

    final unlocked = await _loadUnlockedWorldsFromPrefs(prefs);
    for (var w = 1; w < worlds.length; w++) {
      if (await _isWorldFullyComplete(w, completed, prefs)) {
        if (!unlocked.contains(w + 1)) {
          unlocked.add(w + 1);
          changed = true;
        }
      }
    }

    if (changed) {
      _completedCache = Set<int>.from(completed);
      _unlockedWorldsCache = Set<int>.from(unlocked);
      await prefs.setStringList(
        '${_prefix}completed',
        completed.map((e) => e.toString()).toList(),
      );
      await prefs.setStringList(
        '${_prefix}unlocked_worlds',
        unlocked.map((e) => e.toString()).toList(),
      );
      await prefs.reload();
    }
  }

  static int _normalizeLevelId(int id) {
    if (id >= 100) return id;
    // Legacy bare index 1-5 → world 1
    if (id >= 1 && id <= worldsLevelCount(1)) {
      return levelId(1, id);
    }
    return id;
  }

  static Future<Set<int>> _loadCompletedFromPrefs(SharedPreferences prefs) async {
    final list = prefs.getStringList('${_prefix}completed') ?? [];
    return list.map((e) => int.parse(e)).toSet();
  }

  static Future<Set<int>> _loadUnlockedWorldsFromPrefs(
    SharedPreferences prefs,
  ) async {
    final list = prefs.getStringList('${_prefix}unlocked_worlds') ?? ['1'];
    return list.map((e) => int.parse(e)).toSet();
  }

  static Future<bool> _isWorldFullyComplete(
    int world,
    Set<int> completed,
    SharedPreferences prefs,
  ) async {
    final total = worldsLevelCount(world);
    if (total == 0) return false;
    for (var i = 1; i <= total; i++) {
      final id = levelId(world, i);
      if (!completed.contains(id)) {
        final stars = prefs.getInt('${_prefix}stars_$id') ?? 0;
        if (stars <= 0) return false;
      }
    }
    return true;
  }

  static Future<void> _ensureWorldUnlockChain() async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = await getUnlockedWorlds();
    var changed = false;

    for (var w = 1; w < worlds.length; w++) {
      if (await isWorldFullyComplete(w)) {
        if (!unlocked.contains(w + 1)) {
          unlocked.add(w + 1);
          changed = true;
        }
      }
    }

    if (changed) {
      _unlockedWorldsCache = unlocked;
      await prefs.setStringList(
        '${_prefix}unlocked_worlds',
        unlocked.map((e) => e.toString()).toList(),
      );
      await prefs.reload();
    }
  }

  static Future<Set<int>> getCompletedLevels() async {
    if (_completedCache != null) return Set<int>.from(_completedCache!);

    final prefs = await SharedPreferences.getInstance();
    _completedCache = await _loadCompletedFromPrefs(prefs);
    return Set<int>.from(_completedCache!);
  }

  static Future<Set<int>> getUnlockedWorlds() async {
    if (_unlockedWorldsCache != null) {
      return Set<int>.from(_unlockedWorldsCache!);
    }
    final prefs = await SharedPreferences.getInstance();
    _unlockedWorldsCache = await _loadUnlockedWorldsFromPrefs(prefs);
    return Set<int>.from(_unlockedWorldsCache!);
  }

  static Future<bool> isLevelCompleted(int levelId) async {
    final normalized = _normalizeLevelId(levelId);
    final completed = await getCompletedLevels();
    if (completed.contains(normalized)) return true;
    final stars = await getStars(normalized);
    return stars > 0;
  }

  static Future<bool> isWorldFullyComplete(int world) async {
    final total = worldsLevelCount(world);
    if (total == 0) return false;
    final count = await getWorldCompletedCount(world);
    return count >= total;
  }

  static Future<void> markLevelComplete(int levelId) async {
    final normalized = _normalizeLevelId(levelId);
    final completed = await getCompletedLevels();
    completed.add(normalized);
    _completedCache = Set<int>.from(completed);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '${_prefix}completed',
      completed.map((e) => e.toString()).toList(),
    );
    await prefs.reload();
    await _ensureWorldUnlockChain();
  }

  /// World unlock: explicit flag OR previous world 100% complete (same as X/X UI).
  static Future<bool> isWorldUnlocked(int world) async {
    if (world <= 1) return true;

    final unlocked = await getUnlockedWorlds();
    if (unlocked.contains(world)) return true;

    final prevWorld = world - 1;
    final done = await getWorldCompletedCount(prevWorld);
    final needed = worldsLevelCount(prevWorld);
    final result = needed > 0 && done >= needed;

    if (kDebugMode) {
      debugPrint(
        'World $world unlock: prev=$prevWorld done=$done/$needed => $result',
      );
    }

    if (result) {
      unlocked.add(world);
      _unlockedWorldsCache = unlocked;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        '${_prefix}unlocked_worlds',
        unlocked.map((e) => e.toString()).toList(),
      );
    }

    return result;
  }

  static Future<bool> isLevelUnlocked(int world, int levelIndex) async {
    final currentId = levelId(world, levelIndex);

    if (await isLevelCompleted(currentId)) return true;
    if (world == 1 && levelIndex == 1) return true;

    if (levelIndex == 1) {
      return isWorldUnlocked(world);
    }

    return isLevelCompleted(levelId(world, levelIndex - 1));
  }

  static int worldsLevelCount(int world) {
    for (final w in worlds) {
      if (w.id == world) return w.levelCount;
    }
    return 0;
  }

  static int levelId(int world, int levelIndex) => world * 100 + levelIndex;

  static Future<int> getStars(int levelId) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizeLevelId(levelId);
    return prefs.getInt('${_prefix}stars_$normalized') ?? 0;
  }

  static Future<void> setStars(int levelId, int stars) async {
    if (stars <= 0) return;

    final normalized = _normalizeLevelId(levelId);
    final prefs = await SharedPreferences.getInstance();
    final current = await getStars(normalized);
    if (stars > current) {
      await prefs.setInt('${_prefix}stars_$normalized', stars);
      await prefs.reload();
    }
    await markLevelComplete(normalized);
  }

  static Future<void> resetProgress() async {
    _completedCache = {};
    _unlockedWorldsCache = {1};
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
    await prefs.setStringList('${_prefix}unlocked_worlds', ['1']);
    await prefs.reload();
  }

  static Future<int> getTotalStars() async {
    final prefs = await SharedPreferences.getInstance();
    var total = 0;
    for (final key in prefs.getKeys()) {
      if (key.startsWith('${_prefix}stars_')) {
        total += prefs.getInt(key) ?? 0;
      }
    }
    return total;
  }

  static Future<int> getWorldCompletedCount(int world) async {
    var count = 0;
    final total = worldsLevelCount(world);
    for (var i = 1; i <= total; i++) {
      if (await isLevelCompleted(levelId(world, i))) count++;
    }
    return count;
  }
}
