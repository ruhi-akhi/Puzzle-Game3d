import 'tile_type.dart';

class LevelData {
  final int id;
  final String name;
  final int world;
  final int maxMoves;
  final List<String> grid;
  final List<String> mechanics;
  final String? hint;

  const LevelData({
    required this.id,
    required this.name,
    required this.world,
    required this.maxMoves,
    required this.grid,
    this.mechanics = const [],
    this.hint,
  });

  int get width => grid.isEmpty ? 0 : grid.first.length;
  int get height => grid.length;

  factory LevelData.fromJson(Map<String, dynamic> json) {
    return LevelData(
      id: json['id'] as int,
      name: json['name'] as String,
      world: json['world'] as int,
      maxMoves: json['maxMoves'] as int,
      grid: List<String>.from(json['grid'] as List),
      mechanics: json['mechanics'] != null
          ? List<String>.from(json['mechanics'] as List)
          : [],
      hint: json['hint'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'world': world,
        'maxMoves': maxMoves,
        'grid': grid,
        'mechanics': mechanics,
        if (hint != null) 'hint': hint,
      };
}

class WorldInfo {
  final int id;
  final String name;
  final String description;
  final String mechanic;
  final int levelCount;

  const WorldInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.mechanic,
    required this.levelCount,
  });
}

const List<WorldInfo> worlds = [
  WorldInfo(
    id: 1,
    name: 'Tutorial',
    description: 'Learn the basics of the labyrinth',
    mechanic: 'Movement, Keys & Doors',
    levelCount: 5,
  ),
  WorldInfo(
    id: 2,
    name: 'Laser Lab',
    description: 'Reflect lasers with mirrors',
    mechanic: 'Laser & Mirror',
    levelCount: 3,
  ),
  WorldInfo(
    id: 3,
    name: 'Frozen Depths',
    description: 'Slide on ice — you cannot stop!',
    mechanic: 'Ice Tiles',
    levelCount: 5,
  ),
  WorldInfo(
    id: 4,
    name: 'Echo Chamber',
    description: 'Your shadow copies your moves',
    mechanic: 'Shadow Clone',
    levelCount: 5,
  ),
  WorldInfo(
    id: 5,
    name: 'Gravity Well',
    description: 'Flip gravity to reach new paths',
    mechanic: 'Gravity Flip',
    levelCount: 5,
  ),
  WorldInfo(
    id: 6,
    name: 'Final Mix',
    description: 'All mechanics combined',
    mechanic: 'Mixed Puzzles',
    levelCount: 5,
  ),
];
