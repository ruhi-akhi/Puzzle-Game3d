import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../game/models/level_data.dart';
import '../../game/services/progress_service.dart';
import '../../theme/game_colors.dart';
import '../../theme/world_theme.dart';
import '../widgets/scifi_background.dart';
import 'level_select_screen.dart';

class WorldSelectScreen extends StatefulWidget {
  const WorldSelectScreen({super.key});

  @override
  State<WorldSelectScreen> createState() => _WorldSelectScreenState();
}

class _WorldSelectScreenState extends State<WorldSelectScreen> {
  Map<int, bool> _unlocked = {};
  Map<int, int> _completed = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await ProgressService.syncFromStars();

    final unlocked = <int, bool>{};
    final completed = <int, int>{};

    for (final world in worlds) {
      unlocked[world.id] = await ProgressService.isWorldUnlocked(world.id);
      completed[world.id] = await ProgressService.getWorldCompletedCount(world.id);
    }

    if (mounted) {
      setState(() {
        _unlocked = unlocked;
        _completed = completed;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GameColors.neonCyan),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SELECT WORLD',
          style: GoogleFonts.orbitron(
            color: GameColors.neonCyan,
            letterSpacing: 3,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SciFiBackground(
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: GameColors.neonCyan),
                )
              : RefreshIndicator(
                  color: GameColors.neonCyan,
                  onRefresh: _loadAll,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: worlds.length,
                    itemBuilder: (context, index) {
                      final world = worlds[index];
                      final unlocked = _unlocked[world.id] ?? false;
                      final count = _completed[world.id] ?? 0;

                      return _WorldCard(
                        world: world,
                        unlocked: unlocked,
                        completedCount: count,
                        onTap: unlocked
                            ? () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LevelSelectScreen(world: world),
                                  ),
                                );
                                _loadAll();
                              }
                            : null,
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

class _WorldCard extends StatelessWidget {
  final WorldInfo world;
  final bool unlocked;
  final int completedCount;
  final VoidCallback? onTap;

  const _WorldCard({
    required this.world,
    required this.unlocked,
    required this.completedCount,
    this.onTap,
  });

  Color get _worldColor => WorldTheme.of(world.id).accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: unlocked
                ? _worldColor.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unlocked
                  ? _worldColor.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: unlocked
                ? [BoxShadow(color: _worldColor.withValues(alpha: 0.18), blurRadius: 16)]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _worldColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _worldColor.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    '${world.id}',
                    style: GoogleFonts.orbitron(
                      color: unlocked ? _worldColor : Colors.grey,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      world.name,
                      style: GoogleFonts.orbitron(
                        color: unlocked ? GameColors.hudText : Colors.grey,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      world.mechanic,
                      style: GoogleFonts.exo2(
                        color: _worldColor.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedCount / ${world.levelCount} completed',
                      style: GoogleFonts.exo2(
                        color: unlocked
                            ? GameColors.doorOpen.withValues(alpha: 0.8)
                            : GameColors.hudText.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                unlocked ? Icons.arrow_forward_ios : Icons.lock,
                color: unlocked ? _worldColor : Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
