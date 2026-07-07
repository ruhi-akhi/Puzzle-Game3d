import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/world_theme.dart';

/// Dark sci-fi lab background with a subtle grid, drifting data particles,
/// a slow scan band and a per-world gradient tint.
class SciFiBackground extends StatefulWidget {
  final Widget child;
  final WorldTheme theme;

  const SciFiBackground({
    super.key,
    required this.child,
    this.theme = WorldTheme.fallback,
  });

  @override
  State<SciFiBackground> createState() => _SciFiBackgroundState();
}

class _Particle {
  double x;
  double y;
  final double speed;
  final double size;
  final double drift;

  _Particle(this.x, this.y, this.speed, this.size, this.drift);
}

class _SciFiBackgroundState extends State<SciFiBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _rng = math.Random(7);
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _particles = List.generate(26, (_) {
      return _Particle(
        _rng.nextDouble(),
        _rng.nextDouble(),
        0.02 + _rng.nextDouble() * 0.06,
        0.6 + _rng.nextDouble() * 1.8,
        (_rng.nextDouble() - 0.5) * 0.04,
      );
    });
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
          painter: _SciFiBgPainter(
            phase: _controller.value,
            theme: widget.theme,
            particles: _particles,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SciFiBgPainter extends CustomPainter {
  final double phase;
  final WorldTheme theme;
  final List<_Particle> particles;

  _SciFiBgPainter({
    required this.phase,
    required this.theme,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Per-world gradient base, gently shifting over time.
    final shift = 0.5 + 0.5 * math.sin(phase * math.pi * 2);
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(theme.bgTop, const Color(0xFF04060C), shift)!,
          Color.lerp(theme.bgBottom, theme.bgTop, shift * 0.5)!,
          theme.bgBottom,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    // Near-invisible dot grid that catches the accent light.
    const spacing = 30.0;
    final dotPaint = Paint()..color = theme.accent.withValues(alpha: 0.035);
    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.7, dotPaint);
      }
    }

    // Faint diagonal circuit lines.
    final linePaint = Paint()
      ..color = theme.accentAlt.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    for (var i = -size.height; i < size.width; i += 70) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        linePaint,
      );
    }

    // Drifting data particles.
    for (final p in particles) {
      final py = (p.y - phase * p.speed * 8) % 1.0;
      final ny = py < 0 ? py + 1.0 : py;
      final px = (p.x + math.sin(phase * math.pi * 2 + p.y * 6) * p.drift) % 1.0;
      final pos = Offset(px * size.width, ny * size.height);
      final twinkle = 0.25 + 0.35 * (0.5 + 0.5 * math.sin(phase * math.pi * 4 + p.x * 10));
      final glow = Paint()
        ..color = theme.accent.withValues(alpha: twinkle * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(pos, p.size + 1.5, glow);
      final core = Paint()..color = theme.accent.withValues(alpha: twinkle);
      canvas.drawCircle(pos, p.size, core);
    }

    // Slow moving scan band.
    final scanY = (phase * (size.height + 160)) - 80;
    final scan = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          theme.accent.withValues(alpha: 0.045),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY, size.width, 140));
    canvas.drawRect(Rect.fromLTWH(0, scanY, size.width, 140), scan);

    // Corner vignette to add depth.
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.15,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.5),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);

    // Pulsing corner accents.
    final accentPaint = Paint()
      ..color = theme.accent.withValues(alpha: 0.06 + 0.04 * shift)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const len = 84.0;
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), accentPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), accentPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), accentPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), accentPaint);
  }

  @override
  bool shouldRepaint(covariant _SciFiBgPainter old) =>
      old.phase != phase || old.theme != theme;
}
