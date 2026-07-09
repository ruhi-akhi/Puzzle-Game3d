import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/tile_type.dart';
import '../../theme/world_theme.dart';

class GameColors {
  static const background = Color(0xFF10131F);
  static const gridLine = Color(0xFF262F4B);
  static const wall = Color(0xFF324A82);
  static const wallOutline = Color(0xFF6A89D8);
  static const wallPanel = Color(0xFF4B67AF);
  static const floor = Color(0xFF17213A);
  static const floorShadow = Color(0xFF101B31);
  static const player = Color(0xFF7DF2FF);
  static const playerGlow = Color(0xB300FFFF);
  static const playerOutline = Color(0xFF3EC6FF);
  static const door = Color(0xFFFFA75A);
  static const doorFrame = Color(0xFFDA8745);
  static const doorOpen = Color(0xFF6EE7B7);
  static const key = Color(0xFFFFE26F);
  static const keyDetail = Color(0xFFBE8F00);
  static const box = Color(0xFFEDB57E);
  static const boxDetail = Color(0xFFB5783F);
  static const goal = Color(0xFF7FF2FF);
  static const mirror = Color(0xFFDDE6F0);
  static const mirrorGlow = Color(0xFFF5FBFF);
  static const laser = Color(0xFFFF5D83);
  static const laserGlow = Color(0xAAFF90AB);
  static const redSwitch = Color(0xFFFF7A7A);
  static const blueSwitch = Color(0xFF7CB5FF);
  static const teleporter = Color(0xFFA76EFF);
  static const teleporterRing = Color(0xFFE2B7FF);
  static const ice = Color(0xFF9CF2FF);
  static const bomb = Color(0xFFFF5E5E);
  static const clone = Color(0xFFB9C6DD);
  static const gravity = Color(0xFFFFCE5F);
  static const darkZone = Color(0xFF151626);
  static const lightZone = Color(0xFF2F3F62);
  static const neonCyan = Color(0xFF83FBFF);
  static const neonPink = Color(0xFFFF8FDF);
  static const neonPurple = Color(0xFFBE92FF);
  static const hudText = Color(0xFFECEFF5);
}

class GamePainter extends CustomPainter {
  final GameState state;
  final double tileSize;
  final double animationPhase;
  final double displayPlayerX;
  final double displayPlayerY;
  final WorldTheme theme;

  /// Recent player grid positions (oldest first) for the colored trail.
  final List<Offset> trail;

  /// 0..1 pulse used to tint the player after a valid move.
  final double moveFlash;

  GamePainter({
    required this.state,
    required this.tileSize,
    this.animationPhase = 0,
    this.displayPlayerX = -1,
    this.displayPlayerY = -1,
    this.theme = WorldTheme.fallback,
    this.trail = const [],
    this.moveFlash = 0,
  });

  double get _pulse => 0.5 + 0.5 * math.sin(animationPhase * math.pi * 2);
  double get _pulseFast => 0.5 + 0.5 * math.sin(animationPhase * math.pi * 4);

