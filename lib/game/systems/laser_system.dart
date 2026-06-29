import '../models/game_state.dart';
import '../models/tile_type.dart';

class LaserSystem {
  static void recalculate(GameState state) {
    // Clear old laser beams
    for (var y = 0; y < state.height; y++) {
      for (var x = 0; x < state.width; x++) {
        if (state.grid[y][x] == TileType.laserBeam) {
          state.grid[y][x] = TileType.floor;
        }
      }
    }

    final beams = <(int, int)>[];

    for (var y = 0; y < state.height; y++) {
      for (var x = 0; x < state.width; x++) {
        if (state.grid[y][x] == TileType.laserEmitter) {
          _castLaser(state, x, y, Direction.right, beams);
        }
      }
    }

    state.laserBeams = beams;
  }

  static void _castLaser(
    GameState state,
    int startX,
    int startY,
    Direction dir,
    List<(int, int)> beams, [
    int depth = 0,
  ]) {
    if (depth > 50) return; // prevent infinite loops

    final (dx, dy) = dir.delta;
    var x = startX + dx;
    var y = startY + dy;

    while (x >= 0 && y >= 0 && x < state.width && y < state.height) {
      final tile = state.tileAt(x, y);

      if (tile == TileType.wall) break;

      if (tile == TileType.mirror || tile == TileType.mirrorSlash) {
        beams.add((x, y));
        final newDir = _reflect(dir, true);
        _castLaser(state, x, y, newDir, beams, depth + 1);
        break;
      }

      if (tile == TileType.mirrorBackslash) {
        beams.add((x, y));
        final newDir = _reflect(dir, false);
        _castLaser(state, x, y, newDir, beams, depth + 1);
        break;
      }

      if (tile.isSolid && tile != TileType.mirror &&
          tile != TileType.mirrorSlash &&
          tile != TileType.mirrorBackslash) {
        break;
      }

      beams.add((x, y));
      if (state.grid[y][x] == TileType.floor ||
          state.grid[y][x] == TileType.empty) {
        state.grid[y][x] = TileType.laserBeam;
      }

      x += dx;
      y += dy;
    }
  }

  static Direction _reflect(Direction incoming, bool slash) {
    // / mirror: right->up, up->right, left->down, down->left
    // \ mirror: right->down, down->right, left->up, up->left
    if (slash) {
      switch (incoming) {
        case Direction.right:
          return Direction.up;
        case Direction.up:
          return Direction.right;
        case Direction.left:
          return Direction.down;
        case Direction.down:
          return Direction.left;
      }
    } else {
      switch (incoming) {
        case Direction.right:
          return Direction.down;
        case Direction.down:
          return Direction.right;
        case Direction.left:
          return Direction.up;
        case Direction.up:
          return Direction.left;
      }
    }
  }
}
