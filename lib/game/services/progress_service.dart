import 'package:shared_preferences/shared_preferences.dart';
import '../models/level_data.dart';

class ProgressService {
  static const _prefix = 'echo_labyrinth_';
  static Set<int>? _completedCache;

  /// Fix old saves where stars were saved but completed list was empty.
  static Future<void> syncFromStars() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = await getCompletedLevels();
    var changed = false;

    for (final key in prefs.getKeys()) {
      if (!key.startsWith('${_prefix}stars_')) continue;
      final id = int.tryParse(key.replaceFirst('${_prefix}stars_', ''));
      if (id == null) continue;
      final stars = prefs.getInt(key) ?? 0;
      if (stars > 0 && !completed.contains(id)) {
        completed.add(id);
        changed = true;
      }
    }

    if (changed) {
      _completedCache = Set<int>.from(completed);
      await prefs.setStringList(
        '${_prefix}completed',
        completed.map((e) => e.toString()).toList(),
      );
      await prefs.reload();
    }
  }

  static Future<Set<int>> getCompletedLevels() async {
    if (_completedCache != null) return Set<int>.from(_completedCache!);

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('${_prefix}completed') ?? [];
    _completedCache = list.map(int.parse).toSet();
    return Set<int>.from(_completedCache!);
  }

  static Future<bool> isLevelCompleted(int levelId) async {
    final completed = await getCompletedLevels();
    if (completed.contains(levelId)) return true;
    final stars = await getStars(levelId);
    return stars > 0;
  }

  static Future<void> markLevelComplete(int levelId) async {
    final completed = await getCompletedLevels();
    completed.add(levelId);
    _completedCache = Set<int>.from(completed);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '${_prefix}completed',
      completed.map((e) => e.toString()).toList(),
    );
    await prefs.reload();
  }

  static Future<bool> isWorldUnlocked(int world) async {
    if (world <= 1) return true;

    final prevWorld = world - 1;
    final lastLevelOfPrevWorld = levelId(prevWorld, worldsLevelCount(prevWorld));
    return isLevelCompleted(lastLevelOfPrevWorld);
  }

  static Future<bool> isLevelUnlocked(int world, int levelIndex) async {
    final currentId = levelId(world, levelIndex);

    // Always allow replay of finished levels
    if (await isLevelCompleted(currentId)) return true;

    if (world == 1 && levelIndex == 1) return true;

    if (levelIndex == 1) {
      return isWorldUnlocked(world);
    }

    final previousLevelId = levelId(world, levelIndex - 1);
    return isLevelCompleted(previousLevelId);
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
    return prefs.getInt('${_prefix}stars_$levelId') ?? 0;
  }

  static Future<void> setStars(int levelId, int stars) async {
    if (stars <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final current = await getStars(levelId);
    if (stars > current) {
      await prefs.setInt('${_prefix}stars_$levelId', stars);
      await prefs.reload();
    }
    await markLevelComplete(levelId);
  }

  static Future<void> resetProgress() async {
    _completedCache = {};
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
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
