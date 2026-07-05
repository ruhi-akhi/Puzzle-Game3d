import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../game/models/tile_type.dart';
import '../../game/services/audio_service.dart';
import '../../game/systems/game_engine.dart';
import '../../game/rendering/game_painter.dart';
import '../../theme/game_colors.dart';
import 'direction_pad.dart';

class GameBoard extends StatefulWidget {
  final GameEngine engine;
  final VoidCallback onStateChanged;
  final int world;
  final int levelIndex;

  const GameBoard({
    super.key,
    required this.engine,
    required this.onStateChanged,
    required this.world,
    required this.levelIndex,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _moveController;

  double _displayPlayerX = 0;
  double _displayPlayerY = 0;
  double _fromX = 0;
  double _fromY = 0;

  @override
  void initState() {
    super.initState();
    _displayPlayerX = widget.engine.state.playerX.toDouble();
    _displayPlayerY = widget.engine.state.playerY.toDouble();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(() {
        setState(() {
          _displayPlayerX = _fromX +
              (widget.engine.state.playerX - _fromX) * _moveController.value;
          _displayPlayerY = _fromY +
              (widget.engine.state.playerY - _fromY) * _moveController.value;
        });
      });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.engine.state.movesUsed == 0 &&
        oldWidget.engine.state.movesUsed > 0) {
      _displayPlayerX = widget.engine.state.playerX.toDouble();
      _displayPlayerY = widget.engine.state.playerY.toDouble();
    }
  }

  void _handleMove(Direction dir) {
    final beforeX = widget.engine.state.playerX;
    final beforeY = widget.engine.state.playerY;
    final hadKeyBefore = widget.engine.state.hasKey;

    if (widget.engine.move(dir)) {
      AudioService.playMove();
      AudioService.hapticMove();
      if (!hadKeyBefore && widget.engine.state.hasKey) {
        AudioService.playCollect();
        HapticFeedback.mediumImpact();
      }
      _fromX = beforeX.toDouble();
      _fromY = beforeY.toDouble();
      _moveController.forward(from: 0);
      widget.onStateChanged();
      setState(() {});
    } else {
      AudioService.playBlock();
      AudioService.hapticBlock();
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        _handleMove(Direction.up);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        _handleMove(Direction.down);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        _handleMove(Direction.left);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        _handleMove(Direction.right);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  int _projectedStars(int movesUsed, int maxMoves) {
    if (movesUsed == 0) return 3;
    final ratio = movesUsed / maxMoves;
    if (ratio <= 0.5) return 3;
    if (ratio <= 0.75) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.engine.state;
    final screenSize = MediaQuery.of(context).size;
    final tileSize = _calculateTileSize(screenSize, state.width, state.height);

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Column(
        children: [
          _buildHud(state),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, _) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: GameColors.neonCyan.withOpacity(
                          0.15 + 0.08 * math.sin(_glowController.value * math.pi * 2),
                        ),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: GameColors.neonCyan.withOpacity(
                            0.12 +
                                0.08 *
                                    math.sin(
                                        _glowController.value * math.pi * 2),
                          ),
                          blurRadius: 28,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CustomPaint(
                        size: Size(
                          state.width * tileSize,
                          state.height * tileSize,
                        ),
                        painter: GamePainter(
                          state: state,
                          tileSize: tileSize,
                          animationPhase: _glowController.value,
                          displayPlayerX: _displayPlayerX,
                          displayPlayerY: _displayPlayerY,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          DirectionPad(onMove: _handleMove),
        ],
      ),
    );
  }

  double _calculateTileSize(Size screen, int gridW, int gridH) {
    final maxW = screen.width * 0.92;
    final maxH = screen.height * 0.58;
    final tileW = maxW / gridW;
    final tileH = maxH / gridH;
    return tileW < tileH ? tileW : tileH;
  }

  Widget _buildHud(dynamic state) {
    final movesLeft = state.maxMoves - state.movesUsed;
    final movesColor = movesLeft <= 5 ? GameColors.laser : GameColors.neonCyan;
    final projected = _projectedStars(state.movesUsed, state.maxMoves);
    final star3 = (state.maxMoves * 0.5).ceil();
    final star2 = (state.maxMoves * 0.75).ceil();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.neonCyan.withOpacity(0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORLD ${widget.world} — ${widget.levelIndex}',
                  style: GoogleFonts.orbitron(
                    color: GameColors.neonCyan.withOpacity(0.85),
                    fontSize: 13,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.levelName.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    color: GameColors.hudText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                if (state.hasKey)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '🔑 KEY COLLECTED',
                      style: GoogleFonts.exo2(
                        color: GameColors.key,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'MOVES',
                style: GoogleFonts.orbitron(
                  color: Colors.white54,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '$movesLeft / ${state.maxMoves}',
                style: GoogleFonts.orbitron(
                  color: movesColor,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final filled = i < projected;
                  return Text(
                    filled ? '★' : '☆',
                    style: TextStyle(
                      fontSize: 14,
                      color: filled
                          ? GameColors.key
                          : Colors.white24,
                    ),
                  );
                }),
              ),
              Text(
                '3★ ≤$star3  2★ ≤$star2',
                style: GoogleFonts.exo2(
                  color: Colors.white38,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
