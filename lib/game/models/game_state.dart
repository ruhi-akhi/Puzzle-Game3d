import 'tile_type.dart';

enum GameStatus { playing, won, lost, paused }

class CloneState {
  final int x;
  final int y;
  final Direction direction;

  const CloneState({required this.x, required this.y, required this.direction});

  CloneState copyWith({int? x, int? y, Direction? direction}) {
    return CloneState(
      x: x ?? this.x,
      y: y ?? this.y,
      direction: direction ?? this.direction,
    );
  }
}

class GameState {
  List<List<TileType>> grid;
  int playerX;
  int playerY;
  int movesUsed;
  int maxMoves;
  bool hasKey;
  bool redSwitchOn;
  bool blueSwitchOn;
  bool timeSwitchOn;
  bool darkMode;
  Direction gravity;
  GameStatus status;
  List<CloneState> cloneHistory;
  List<(int, int)> laserBeams;
  Set<String> goalPositions;
  int levelId;
  String levelName;

  GameState({
    required this.grid,
    required this.playerX,
    required this.playerY,
    required this.movesUsed,
    required this.maxMoves,
    this.hasKey = false,
    this.redSwitchOn = false,
    this.blueSwitchOn = false,
    this.timeSwitchOn = false,
    this.darkMode = false,
    this.gravity = Direction.down,
    this.status = GameStatus.playing,
    this.cloneHistory = const [],
    this.laserBeams = const [],
    this.goalPositions = const {},
    this.levelId = 0,
    this.levelName = '',
  });

  int get width => grid.isEmpty ? 0 : grid.first.length;
  int get height => grid.length;

  bool isGoalAt(int x, int y) => goalPositions.contains('$x,$y');

  TileType tileAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) {
      return TileType.wall;
    }
    return grid[y][x];
  }

  void setTile(int x, int y, TileType type) {
    if (x >= 0 && y >= 0 && x < width && y < height) {
      grid[y][x] = type;
    }
  }

  bool isBlocked(int x, int y) {
    final tile = tileAt(x, y);
    if (tile == TileType.door && hasKey) return false;
    if (tile == TileType.doorOpen) return false;
    if (tile == TileType.redDoor && redSwitchOn) return false;
    if (tile == TileType.blueDoor && blueSwitchOn) return false;
    if (tile == TileType.laserBeam) return true;
    return tile.isSolid;
  }

  GameState copy() {
    return GameState(
      grid: grid.map((row) => List<TileType>.from(row)).toList(),
      playerX: playerX,
      playerY: playerY,
      movesUsed: movesUsed,
      maxMoves: maxMoves,
      hasKey: hasKey,
      redSwitchOn: redSwitchOn,
      blueSwitchOn: blueSwitchOn,
      timeSwitchOn: timeSwitchOn,
      darkMode: darkMode,
      gravity: gravity,
      status: status,
      cloneHistory: List<CloneState>.from(cloneHistory),
      laserBeams: List<(int, int)>.from(laserBeams),
      goalPositions: Set<String>.from(goalPositions),
      levelId: levelId,
      levelName: levelName,
    );
  }
}
