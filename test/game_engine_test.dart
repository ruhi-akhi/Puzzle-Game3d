import 'package:flutter_test/flutter_test.dart';
import 'package:echo_labyrinth/game/services/progress_service.dart';
import 'package:echo_labyrinth/game/models/level_data.dart';
import 'package:echo_labyrinth/game/models/tile_type.dart';
import 'package:echo_labyrinth/game/models/game_state.dart';
import 'package:echo_labyrinth/game/systems/game_engine.dart';

void main() {
  group('TileType', () {
    test('fromChar parses all basic tiles', () {
      expect(tileTypeFromChar('#'), TileType.wall);
      expect(tileTypeFromChar('@'), TileType.player);
      expect(tileTypeFromChar('K'), TileType.key);
      expect(tileTypeFromChar('G'), TileType.goal);
      expect(tileTypeFromChar('B'), TileType.box);
      expect(tileTypeFromChar('D'), TileType.door);
    });

    test('isSolid returns correct values', () {
      expect(TileType.wall.isSolid, true);
      expect(TileType.floor.isWalkable, true);
      expect(TileType.box.isPushable, true);
    });
  });

  group('GameEngine', () {
    late LevelData testLevel;

    setUp(() {
      testLevel = const LevelData(
        id: 999,
        name: 'Test Level',
        world: 1,
        maxMoves: 10,
        grid: [
          '######',
          '#@...#',
          '#...G#',
          '######',
        ],
      );
    });

    test('initializes player position correctly', () {
      final engine = GameEngine(level: testLevel);
      expect(engine.state.playerX, 1);
      expect(engine.state.playerY, 1);
      expect(engine.state.movesUsed, 0);
      expect(engine.state.status, GameStatus.playing);
    });

    test('player can move to goal and win', () {
      final engine = GameEngine(level: testLevel);
      engine.move(Direction.right);
      engine.move(Direction.right);
      engine.move(Direction.right);
      engine.move(Direction.down);
      expect(engine.state.status, GameStatus.won);
    });

    test('cannot move through walls', () {
      final engine = GameEngine(level: testLevel);
      final result = engine.move(Direction.up);
      expect(result, false);
      expect(engine.state.playerX, 1);
      expect(engine.state.playerY, 1);
    });

    test('move count increases on valid move', () {
      final engine = GameEngine(level: testLevel);
      engine.move(Direction.right);
      expect(engine.state.movesUsed, 1);
    });

    test('reset restores initial state', () {
      final engine = GameEngine(level: testLevel);
      engine.move(Direction.right);
      engine.reset();
      expect(engine.state.movesUsed, 0);
      expect(engine.state.playerX, 1);
    });

    test('key collection works', () {
      const keyLevel = LevelData(
        id: 998,
        name: 'Key Test',
        world: 1,
        maxMoves: 10,
        grid: [
          '######',
          '#@.K.#',
          '#...G#',
          '######',
        ],
      );
      final engine = GameEngine(level: keyLevel);
      engine.move(Direction.right);
      engine.move(Direction.right);
      expect(engine.state.hasKey, true);
    });

    test('box pushing works', () {
      const boxLevel = LevelData(
        id: 997,
        name: 'Box Test',
        world: 1,
        maxMoves: 15,
        mechanics: ['sokoban'],
        grid: [
          '#######',
          '#@.B..#',
          '#.....#',
          '#....G#',
          '#######',
        ],
      );
      final engine = GameEngine(level: boxLevel);
      engine.move(Direction.right);
      engine.move(Direction.right);
      expect(engine.state.tileAt(4, 1), TileType.box);
      expect(engine.state.playerX, 3);
    });

    test('sokoban win when box on goal', () {
      const boxLevel = LevelData(
        id: 996,
        name: 'Sokoban Win',
        world: 1,
        maxMoves: 10,
        mechanics: ['sokoban'],
        grid: [
          '######',
          '#@BG.#',
          '#.....#',
          '######',
        ],
      );
      final engine = GameEngine(level: boxLevel);
      engine.move(Direction.right);
      expect(engine.state.status, GameStatus.won);
    });

    test('stars calculation', () {
      final engine = GameEngine(level: testLevel);
      engine.move(Direction.right);
      engine.move(Direction.right);
      engine.move(Direction.right);
      engine.move(Direction.down);
      expect(engine.calculateStars(), greaterThan(0));
    });
    test('apocalypse gate is solvable', () {
      const level = LevelData(
        id: 605,
        name: 'Apocalypse Gate',
        world: 6,
        maxMoves: 24,
        mechanics: ['laser', 'switch', 'key_door', 'teleporter'],
        grid: [
          '##########',
          '#@..T....#',
          '#.##.....#',
          '#...L....#',
          '#......t.#',
          '#..R.r...#',
          '#...K....#',
          '#....D.G.#',
          '##########',
        ],
      );
      expect(_canWinLevel(level), isTrue);
    });
  });

  group('LevelData', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 101,
        'name': 'Test',
        'world': 1,
        'maxMoves': 20,
        'grid': ['###', '#@#', '###'],
      };
      final level = LevelData.fromJson(json);
      expect(level.id, 101);
      expect(level.width, 3);
      expect(level.height, 3);
    });
  });

  group('ProgressService', () {
    test('level ids match json format', () {
      expect(ProgressService.levelId(1, 5), 105);
      expect(ProgressService.levelId(2, 1), 201);
    });

    test('normalize legacy level ids', () {
      expect(ProgressService.levelId(1, 5), 105);
    });
  });
}

bool _canWinLevel(LevelData level) {
  final engine = GameEngine(level: level);
  return _bfs(engine, <String>{});
}

bool _bfs(GameEngine engine, Set<String> visited) {
  if (engine.state.status == GameStatus.won) return true;
  if (engine.state.status == GameStatus.lost) return false;

  final key =
      '${engine.state.playerX},${engine.state.playerY},${engine.state.movesUsed},${engine.state.status}';
  if (visited.contains(key)) return false;
  visited.add(key);

  for (final dir in Direction.values) {
    final copy = GameEngine(level: engine.level);
    copy.state = engine.state.copy();
    if (copy.move(dir) && copy.state.status != GameStatus.lost) {
      if (_bfs(copy, visited)) return true;
    }
  }
  return false;
}
