import 'package:flutter/material.dart';
import '../../game/services/progress_service.dart';
import '../../theme/game_colors.dart';
import '../widgets/neon_button.dart';
import 'world_select_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _totalStars = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final stars = await ProgressService.getTotalStars();
    if (mounted) setState(() => _totalStars = stars);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [
                            GameColors.neonCyan,
                            GameColors.neonPink,
                            GameColors.neonPurple,
                            GameColors.neonCyan,
                          ],
                          stops: [
                            0,
                            _controller.value * 0.5,
                            _controller.value,
                            1,
                          ],
                        ).createShader(bounds);
                      },
                      child: const Text(
                        'ECHO\nLABYRINTH',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 8,
                          height: 1.2,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'A Dark Sci-Fi Puzzle Adventure',
                  style: TextStyle(
                    color: GameColors.hudText.withOpacity(0.6),
                    fontSize: 14,
                    letterSpacing: 4,
                  ),
                ),
                if (_totalStars > 0) ...[
                  const SizedBox(height: 16),
                  Text(
                    '⭐ $_totalStars Stars Collected',
                    style: const TextStyle(
                      color: GameColors.key,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 48),
                NeonButton(
                  label: 'PLAY',
                  icon: Icons.play_arrow,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorldSelectScreen(),
                      ),
                    ).then((_) => _loadProgress());
                  },
                ),
                const SizedBox(height: 16),
                NeonButton(
                  label: 'HOW TO PLAY',
                  icon: Icons.help_outline,
                  color: GameColors.neonPurple,
                  onPressed: () => _showHowToPlay(context),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Text(
              'Flutter + Flame | Android • Windows • Web',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GameColors.hudText.withOpacity(0.3),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return CustomPaint(
      size: Size.infinite,
      painter: _StarFieldPainter(),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        title: const Text('How to Play', style: TextStyle(color: GameColors.neonCyan)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎮 Use Arrow Keys or WASD to move', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Text('🔑 Collect keys to open doors', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Text('📦 Push boxes onto goals', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Text('🪞 Reflect lasers with mirrors', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Text('❄ Ice tiles make you slide', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Text('⚡ Limited moves — plan carefully!', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Text('⭐ Fewer moves = more stars', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('GOT IT', style: TextStyle(color: GameColors.neonCyan)),
          ),
        ],
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = GameColors.background;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final starPaint = Paint();
    for (var i = 0; i < 80; i++) {
      final x = (i * 137.5) % size.width;
      final y = (i * 251.3) % size.height;
      final brightness = (i % 5 + 1) / 5;
      starPaint.color = Colors.white.withOpacity(brightness * 0.3);
      canvas.drawCircle(Offset(x, y), (i % 3) + 0.5, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
