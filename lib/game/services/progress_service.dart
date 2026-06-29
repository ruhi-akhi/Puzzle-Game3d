import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static const _prefix = 'echo_labyrinth_';

  static Future<Set<int>> getCompletedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('${_prefix}completed') ?? [];
    return list.map(int.parse).toList().toSet();
  }

  static Future<void> markLevelComplete(int levelId) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = await getCompletedLevels();
    completed.add(levelId);
    await prefs.setStringList(
      '${_prefix}completed',
      completed.map((e) => e.toString()).toList(),
    );
  }

  static Future<bool> isLevelUnlocked(int world, int levelIndex) async {
    if (world == 1 && levelIndex == 1) return true;
    final completed = await getCompletedLevels();
    if (levelIndex > 1) {
      final prevId = world * 100 + levelIndex - 1;
      return completed.contains(prevId);
    }
    // First level of a world — unlock if last level of previous world done
    if (world > 1) {
      final prevWorld = worldsLevelCount(world - 1);
      final prevId = (world - 1) * 100 + prevWorld;
      return completed.contains(prevId);
    }
    return false;
  }

  static int worldsLevelCount(int world) {
    const counts = {1: 5, 2: 3, 3: 2, 4: 2, 5: 2, 6: 2};
    return counts[world] ?? 0;
  }

  static int levelId(int world, int levelIndex) => world * 100 + levelIndex;

  static Future<int> getStars(int levelId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${_prefix}stars_$levelId') ?? 0;
  }

  static Future<void> setStars(int levelId, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getStars(levelId);
    if (stars > current) {
      await prefs.setInt('${_prefix}stars_$levelId', stars);
    }
  }

  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  static Future<int> getTotalStars() async {
    final completed = await getCompletedLevels();
    var total = 0;
    for (final id in completed) {
      total += await getStars(id);
    }
    return total;
  }
}
