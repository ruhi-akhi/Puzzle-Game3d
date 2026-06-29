import '../models/game_state.dart';
import '../models/level_data.dart';
import '../models/tile_type.dart';
import 'laser_system.dart';

class GameEngine {
  GameState state;
  final LevelData level;
  GameState? _snapshot;

  GameEngine({required this.level}) : state = _initState(level);

  static GameState _initState(LevelData level) {
    final grid = <List<TileType>>[];
    var px = 0, py = 0;

    for (var y = 0; y < level.height; y++) {
      final row = <TileType>[];
      for (var x = 0; x < level.width; x++) {
        final ch = level.grid[y][x];
        final tile = tileTypeFromChar(ch);
        if (tile == TileType.player) {
          px = x;
          py = y;
          row.add(TileType.floor);
        } else {
          row.add(tile);
        }
      }
      grid.add(row);
    }

    final gs = GameState(
      grid: grid,
      playerX: px,
      playerY: py,
      movesUsed: 0,
      maxMoves: level.maxMoves,
      levelId: level.id,
      levelName: level.name,
      darkMode: level.mechanics.contains('dark_mode'),
    );

    LaserSystem.recalculate(gs);
    return gs;
  }

  void reset() {
    state = _initState(level);
    _snapshot = null;
  }

  void undo() {
    if (_snapshot != null) {
      state = _snapshot!.copy();
      _snapshot = null;
    }
  }

  bool move(Direction dir) {
    if (state.status != GameStatus.playing) return false;

    _snapshot = state.copy();
    var moved = _tryMove(dir);

    if (!moved) {
      _snapshot = null;
      return false;
    }

    state.movesUsed++;
    _afterMove();

    if (state.movesUsed >= state.maxMoves && state.status == GameStatus.playing) {
      state.status = GameStatus.lost;
    }

    return true;
  }

  bool _tryMove(Direction dir) {
    final (dx, dy) = dir.delta;
    final nx = state.playerX + dx;
    final ny = state.playerY + dy;

    final target = state.tileAt(nx, ny);

    // Push box/bomb
    if (target.isPushable) {
      final bx = nx + dx;
      final by = ny + dy;
      if (state.isBlocked(bx, by)) return false;
      state.setTile(bx, by, target);
      state.setTile(nx, ny, TileType.floor);
    } else if (state.isBlocked(nx, ny)) {
      return false;
    }

    // Handle clone mechanic
    if (level.mechanics.contains('clone')) {
      _updateClone(dir);
    }

    state.playerX = nx;
    state.playerY = ny;

    // Ice sliding
    if (state.tileAt(nx, ny) == TileType.ice ||
        level.mechanics.contains('ice')) {
      _slideOnIce(dir);
    }

    return true;
  }

  void _slideOnIce(Direction dir) {
    final (dx, dy) = dir.delta;
    while (true) {
      final nx = state.playerX + dx;
      final ny = state.playerY + dy;
      if (state.isBlocked(nx, ny)) break;
      final tile = state.tileAt(nx, ny);
      if (tile.isPushable) break;
      state.playerX = nx;
      state.playerY = ny;
      _collectTile(nx, ny);
      if (tile != TileType.ice) break;
    }
  }

  void _updateClone(Direction dir) {
    if (state.cloneHistory.isNotEmpty) {
      final clone = state.cloneHistory.last;
      final (dx, dy) = clone.direction.delta;
      final cx = clone.x + dx;
      final cy = clone.y + dy;
      if (!state.isBlocked(cx, cy)) {
        state.cloneHistory = [
          ...state.cloneHistory.sublist(0, state.cloneHistory.length - 1),
          CloneState(x: cx, y: cy, direction: clone.direction),
        ];
      }
    }
    state.cloneHistory = [
      ...state.cloneHistory,
      CloneState(
        x: state.playerX,
        y: state.playerY,
        direction: dir,
      ),
    ];
  }

