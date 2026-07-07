import 'package:flutter/material.dart';

/// Per-world neon accent theme. Keeps a single deep-dark base while swapping
/// only the accent tint per world so the clean minimalist look is preserved.
class WorldTheme {
  final String moodName;
  final Color accent;
  final Color accentAlt;
  final Color bgTop;
  final Color bgBottom;

  const WorldTheme({
    required this.moodName,
    required this.accent,
    required this.accentAlt,
    required this.bgTop,
    required this.bgBottom,
  });

  /// Positive feedback color (valid move).
  Color get success => accent;

  /// Negative feedback color (blocked move).
  Color get danger => const Color(0xFFFF3B5C);

  static const _themes = <int, WorldTheme>{
    // World 1 — calm "Electron Blue"
    1: WorldTheme(
      moodName: 'ELECTRON BLUE',
      accent: Color(0xFF00E5FF),
      accentAlt: Color(0xFF3B82F6),
      bgTop: Color(0xFF060B14),
      bgBottom: Color(0xFF0A1424),
    ),
    // World 2 — "Cyber Green"
    2: WorldTheme(
      moodName: 'CYBER GREEN',
      accent: Color(0xFF39FF88),
      accentAlt: Color(0xFF14B8A6),
      bgTop: Color(0xFF05100B),
      bgBottom: Color(0xFF0A1A14),
    ),
    // World 3 — cold "Glacier Violet"
    3: WorldTheme(
      moodName: 'GLACIER VIOLET',
      accent: Color(0xFF8B9DFF),
      accentAlt: Color(0xFF67E8F9),
      bgTop: Color(0xFF080A16),
      bgBottom: Color(0xFF10142A),
    ),
    // World 4 — "Spectral Purple"
    4: WorldTheme(
      moodName: 'SPECTRAL PURPLE',
      accent: Color(0xFFB14DFF),
      accentAlt: Color(0xFFE879F9),
      bgTop: Color(0xFF0C0616),
      bgBottom: Color(0xFF160A28),
    ),
    // World 5 — warm "Solar Amber"
    5: WorldTheme(
      moodName: 'SOLAR AMBER',
      accent: Color(0xFFFFB020),
      accentAlt: Color(0xFFFF7A45),
      bgTop: Color(0xFF140C04),
      bgBottom: Color(0xFF241407),
    ),
    // World 6 — challenging "Magma Red"
    6: WorldTheme(
      moodName: 'MAGMA RED',
      accent: Color(0xFFFF4D6D),
      accentAlt: Color(0xFFFF00AA),
      bgTop: Color(0xFF140509),
      bgBottom: Color(0xFF260A14),
    ),
  };

  static const WorldTheme fallback = WorldTheme(
    moodName: 'ECHO',
    accent: Color(0xFF00E5FF),
    accentAlt: Color(0xFF3B82F6),
    bgTop: Color(0xFF060B14),
    bgBottom: Color(0xFF0A1424),
  );

  static WorldTheme of(int world) => _themes[world] ?? fallback;
}
