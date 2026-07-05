import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/tile_type.dart';

class GameColors {
  static const background = Color(0xFF0A0E17);
  static const gridLine = Color(0xFF1A2332);
  static const wall = Color(0xFF2D3A4F);
  static const wallGlow = Color(0xFF4A6FA5);
  static const floor = Color(0xFF111827);
  static const player = Color(0xFF00F5FF);
  static const playerGlow = Color(0x6600F5FF);
  static const door = Color(0xFFFF6B35);
  static const doorOpen = Color(0xFF4ADE80);
  static const key = Color(0xFFFFD700);
  static const box = Color(0xFF8B5CF6);
  static const goal = Color(0xFF22D3EE);
  static const mirror = Color(0xFFE2E8F0);
  static const laser = Color(0xFFFF0040);
  static const laserGlow = Color(0x88FF0040);
  static const redSwitch = Color(0xFFEF4444);
  static const blueSwitch = Color(0xFF3B82F6);
  static const teleporter = Color(0xFFA855F7);
  static const ice = Color(0xFF67E8F9);
  static const bomb = Color(0xFFFF4444);
  static const clone = Color(0xFF94A3B8);
  static const gravity = Color(0xFFF59E0B);
  static const darkZone = Color(0xFF1E1B2E);
  static const lightZone = Color(0xFF2A2540);
  static const neonCyan = Color(0xFF00F5FF);
  static const neonPink = Color(0xFFFF00AA);
  static const neonPurple = Color(0xFF8B5CF6);
  static const hudText = Color(0xFFE2E8F0);
}

class GamePainter extends CustomPainter {
  final GameState state;
  final double tileSize;
  final double animationPhase;
  final double displayPlayerX;
  final double displayPlayerY;