  double get _playerX => displayPlayerX >= 0 ? displayPlayerX : state.playerX.toDouble();
  double get _playerY => displayPlayerY >= 0 ? displayPlayerY : state.playerY.toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final offsetX = (size.width - state.width * tileSize) / 2;
    final offsetY = (size.height - state.height * tileSize) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);

    for (var y = 0; y < state.height; y++) {
      for (var x = 0; x < state.width; x++) {
        _drawTile(canvas, x, y, state.tileAt(x, y));
        if (state.isGoalAt(x, y)) {
          _drawGoal(canvas, Rect.fromLTWH(
            x * tileSize + 1,
            y * tileSize + 1,
            tileSize - 2,
            tileSize - 2,
          ));
        }
      }
    }

    _drawTrail(canvas);

    for (final clone in state.cloneHistory) {
      _drawClone(canvas, clone.x, clone.y);
    }

    _drawPlayerShadow(canvas, _playerX, _playerY);
    _drawPlayer(canvas, _playerX, _playerY);

    canvas.restore();
  }

  /// Fading accent trail behind the player — a "correct move" light path.
  void _drawTrail(Canvas canvas) {
    if (trail.isEmpty) return;
    for (var i = 0; i < trail.length; i++) {
      final t = (i + 1) / trail.length;
      final center = Offset(
        trail[i].dx * tileSize + tileSize / 2,
        trail[i].dy * tileSize + tileSize / 2,
      );
      final glow = Paint()
        ..color = theme.accent.withValues(alpha: 0.10 * t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, tileSize * 0.22 * t, glow);
      final dot = Paint()..color = theme.accent.withValues(alpha: 0.18 * t);
      canvas.drawCircle(center, tileSize * 0.10 * t, dot);
    }
  }

  /// Frosted-glass tile: translucent fill + top light gradient + hairline edge.
  void _drawGlassTile(
    Canvas canvas,
    Rect rect,
    Color tint, {
    double radius = 6,
    double fill = 0.22,
  }) {
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final base = Paint()..color = tint.withValues(alpha: fill);
    canvas.drawRRect(rr, base);

    final sheen = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.14),
          Colors.white.withValues(alpha: 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rr, sheen);

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = tint.withValues(alpha: 0.55);
    canvas.drawRRect(rr.deflate(0.5), edge);
  }

  void _drawTile(Canvas canvas, int x, int y, TileType type) {
    final rect = Rect.fromLTWH(
      x * tileSize + 1,
      y * tileSize + 1,
      tileSize - 2,
      tileSize - 2,
    );

    switch (type) {
      case TileType.wall:
        _drawWall(canvas, rect);
        break;
      case TileType.floor:
      case TileType.empty:
        _drawFloor(canvas, rect);
        break;
      case TileType.door:
        _drawDoor(canvas, rect, open: false);
        break;
      case TileType.doorOpen:
        _drawDoor(canvas, rect, open: true);
        break;
      case TileType.key:
        _drawFloor(canvas, rect);
        _drawKey(canvas, rect);
        break;
      case TileType.box:
        _drawCrate(canvas, rect);
        break;
      case TileType.goal:
        _drawFloor(canvas, rect);
        _drawGoal(canvas, rect);
        break;
      case TileType.mirror:
        _drawFloor(canvas, rect);
        _drawMirror(canvas, rect, true);
        break;
      case TileType.mirrorSlash:
        _drawFloor(canvas, rect);
        _drawMirror(canvas, rect, true);
        break;
      case TileType.mirrorBackslash:
        _drawFloor(canvas, rect);
        _drawMirror(canvas, rect, false);
        break;
      case TileType.laserEmitter:
        _drawFloor(canvas, rect);
        _drawLaserEmitter(canvas, rect);
        break;
      case TileType.laserBeam:
        _drawLaserBeam(canvas, rect);
        break;
      case TileType.redSwitch:
        _drawFloor(canvas, rect);
        _drawSwitch(canvas, rect, GameColors.redSwitch, state.redSwitchOn);
        break;
      case TileType.blueSwitch:
        _drawFloor(canvas, rect);
        _drawSwitch(canvas, rect, GameColors.blueSwitch, state.blueSwitchOn);
        break;
      case TileType.redDoor:
        _drawDoor(canvas, rect,
            open: state.redSwitchOn, color: state.redSwitchOn ? GameColors.doorOpen : GameColors.redSwitch);
        break;
      case TileType.blueDoor:
        _drawDoor(canvas, rect,
            open: state.blueSwitchOn, color: state.blueSwitchOn ? GameColors.doorOpen : GameColors.blueSwitch);
        break;
      case TileType.teleporterA:
      case TileType.teleporterB:
        _drawFloor(canvas, rect);
        _drawTeleporter(canvas, rect);
        break;
      case TileType.ice:
        _drawGlassTile(canvas, rect, GameColors.ice, radius: 8, fill: 0.28);
        _drawIce(canvas, rect);
        break;
      case TileType.bomb:
        _drawBomb(canvas, rect);
        break;
      case TileType.gravityPad:
        _drawFloor(canvas, rect);
        _drawGravityPad(canvas, rect);
        break;
      case TileType.darkZone:
        _drawZone(canvas, rect, GameColors.darkZone);
        break;
      case TileType.lightZone:
        _drawZone(canvas, rect, GameColors.lightZone);
        break;
      default:
        _drawFloor(canvas, rect);
        break;
    }

    // Hairline grid — nearly invisible, tinted by the world accent.
    final gridPaint = Paint()
      ..color = theme.accent.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRect(
      Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize),
      gridPaint,
    );
  }

  void _drawFloor(Canvas canvas, Rect rect) {
    final base = Paint()
      ..shader = LinearGradient(
        colors: [GameColors.floor, GameColors.floorShadow],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(tileSize * 0.18)), base);

    final inner = Paint()
      ..color = theme.accent.withValues(alpha: 0.06 + 0.02 * _pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(tileSize * 0.18), Radius.circular(tileSize * 0.18)),
      inner,
    );

    final dot = Paint()..color = theme.accent.withValues(alpha: 0.08);
    final spacing = tileSize * 0.32;
    for (var x = rect.left + spacing * 0.3; x < rect.right; x += spacing) {
      for (var y = rect.top + spacing * 0.3; y < rect.bottom; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, dot);
      }
    }
  }

  void _drawGlow(Canvas canvas, Rect rect, Color color, double intensity) {
    final glowPaint = Paint()
      ..color = color.withValues(alpha: intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(3), const Radius.circular(8)),
      glowPaint,
    );
  }

  void _drawPulsingGlow(
    Canvas canvas,
    Rect rect,
    Color color, {
    double base = 0.35,
    double range = 0.35,
    double blur = 8,
  }) {
    final glowPaint = Paint()
      ..color = color.withValues(alpha: base + range * _pulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur + 2 * _pulse);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(2 + _pulse * 2), const Radius.circular(4)),
      glowPaint,
    );
  }

  void _drawPlayerShadow(Canvas canvas, double x, double y) {
    final center = Offset(
      x * tileSize + tileSize / 2,
      y * tileSize + tileSize / 2 + tileSize * 0.12,
    );
    final shadow = Paint()
      ..color = theme.accent.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: tileSize * 0.5, height: tileSize * 0.2),
      shadow,
    );
  }

  void _drawPlayer(Canvas canvas, double x, double y) {
    final center = Offset(
      x * tileSize + tileSize / 2,
      y * tileSize + tileSize / 2,
    );
    final flash = moveFlash.clamp(0.0, 1.0);
    final pulse = 1.0 + 0.08 * _pulseFast + 0.12 * flash;
    final radius = tileSize * 0.32 * pulse;

    final ringPaint = Paint()
      ..color = theme.accent.withValues(alpha: 0.28 + 0.18 * _pulse + 0.2 * flash)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, radius + 8, ringPaint);

    final outerGlow = Paint()
      ..color = GameColors.playerGlow.withValues(alpha: 0.22 + 0.18 * _pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, radius + 12, outerGlow);

    final body = Paint()..color = GameColors.player;
    canvas.drawCircle(center, radius, body);

    final border = Paint()
      ..color = GameColors.playerOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, border);

    final eye = Paint()..color = Colors.white;
    final leftEye = center + Offset(-radius * 0.18, -radius * 0.08);
    final rightEye = center + Offset(radius * 0.18, -radius * 0.08);
    canvas.drawCircle(leftEye, radius * 0.12, eye);
    canvas.drawCircle(rightEye, radius * 0.12, eye);

    final pupil = Paint()..color = Colors.black;
    canvas.drawCircle(leftEye, radius * 0.05, pupil);
    canvas.drawCircle(rightEye, radius * 0.05, pupil);

    final highlight = Paint()..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(
      center + Offset(-radius * 0.2, -radius * 0.2),
      radius * 0.26,
      highlight,
    );
  }

  void _drawClone(Canvas canvas, int x, int y) {
    final center = Offset(
      x * tileSize + tileSize / 2,
      y * tileSize + tileSize / 2,
    );
    final paint = Paint()
      ..color = GameColors.clone.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, tileSize * 0.28, paint);
  }

  void _drawKey(Canvas canvas, Rect rect) {
    final paint = Paint()..color = GameColors.key;
    final head = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.center.dy - tileSize * 0.08),
      width: tileSize * 0.24,
      height: tileSize * 0.22,
    );
    canvas.drawOval(head, paint);

    final shaft = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.center.dy + tileSize * 0.08),
      width: tileSize * 0.12,
      height: tileSize * 0.26,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(shaft, const Radius.circular(4)), paint);

    final detail = Paint()
      ..color = GameColors.keyDetail
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(rect.center.dx, rect.center.dy - tileSize * 0.02),
      Offset(rect.center.dx, rect.center.dy + tileSize * 0.14),
      detail,
    );
    canvas.drawCircle(Offset(rect.center.dx + tileSize * 0.08, rect.center.dy + tileSize * 0.12), 3, detail);
    canvas.drawCircle(Offset(rect.center.dx - tileSize * 0.08, rect.center.dy + tileSize * 0.12), 3, detail);

    _drawPulsingGlow(canvas, rect, GameColors.key, base: 0.32, range: 0.38);
  }

  void _drawGoal(Canvas canvas, Rect rect) {
    final center = rect.center;
    final outer = Paint()
      ..color = theme.accentAlt.withValues(alpha: 0.22 + 0.18 * _pulse)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, tileSize * 0.22, outer);

    final star = Paint()
      ..color = theme.accentAlt
      ..style = PaintingStyle.fill;
    final path = Path();
    const points = 5;
    final radius = tileSize * 0.12;
    final inner = radius * 0.45;
    for (var i = 0; i < points * 2; i++) {
      final angle = i * math.pi / points - math.pi / 2;
      final r = i.isEven ? radius : inner;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, star);

    _drawPulsingGlow(canvas, rect, theme.accentAlt, base: 0.12, range: 0.28, blur: 10);
  }

  void _drawMirror(Canvas canvas, Rect rect, bool slash) {
    final paint = Paint()
      ..color = GameColors.mirror
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    if (slash) {
      canvas.drawLine(rect.bottomLeft, rect.topRight, paint);
    } else {
      canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
    }
    _drawGlow(canvas, rect, GameColors.mirrorGlow, 0.35);
  }

  void _drawLaserEmitter(Canvas canvas, Rect rect) {
    final paint = Paint()..color = GameColors.laser;
    canvas.drawCircle(rect.center, tileSize * 0.2 * (1 + 0.06 * _pulseFast), paint);
    _drawPulsingGlow(canvas, rect, GameColors.laser, base: 0.5, range: 0.45, blur: 12);
  }

  void _drawSwitch(Canvas canvas, Rect rect, Color color, bool isOn) {
    final paint = Paint()
      ..color = isOn ? color : color.withValues(alpha: 0.4);
    canvas.drawCircle(rect.center, tileSize * 0.2, paint);
    if (isOn) _drawPulsingGlow(canvas, rect, color, base: 0.4, range: 0.4);
  }

  void _drawTeleporter(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = GameColors.teleporter
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rotation = animationPhase * 6.28;
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(rotation);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: tileSize * 0.5, height: tileSize * 0.5),
      paint,
    );
    canvas.restore();
    _drawGlow(canvas, rect, GameColors.teleporter, 0.4);
  }

  void _drawIce(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = GameColors.ice.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(rect.left + 4, rect.top + 8),
      Offset(rect.right - 4, rect.bottom - 8),
      paint,
    );
  }

  void _drawGravityPad(Canvas canvas, Rect rect) {
    final paint = Paint()..color = GameColors.gravity;
    final path = Path()
      ..moveTo(rect.center.dx, rect.top + 6)
      ..lineTo(rect.right - 6, rect.bottom - 6)
      ..lineTo(rect.left + 6, rect.bottom - 6)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawWall(Canvas canvas, Rect rect) {
    final base = Paint()
      ..shader = LinearGradient(
        colors: [GameColors.wall, GameColors.wallPanel],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(10)), base);

    final edge = Paint()
      ..color = GameColors.wallOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(1.5), Radius.circular(8)), edge);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.2;
    canvas.drawLine(rect.topLeft + const Offset(10, 10), rect.topRight - const Offset(10, -0), line);
    canvas.drawLine(rect.bottomLeft + const Offset(10, -10), rect.bottomRight - const Offset(10, 10), line);
    _drawGlow(canvas, rect, GameColors.wallOutline, 0.12);
  }

  void _drawDoor(Canvas canvas, Rect rect, {required bool open, Color? color}) {
    final fill = color ?? (open ? GameColors.doorOpen : GameColors.door);
    final base = Paint()..color = fill;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(10)), base);

    final frame = Paint()
      ..color = GameColors.doorFrame
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(2), Radius.circular(8)), frame);

    if (!open) {
      final handle = Paint()..color = Colors.black.withAlpha(210);
      canvas.drawCircle(rect.centerRight - Offset(tileSize * 0.18, 0), tileSize * 0.08, handle);
      canvas.drawCircle(rect.centerRight - Offset(tileSize * 0.08, 0), tileSize * 0.05, Paint()..color = GameColors.door);
    } else {
      final shine = Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withAlpha(180), Colors.transparent],
          radius: 0.7,
        ).createShader(Rect.fromCircle(center: rect.center, radius: tileSize * 0.5));
      canvas.drawCircle(rect.center, tileSize * 0.4, shine);
    }

    _drawGlow(canvas, rect, fill.withAlpha(160), 0.2);
  }

  void _drawCrate(Canvas canvas, Rect rect) {
    final box = Paint()..color = GameColors.box;
    final border = Paint()
      ..color = GameColors.boxDetail
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(10)), box);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(2), Radius.circular(8)), border);

    final top = Paint()
      ..color = GameColors.box.withAlpha(180);
    canvas.drawRect(Rect.fromLTWH(rect.left + 4, rect.top + 4, rect.width - 8, rect.height * 0.22), top);

    final plank = Paint()
      ..color = GameColors.boxDetail
      ..strokeWidth = 3;
    for (var i = 1; i <= 2; i++) {
      final x = rect.left + rect.width * (0.25 * i);
      canvas.drawLine(Offset(x, rect.top + 6), Offset(x, rect.bottom - 6), plank);
    }

    _drawGlow(canvas, rect, GameColors.boxDetail, 0.18);
  }

  void _drawLaserBeam(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [GameColors.laser.withAlpha(220), GameColors.laser.withAlpha(120)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(6)), paint);
    _drawPulsingGlow(canvas, rect, GameColors.laserGlow, base: 0.4, range: 0.35, blur: 16);
  }

  void _drawBomb(Canvas canvas, Rect rect) {
    final base = Paint()..color = GameColors.bomb;
    canvas.drawCircle(rect.center, tileSize * 0.32, base);

    final rim = Paint()
      ..color = Colors.black.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(rect.center, tileSize * 0.32, rim);

    final fuse = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 4;
    canvas.drawLine(
      Offset(rect.center.dx, rect.top + tileSize * 0.05),
      Offset(rect.center.dx, rect.top - tileSize * 0.05),
      fuse,
    );
    canvas.drawCircle(
      Offset(rect.center.dx, rect.top - tileSize * 0.07),
      tileSize * 0.05,
      Paint()..color = Colors.yellowAccent,
    );

    _drawGlow(canvas, rect, GameColors.bomb, 0.35);
  }

  void _drawZone(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()..color = color;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(10)), paint);
    final dashPaint = Paint()
      ..color = Colors.white.withAlpha(70)
      ..strokeWidth = 1.5;
    final step = 8.0;
    for (var x = rect.left + 4; x < rect.right - 4; x += step * 2) {
      canvas.drawLine(Offset(x, rect.bottom - 6), Offset(x + step, rect.bottom - 6), dashPaint);
    }
    _drawGlow(canvas, rect, color.withAlpha(120), 0.15);
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.animationPhase != animationPhase ||
      oldDelegate.displayPlayerX != displayPlayerX ||
      oldDelegate.displayPlayerY != displayPlayerY ||
      oldDelegate.theme != theme ||
      oldDelegate.moveFlash != moveFlash ||
      oldDelegate.trail != trail;
}