  void _afterMove() {
    _collectTile(state.playerX, state.playerY);
    _handleTeleporter();
    _handleSwitches();
    _handleGravity();
    LaserSystem.recalculate(state);
    _checkLaserHit();
    _checkWin();
  }

  void _collectTile(int x, int y) {
    final tile = state.tileAt(x, y);
    switch (tile) {
      case TileType.key:
        state.hasKey = true;
        state.setTile(x, y, TileType.floor);
      case TileType.goal:
        break;
      default:
        break;
    }
  }

  void _handleTeleporter() {
    final tile = state.tileAt(state.playerX, state.playerY);
    if (tile == TileType.teleporterA || tile == TileType.teleporterB) {
      final target = tile == TileType.teleporterA
          ? TileType.teleporterB
          : TileType.teleporterA;
      for (var y = 0; y < state.height; y++) {
        for (var x = 0; x < state.width; x++) {
          if (state.tileAt(x, y) == target) {
            state.playerX = x;
            state.playerY = y;
            return;
          }
        }
      }
    }
  }

  void _handleSwitches() {
    final tile = state.tileAt(state.playerX, state.playerY);
    switch (tile) {
      case TileType.redSwitch:
        state.redSwitchOn = !state.redSwitchOn;
      case TileType.blueSwitch:
        state.blueSwitchOn = !state.blueSwitchOn;
      case TileType.timeSwitch:
        state.timeSwitchOn = !state.timeSwitchOn;
      default:
        break;
    }
  }

  void _handleGravity() {
    if (!level.mechanics.contains('gravity')) return;
    final tile = state.tileAt(state.playerX, state.playerY);
    if (tile == TileType.gravityPad) {
      state.gravity = state.gravity == Direction.down
          ? Direction.up
          : Direction.down;
    }
  }

  void _checkLaserHit() {
    for (final (lx, ly) in state.laserBeams) {
      if (lx == state.playerX && ly == state.playerY) {
        state.status = GameStatus.lost;
        return;
      }
    }
  }

  void _checkWin() {
    // Win: reach goal
    if (state.tileAt(state.playerX, state.playerY) == TileType.goal) {
      state.status = GameStatus.won;
      return;
    }

    // Win: all boxes on goals (sokoban style)
    if (level.mechanics.contains('sokoban')) {
      var allOnGoals = true;
      var hasBoxes = false;
      for (var y = 0; y < state.height; y++) {
        for (var x = 0; x < state.width; x++) {
          if (state.tileAt(x, y) == TileType.box) {
            hasBoxes = true;
            allOnGoals = false;
          }
        }
      }
      if (hasBoxes == false || allOnGoals) {
        // Check boxes on goals
        var boxesOnGoals = 0;
        var totalGoals = 0;
        for (var y = 0; y < state.height; y++) {
          for (var x = 0; x < state.width; x++) {
            if (state.tileAt(x, y) == TileType.goal) totalGoals++;
          }
        }
        // Simplified: player at goal with key and door open
      }
    }

    // Win: door reached with key collected and standing on door tile
    if (state.hasKey) {
      final tile = state.tileAt(state.playerX, state.playerY);
      if (tile == TileType.door || tile == TileType.doorOpen) {
        state.setTile(state.playerX, state.playerY, TileType.doorOpen);
      }
    }

    // Check if player is on goal tile
    for (var y = 0; y < state.height; y++) {
      for (var x = 0; x < state.width; x++) {
        if (state.grid[y][x] == TileType.goal &&
            x == state.playerX &&
            y == state.playerY) {
          state.status = GameStatus.won;
          return;
        }
      }
    }
  }

  int calculateStars() {
    if (state.status != GameStatus.won) return 0;
    final ratio = state.movesUsed / state.maxMoves;
    if (ratio <= 0.5) return 3;
    if (ratio <= 0.75) return 2;
    return 1;
  }
}
