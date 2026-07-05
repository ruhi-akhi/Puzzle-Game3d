import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/models/tile_type.dart';
import '../../theme/game_colors.dart';

/// Compact semi-transparent D-pad with thin neon borders.
class DirectionPad extends StatelessWidget {
  final void Function(Direction direction) onMove;

  const DirectionPad({super.key, required this.onMove});

  void _tap(VoidCallback action) {
    HapticFeedback.selectionClick();
    action();
  }

  @override
  Widget build(BuildContext context) {
    const size = 52.0;
    const gap = 6.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PadButton(
            size: size,
            icon: Icons.keyboard_arrow_up,
            onTap: () => _tap(() => onMove(Direction.up)),
          ),
          SizedBox(height: gap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PadButton(
                size: size,
                icon: Icons.keyboard_arrow_left,
                onTap: () => _tap(() => onMove(Direction.left)),
              ),
              SizedBox(width: gap),
              const SizedBox(width: size, height: size),
              SizedBox(width: gap),
              _PadButton(
                size: size,
                icon: Icons.keyboard_arrow_right,
                onTap: () => _tap(() => onMove(Direction.right)),
              ),
            ],
          ),
          SizedBox(height: gap),
          _PadButton(
            size: size,
            icon: Icons.keyboard_arrow_down,
            onTap: () => _tap(() => onMove(Direction.down)),
          ),
        ],
      ),
    );
  }
}

class _PadButton extends StatefulWidget {
  final double size;
  final IconData icon;
  final VoidCallback onTap;

  const _PadButton({
    required this.size,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PadButton> createState() => _PadButtonState();
}

class _PadButtonState extends State<_PadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: GameColors.neonCyan.withOpacity(_pressed ? 0.22 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: GameColors.neonCyan.withOpacity(_pressed ? 0.9 : 0.55),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: GameColors.neonCyan.withOpacity(_pressed ? 0.35 : 0.12),
              blurRadius: _pressed ? 10 : 6,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(
          widget.icon,
          color: GameColors.neonCyan.withOpacity(_pressed ? 1 : 0.85),
          size: 28,
        ),
      ),
    );
  }
}