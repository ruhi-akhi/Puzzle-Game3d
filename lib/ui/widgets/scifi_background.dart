import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/game_colors.dart';

/// Dark sci-fi lab background with grid pattern and subtle scan-line motion.
class SciFiBackground extends StatefulWidget {
  final Widget child;

  const SciFiBackground({super.key, required this.child});

  @override
  State<SciFiBackground> createState() => _SciFiBackgroundState();
}

class _SciFiBackgroundState extends State<SciFiBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SciFiBgPainter(phase: _controller.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SciFiBgPainter extends CustomPainter {
  final double phase;

  _SciFiBgPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base gradient
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF060A12),
          GameColors.background,
          const Color(0xFF0D1520),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    // Dot grid
    const spacing = 28.0;
    final dotPaint = Paint()..color = GameColors.neonCyan.withOpacity(0.04);
    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
      }
    }

    // Diagonal circuit lines
    final linePaint = Paint()
      ..color = GameColors.neonPurple.withOpacity(0.03)
      ..strokeWidth = 1;
    for (var i = -size.height; i < size.width; i += 64) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        linePaint,
      );
    }

    // Moving scan band
    final scanY = (phase * (size.height + 120)) - 60;
    final scan = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          GameColors.neonCyan.withOpacity(0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY, size.width, 120));
    canvas.drawRect(Rect.fromLTWH(0, scanY, size.width, 120), scan);

    // Corner vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.1,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.45),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);

    // Subtle corner accents
    final accent = Paint()
      ..color = GameColors.neonCyan.withOpacity(
        0.06 + 0.03 * math.sin(phase * math.pi * 2),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, 0), Offset(80, 0), accent);
    canvas.drawLine(Offset(0, 0), Offset(0, 80), accent);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - 80, size.height), accent);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - 80), accent);
  }

  @override
  bool shouldRepaint(covariant _SciFiBgPainter old) => old.phase != phase;
}