  GamePainter({
    required this.state,
    required this.tileSize,
    this.animationPhase = 0,
    this.displayPlayerX = -1,
    this.displayPlayerY = -1,
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

    // Draw tiles
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

    // Draw clone
    for (final clone in state.cloneHistory) {
      _drawClone(canvas, clone.x, clone.y);
    }

    // Draw player with glow (3D shadow)
    _drawPlayerShadow(canvas, _playerX, _playerY);
    _drawPlayer(canvas, _playerX, _playerY);

    canvas.restore();
  }

  void _drawTile(Canvas canvas, int x, int y, TileType type) {
    final rect = Rect.fromLTWH(
      x * tileSize + 1,
      y * tileSize + 1,
      tileSize - 2,
      tileSize - 2,
    );

    final paint = Paint()..style = PaintingStyle.fill;

    switch (type) {
      case TileType.wall:
        paint.color = GameColors.wall;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          paint,
        );
        _drawPulsingGlow(canvas, rect, GameColors.wallGlow, base: 0.15, range: 0.2);
      case TileType.floor:
      case TileType.empty:
        paint.color = GameColors.floor;
        canvas.drawRect(rect, paint);
        paint.color = GameColors.neonCyan.withOpacity(0.02 + 0.02 * _pulse);
        canvas.drawRect(rect.deflate(tileSize * 0.35), paint);
      case TileType.door:
        paint.color = GameColors.door;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          paint,
        );
        _drawPulsingGlow(canvas, rect, GameColors.door, base: 0.35, range: 0.3);
      case TileType.doorOpen:
        paint.color = GameColors.doorOpen;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          paint,
        );
      case TileType.key:
        paint.color = GameColors.floor;
        canvas.drawRect(rect, paint);
        _drawKey(canvas, rect);
      case TileType.box:
        paint.color = GameColors.box;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          paint,
        );
        _drawPulsingGlow(canvas, rect, GameColors.neonPurple, base: 0.25, range: 0.35);
      case TileType.goal:
        paint.color = GameColors.floor;
        canvas.drawRect(rect, paint);
        _drawGoal(canvas, rect);
      case TileType.mirror:
      case TileType.mirrorSlash:
        paint.color = GameColors.floor;
        canvas.drawRect(rect, paint);
        _drawMirror(canvas, rect, true);
      case TileType.mirrorBackslash:
        paint.color = GameColors.floor;
        canvas.drawRect(rect, paint);
        _drawMirror(canvas, rect, false);
      case TileType.laserEmitter:
        paint.color = GameColors.floor;
        canvas.drawRect(rect, paint);
        _drawLaserEmitter(canvas, rect);
      case TileType.laserBeam:
        paint.color = GameColors.laser;
        canvas.drawRect(rect, paint);
        _drawPulsingGlow(canvas, rect, GameColors.laserGlow, base: 0.45, range: 0.45, blur: 10);
      case TileType.redSwitch:
        paint.color = GameColors.floor;
        canvas.drawRect(rect, paint);
        _drawSwitch(canvas, rect, GameColors.redSwitch, state.redSwitchOn);
      case TileType.blueSwitch:
        paint.color = GameColors.floor;
        canvas.drawRect(rect, paint);
        _drawSwitch(canvas, rect, GameColors.blueSwitch, state.blueSwitchOn);
      case TileType.redDoor:
        paint.color = state.redSwitchOn ? GameColors.doorOpen : GameColors.redSwitch;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          paint,
        );
      case TileType.blueDoor:
        paint.color = state.blueSwitchOn ? GameColors.doorOpen : GameColors.blueSwitch;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          paint,
        );
      case TileType.teleporterA:
      case TileType.teleporterB:
        paint.color = GameColors.floor;
        canvas.drawRect(rect, paint);
        _drawTeleporter(canvas, rect);
      case TileType.ice:
        paint.color = GameColors.ice.withOpacity(0.3);
        canvas.drawRect(rect, paint);
        _drawIce(canvas, rect);
      case TileType.bomb:
        paint.color = GameColors.bomb;
        canvas.drawCircle(rect.center, tileSize * 0.35, paint);
      case TileType.gravityPad:
        paint.color = GameColors.floor;
        canvas.drawRect(rect, paint);
        _drawGravityPad(canvas, rect);
      case TileType.darkZone:
        paint.color = GameColors.darkZone;
        canvas.drawRect(rect, paint);
      case TileType.lightZone:
        paint.color = GameColors.lightZone;
        canvas.drawRect(rect, paint);
      default:
        paint.color = GameColors.floor;
        canvas.drawRect(rect, paint);
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = GameColors.gridLine.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRect(
      Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize),
      gridPaint,
    );
  }

  void _drawGlow(Canvas canvas, Rect rect, Color color, double intensity) {
    final glowPaint = Paint()
      ..color = color.withOpacity(intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(4)),
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
      ..color = color.withOpacity(base + range * _pulse)
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
      ..color = GameColors.player.withOpacity(0.25)
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
    final pulse = 1.0 + 0.08 * _pulseFast;
    final radius = tileSize * 0.32 * pulse;

    final glowPaint = Paint()
      ..color = GameColors.playerGlow.withOpacity(0.5 + 0.4 * _pulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + 6 * _pulse);
    canvas.drawCircle(center, radius + 6 + 2 * _pulse, glowPaint);

    final outerGlow = Paint()
      ..color = GameColors.player.withOpacity(0.15 + 0.15 * _pulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, radius + 10, outerGlow);

    final paint = Paint()..color = GameColors.player;
    canvas.drawCircle(center, radius, paint);

    // Inner highlight
    final highlight = Paint()..color = Colors.white.withOpacity(0.4);
    canvas.drawCircle(
      center + Offset(-radius * 0.2, -radius * 0.2),
      radius * 0.3,
      highlight,
    );
  }

  void _drawClone(Canvas canvas, int x, int y) {
    final center = Offset(
      x * tileSize + tileSize / 2,
      y * tileSize + tileSize / 2,
    );
    final paint = Paint()
      ..color = GameColors.clone.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, tileSize * 0.28, paint);
  }

  void _drawKey(Canvas canvas, Rect rect) {
    final paint = Paint()..color = GameColors.key;
    canvas.drawCircle(
      Offset(rect.center.dx, rect.center.dy - 2),
      tileSize * 0.15,
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(rect.center.dx, rect.center.dy + 6),
        width: 4,
        height: tileSize * 0.2,
      ),
      paint,
    );
    _drawPulsingGlow(canvas, rect, GameColors.key, base: 0.4, range: 0.45);
  }

  void _drawGoal(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = GameColors.goal.withOpacity(0.35 + 0.35 * _pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 + _pulse;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(4)),
      paint,
    );
    _drawPulsingGlow(canvas, rect, GameColors.goal, base: 0.1, range: 0.25, blur: 6);
  }

  void _drawMirror(Canvas canvas, Rect rect, bool slash) {
    final paint = Paint()
      ..color = GameColors.mirror
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    if (slash) {
      canvas.drawLine(rect.bottomLeft, rect.topRight, paint);
    } else {
      canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
    }
    _drawGlow(canvas, rect, GameColors.mirror, 0.3);
  }

  void _drawLaserEmitter(Canvas canvas, Rect rect) {
    final paint = Paint()..color = GameColors.laser;
    canvas.drawCircle(rect.center, tileSize * 0.2 * (1 + 0.06 * _pulseFast), paint);
    _drawPulsingGlow(canvas, rect, GameColors.laser, base: 0.5, range: 0.45, blur: 12);
  }

  void _drawSwitch(Canvas canvas, Rect rect, Color color, bool isOn) {
    final paint = Paint()
      ..color = isOn ? color : color.withOpacity(0.4);
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
      ..color = GameColors.ice.withOpacity(0.6)
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

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.animationPhase != animationPhase ||
      oldDelegate.displayPlayerX != displayPlayerX ||
      oldDelegate.displayPlayerY != displayPlayerY;
}
