import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/models/tile_type.dart';
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

class _GameBoardState extends State<GameBoard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleMove(Direction dir) {
    if (widget.engine.move(dir)) {
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

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Column(
        children: [
          _buildHud(state),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(
                      state.width * tileSize,
                      state.height * tileSize,
                    ),
                    painter: GamePainter(
                      state: state,
                      tileSize: tileSize,
                      animationPhase: _animController.value,
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
