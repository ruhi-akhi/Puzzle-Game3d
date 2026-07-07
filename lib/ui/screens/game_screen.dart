import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../game/models/game_state.dart';
import '../../game/models/level_data.dart' show LevelData, worlds;
import '../../game/services/level_loader.dart';
import '../../game/services/audio_service.dart';
import '../../game/services/progress_service.dart';
import '../../game/systems/game_engine.dart';
import '../../theme/game_colors.dart';
import '../../theme/world_theme.dart';
import '../widgets/game_board.dart';
import '../widgets/scifi_background.dart';
import '../widgets/level_intro_dialog.dart';

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

  WorldTheme get _theme => WorldTheme.of(widget.world);

  @override
  void initState() {
    super.initState();
    _engine = GameEngine(level: widget.level);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showLevelIntro());
  }

  Future<void> _showLevelIntro() async {
    if (!mounted) return;
    final hint = widget.level.hint ?? '';
    if (hint.isEmpty) return;
    await showLevelIntroDialog(
      context,
      world: widget.world,
      level: widget.levelIndex,
      levelName: widget.level.name,
      hint: hint,
      theme: _theme,
    );
  }

  void _showHint() {
    final hint = widget.level.hint ?? '';
    if (hint.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: GameColors.key.withValues(alpha: 0.4)),
        ),
        title: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'HINT',
              style: GoogleFonts.orbitron(
                color: GameColors.key,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        content: Text(
          hint,
          style: GoogleFonts.exo2(
            color: GameColors.hudText,
            fontSize: 15,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'GOT IT',
              style: GoogleFonts.orbitron(color: _theme.accent),
            ),
          ),
        ],
      ),
    );
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
      AudioService.playWin();
      AudioService.hapticWin();
      final stars = _engine.calculateStars();
      await ProgressService.markLevelComplete(widget.level.id);
      await ProgressService.setStars(widget.level.id, stars);

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A2332),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: GameColors.doorOpen.withValues(alpha: 0.5)),
          ),
          title: Text(
            'LEVEL COMPLETE!',
            style: GoogleFonts.orbitron(
              color: GameColors.doorOpen,
              fontSize: 20,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '★' * stars + '☆' * (3 - stars),
                style: const TextStyle(fontSize: 36, color: GameColors.key),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Moves: ${_engine.state.movesUsed} / ${_engine.state.maxMoves}',
                style: GoogleFonts.exo2(color: Colors.white70, fontSize: 15),
              ),
              if (stars < 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Replay for more stars!',
                    style: GoogleFonts.exo2(
                      color: _theme.accent.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _restart();
              },
              child: Text('RETRY', style: GoogleFonts.orbitron(color: GameColors.hudText)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _goToNextLevel();
              },
              child: Text('NEXT', style: GoogleFonts.orbitron(color: _theme.accent)),
            ),
          ],
        ),
      );
    } else if (status == GameStatus.lost) {
      AudioService.hapticBlock();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A2332),
          title: Text(
            'OUT OF MOVES',
            style: GoogleFonts.orbitron(color: GameColors.laser, letterSpacing: 2),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'You ran out of moves. Tap HINT or try again!',
            style: GoogleFonts.exo2(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text('QUIT', style: GoogleFonts.orbitron(color: GameColors.hudText)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showHint();
              },
              child: Text('HINT', style: GoogleFonts.orbitron(color: GameColors.key)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _restart();
              },
              child: Text('RETRY', style: GoogleFonts.orbitron(color: _theme.accent)),
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
    final theme = _theme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.25),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          theme.moodName,
          style: GoogleFonts.orbitron(
            color: theme.accent.withValues(alpha: 0.75),
            fontSize: 12,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
        actions: [
          if ((widget.level.hint ?? '').isNotEmpty)
            IconButton(
              icon: const Icon(Icons.lightbulb_outline, color: GameColors.key),
              onPressed: _showHint,
              tooltip: 'Hint',
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.accentAlt),
            onPressed: _restart,
            tooltip: 'Restart',
          ),
          IconButton(
            icon: Icon(Icons.undo, color: theme.accent),
            onPressed: () {
              _engine.undo();
              setState(() {});
            },
            tooltip: 'Undo',
          ),
        ],
      ),
      body: SciFiBackground(
        theme: theme,
        child: SafeArea(
          child: GameBoard(
            engine: _engine,
            onStateChanged: _onStateChanged,
            world: widget.world,
            levelIndex: widget.levelIndex,
            theme: theme,
          ),
        ),
      ),
    );
  }
}
