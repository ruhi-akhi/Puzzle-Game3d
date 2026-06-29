import 'package:flutter/material.dart';
import '../../game/models/game_state.dart';
import '../../game/models/level_data.dart' show LevelData, worlds;
import '../../game/services/level_loader.dart';
import '../../game/services/progress_service.dart';
import '../../game/systems/game_engine.dart';
import '../../theme/game_colors.dart';
import '../widgets/game_board.dart';
import '../widgets/neon_button.dart';

class GameScreen extends StatefulWidget {
  final LevelData level;
  final int world;
  final int levelIndex;

  const GameScreen({
    super.key,
    required this.level,
    required this.world,
    required this.levelIndex,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameEngine _engine;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine(level: widget.level);
  }

  void _onStateChanged() {
    final status = _engine.state.status;
    if (status != GameStatus.playing && !_dialogShown) {
      _dialogShown = true;
      _showResultDialog(status);
    }
    setState(() {});
  }

  Future<void> _showResultDialog(GameStatus status) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (status == GameStatus.won) {
      final stars = _engine.calculateStars();
      final levelId = ProgressService.levelId(widget.world, widget.levelIndex);
      await ProgressService.markLevelComplete(levelId);
      await ProgressService.setStars(levelId, stars);

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A2332),
          title: const Text(
            '🎉 LEVEL COMPLETE!',
            style: TextStyle(color: GameColors.doorOpen),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '⭐' * stars + '☆' * (3 - stars),
                style: const TextStyle(fontSize: 32),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Moves: ${_engine.state.movesUsed} / ${_engine.state.maxMoves}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _restart();
              },
              child: const Text('RETRY', style: TextStyle(color: GameColors.hudText)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _goToNextLevel();
              },
              child: const Text('NEXT', style: TextStyle(color: GameColors.neonCyan)),
            ),
          ],
        ),
      );
    } else if (status == GameStatus.lost) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A2332),
          title: const Text(
            '💀 OUT OF MOVES',
            style: TextStyle(color: GameColors.laser),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'You ran out of moves. Try again!',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('QUIT', style: TextStyle(color: GameColors.hudText)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _restart();
              },
              child: const Text('RETRY', style: TextStyle(color: GameColors.neonCyan)),
            ),
          ],
        ),
      );
    }
  }

  void _restart() {
    setState(() {
      _engine.reset();
      _dialogShown = false;
    });
  }

  Future<void> _goToNextLevel() async {
    final worldInfo = worlds.firstWhere((w) => w.id == widget.world);
    if (widget.levelIndex < worldInfo.levelCount) {
      final nextLevel = await LevelLoader.loadLevel(
        widget.world,
        widget.levelIndex + 1,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            level: nextLevel,
            world: widget.world,
            levelIndex: widget.levelIndex + 1,
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GameColors.neonCyan),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'WORLD ${widget.world} - ${widget.levelIndex}',
          style: const TextStyle(
            color: GameColors.neonCyan,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: GameColors.neonPink),
            onPressed: _restart,
            tooltip: 'Restart',
          ),
          IconButton(
            icon: const Icon(Icons.undo, color: GameColors.neonPurple),
            onPressed: () {
              _engine.undo();
              setState(() {});
            },
            tooltip: 'Undo',
          ),
        ],
      ),
      body: GameBoard(
        engine: _engine,
        onStateChanged: _onStateChanged,
      ),
    );
  }
}
