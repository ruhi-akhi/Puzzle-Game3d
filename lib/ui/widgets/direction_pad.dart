import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/models/tile_type.dart';
import '../../theme/game_colors.dart';

/// Compact semi-transparent D-pad with unique trapezoid (arrow-slice) buttons
/// arranged around a hollow hub. Accent color is driven by the world theme.
class DirectionPad extends StatelessWidget {
  final void Function(Direction direction) onMove;
  final Color accent;

  const DirectionPad({
    super.key,
    required this.onMove,
    this.accent = GameColors.neonCyan,
  });

  void _tap(Direction dir) {
    HapticFeedback.selectionClick();
    onMove(dir);
  }

  @override
  Widget build(BuildContext context) {
    const size = 150.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Hollow hub
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.3),
                  width: 1,
                ),
                color: accent.withValues(alpha: 0.04),
              ),
            ),
            _SliceButton(
              accent: accent,
              direction: Direction.up,
              alignment: Alignment.topCenter,
              onTap: () => _tap(Direction.up),
            ),
            _SliceButton(
              accent: accent,
              direction: Direction.down,
              alignment: Alignment.bottomCenter,
              onTap: () => _tap(Direction.down),
            ),
            _SliceButton(
              accent: accent,
              direction: Direction.left,
              alignment: Alignment.centerLeft,
              onTap: () => _tap(Direction.left),
            ),
            _SliceButton(
              accent: accent,
              direction: Direction.right,
              alignment: Alignment.centerRight,
              onTap: () => _tap(Direction.right),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliceButton extends StatefulWidget {
  final Color accent;
  final Direction direction;
  final Alignment alignment;
  final VoidCallback onTap;

  const _SliceButton({
    required this.accent,
    required this.direction,
    required this.alignment,
    required this.onTap,
  });

  @override
  State<_SliceButton> createState() => _SliceButtonState();
}

class _SliceButtonState extends State<_SliceButton> {
  bool _pressed = false;

  double get _angle {
    switch (widget.direction) {
      case Direction.up:
        return 0;
      case Direction.right:
        return 1.5708;
      case Direction.down:
        return 3.14159;
      case Direction.left:
        return -1.5708;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1,
          duration: const Duration(milliseconds: 90),
          child: Transform.rotate(
            angle: _angle,
            child: CustomPaint(
              size: const Size(58, 46),
              painter: _SlicePainter(
                accent: widget.accent,
                pressed: _pressed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlicePainter extends CustomPainter {
  final Color accent;
  final bool pressed;

  _SlicePainter({required this.accent, required this.pressed});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Trapezoid slice pointing up (narrow top, wide bottom).
    final path = Path()
      ..moveTo(w * 0.34, h * 0.08)
      ..lineTo(w * 0.66, h * 0.08)
      ..lineTo(w * 0.94, h * 0.92)
      ..lineTo(w * 0.06, h * 0.92)
      ..close();

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withValues(alpha: pressed ? 0.28 : 0.10);
    canvas.drawPath(path, fill);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = accent.withValues(alpha: pressed ? 1 : 0.55);
    canvas.drawPath(path, border);

    if (pressed) {
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = accent.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(path, glow);
    }

    // Chevron arrow near the narrow (top) end.
    final chevron = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = accent.withValues(alpha: pressed ? 1 : 0.85);
    final cx = w / 2;
    final cy = h * 0.34;
    final s = w * 0.14;
    canvas.drawPath(
      Path()
        ..moveTo(cx - s, cy + s * 0.7)
        ..lineTo(cx, cy - s * 0.4)
        ..lineTo(cx + s, cy + s * 0.7),
      chevron,
    );
  }

  @override
  bool shouldRepaint(covariant _SlicePainter old) =>
      old.pressed != pressed || old.accent != accent;
}
