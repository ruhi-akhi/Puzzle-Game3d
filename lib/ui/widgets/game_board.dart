import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../game/models/tile_type.dart';
import '../../game/services/audio_service.dart';
import '../../game/systems/game_engine.dart';
import '../../game/rendering/game_painter.dart';
import '../../theme/game_colors.dart';
import '../widgets/neon_button.dart';

class GameBoard extends StatefulWidget {
  final GameEngine engine;
  final VoidCallback onStateChanged;

  const GameBoard({
    super.key,
    required this.engine,
    required this.onStateChanged,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _moveController;
  late AnimationController _tiltController;

  double _displayPlayerX = 0;
  double _displayPlayerY = 0;
  double _fromX = 0;
  double _fromY = 0;
  double _boardTilt = 0;

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
      duration: const Duration(milliseconds: 180),
    )..addListener(() {
        setState(() {
          _displayPlayerX = _fromX +
              (widget.engine.state.playerX - _fromX) * _moveController.value;
          _displayPlayerY = _fromY +
              (widget.engine.state.playerY - _fromY) * _moveController.value;
        });
      });

    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _glowController.dispose();
    _moveController.dispose();
    _tiltController.dispose();
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

    if (widget.engine.move(dir)) {
      AudioService.playMove();
      _fromX = beforeX.toDouble();
      _fromY = beforeY.toDouble();
      _moveController.forward(from: 0);

      final tilt = switch (dir) {
        Direction.up => -0.08,
        Direction.down => 0.08,
        Direction.left => -0.06,
        Direction.right => 0.06,
      };
      _boardTilt = tilt;
      _tiltController.forward(from: 0).then((_) {
        if (mounted) {
          _tiltController.reverse();
        }
      });

      widget.onStateChanged();
      setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final state = widget.engine.state;
    final screenSize = MediaQuery.of(context).size;
    final tileSize = _calculateTileSize(screenSize, state.width, state.height);
    final tiltAnim = _tiltController.value * _boardTilt;

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Column(
        children: [
          _buildHud(state),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_glowController, _tiltController]),
                builder: (context, _) {
                  final matrix = Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateX(0.18 + tiltAnim)
                    ..rotateY(tiltAnim * 0.5);

                  return Transform(
                    transform: matrix,
                    alignment: Alignment.center,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: GameColors.neonCyan.withOpacity(
                              0.15 + 0.1 * math.sin(_glowController.value * math.pi * 2),
                            ),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
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
                          boardTilt: tiltAnim.abs(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  double _calculateTileSize(Size screen, int gridW, int gridH) {
    final maxW = screen.width * 0.9;
    final maxH = screen.height * 0.55;
    final tileW = maxW / gridW;
    final tileH = maxH / gridH;
    return tileW < tileH ? tileW : tileH;
  }

  Widget _buildHud(dynamic state) {
    final movesLeft = state.maxMoves - state.movesUsed;
    final movesColor = movesLeft <= 5 ? GameColors.laser : GameColors.neonCyan;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.levelName,
                style: const TextStyle(
                  color: GameColors.neonCyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (state.hasKey)
                const Text(
                  '🔑 Key Collected',
                  style: TextStyle(color: GameColors.key, fontSize: 12),
                ),
            ],
          ),
          Text(
            'MOVES: $movesLeft / ${state.maxMoves}',
            style: TextStyle(
              color: movesColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          NeonButton(
            label: '',
            onPressed: () => _handleMove(Direction.up),
            icon: Icons.keyboard_arrow_up,
            small: true,
            color: GameColors.neonCyan,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NeonButton(
                label: '',
                onPressed: () => _handleMove(Direction.left),
                icon: Icons.keyboard_arrow_left,
                small: true,
                color: GameColors.neonCyan,
              ),
              const SizedBox(width: 48),
              NeonButton(
                label: '',
                onPressed: () => _handleMove(Direction.right),
                icon: Icons.keyboard_arrow_right,
                small: true,
                color: GameColors.neonCyan,
              ),
            ],
          ),
          NeonButton(
            label: '',
            onPressed: () => _handleMove(Direction.down),
            icon: Icons.keyboard_arrow_down,
            small: true,
            color: GameColors.neonCyan,
          ),
        ],
      ),
    );
  }
}
