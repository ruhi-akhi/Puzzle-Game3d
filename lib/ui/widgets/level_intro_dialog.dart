import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/game_colors.dart';
import '../../theme/world_theme.dart';

/// Animated popup shown at level start with objective / hint text.
Future<void> showLevelIntroDialog(
  BuildContext context, {
  required int world,
  required int level,
  required String levelName,
  required String hint,
  WorldTheme theme = WorldTheme.fallback,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Level intro',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (ctx, anim1, anim2) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: _IntroCard(
            world: world,
            level: level,
            levelName: levelName,
            hint: hint,
            theme: theme,
            onDismiss: () => Navigator.of(ctx).pop(),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return Transform.scale(
        scale: 0.85 + curve.value * 0.15,
        child: Opacity(opacity: anim.value, child: child),
      );
    },
  );
}

class _IntroCard extends StatefulWidget {
  final int world;
  final int level;
  final String levelName;
  final String hint;
  final WorldTheme theme;
  final VoidCallback onDismiss;

  const _IntroCard({
    required this.world,
    required this.level,
    required this.levelName,
    required this.hint,
    required this.theme,
    required this.onDismiss,
  });

  @override
  State<_IntroCard> createState() => _IntroCardState();
}

class _IntroCardState extends State<_IntroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.theme.accent;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = 0.15 + _pulse.value * 0.15;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF111827).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: 0.6 + glow),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: glow),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.theme.moodName,
                style: GoogleFonts.orbitron(
                  color: accent.withValues(alpha: 0.7),
                  fontSize: 11,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'WORLD ${widget.world} — ${widget.level}',
                style: GoogleFonts.orbitron(
                  color: accent,
                  fontSize: 14,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.levelName.toUpperCase(),
                style: GoogleFonts.orbitron(
                  color: GameColors.hudText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: GameColors.key.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: GameColors.key.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.hint,
                        style: GoogleFonts.exo2(
                          color: GameColors.key.withValues(alpha: 0.95),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Earn up to 3★ — fewer moves = more stars!',
                style: GoogleFonts.exo2(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: widget.onDismiss,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  side: BorderSide(color: accent.withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'START',
                  style: GoogleFonts.orbitron(
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
