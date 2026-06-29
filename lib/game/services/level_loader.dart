import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/level_data.dart';

class LevelLoader {
  static final Map<String, LevelData> _cache = {};

  static Future<LevelData> loadLevel(int world, int levelIndex) async {
    final key = 'world_${world}_$levelIndex';
    if (_cache.containsKey(key)) return _cache[key]!;

    final path = 'assets/levels/world_$world/level_${levelIndex.toString().padLeft(2, '0')}.json';
    try {
      final jsonStr = await rootBundle.loadString(path);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final level = LevelData.fromJson(json);
      _cache[key] = level;
      return level;
    } catch (e) {
      throw Exception('Failed to load level: $path - $e');
    }
  }

  static Future<List<LevelData>> loadWorld(int world) async {
    final worldInfo = worlds.firstWhere((w) => w.id == world);
    final levels = <LevelData>[];
    for (var i = 1; i <= worldInfo.levelCount; i++) {
      levels.add(await loadLevel(world, i));
    }
    return levels;
  }

  static void clearCache() => _cache.clear();
}
