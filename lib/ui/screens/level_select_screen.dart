import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../game/models/level_data.dart';
import '../../game/services/level_loader.dart';
import '../../game/services/progress_service.dart';
import '../../theme/game_colors.dart';
import '../../theme/world_theme.dart';
import '../widgets/scifi_background.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  final WorldInfo world;
  const LevelSelectScreen({super.key, required this.world});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  Set<int> _completed = {};
  Map<int, int> _stars = {};
  Map<int, bool> _unlocked = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    await ProgressService.syncFromStars();
    final completed = await ProgressService.getCompletedLevels();
    final stars = <int, int>{};
    final unlocked = <int, bool>{};

    for (var i = 1; i <= widget.world.levelCount; i++) {
      final id = ProgressService.levelId(widget.world.id, i);
      stars[id] = await ProgressService.getStars(id);
      unlocked[i] = await ProgressService.isLevelUnlocked(widget.world.id, i);
    }

    if (mounted) {
      setState(() {
        _completed = completed;
        _stars = stars;
        _unlocked = unlocked;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = WorldTheme.of(widget.world.id);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.2),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.world.name.toUpperCase(),
          style: GoogleFonts.orbitron(
            color: theme.accent,
            letterSpacing: 3,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SciFiBackground(
        theme: theme,
        child: SafeArea(
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(color: theme.accent),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: widget.world.levelCount,
                  itemBuilder: (context, index) {
                    final levelNum = index + 1;
                    final levelId = ProgressService.levelId(widget.world.id, levelNum);
                    final isCompleted = _completed.contains(levelId);
                    final stars = _stars[levelId] ?? 0;
                    final unlocked = _unlocked[levelNum] ?? false;

                    return _LevelTile(
                      levelNum: levelNum,
                      unlocked: unlocked,
                      completed: isCompleted,
                      stars: stars,
                      accent: theme.accent,
                      onTap: unlocked
                          ? () async {
                              final level = await LevelLoader.loadLevel(
                                widget.world.id,
                                levelNum,
                              );
                              if (!context.mounted) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GameScreen(
                                    level: level,
                                    world: widget.world.id,
                                    levelIndex: levelNum,
                                  ),
                                ),
                              );
                              _loadProgress();
                            }
                          : null,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final int levelNum;
  final bool unlocked;
  final bool completed;
  final int stars;
  final Color accent;
  final VoidCallback? onTap;

  const _LevelTile({
    required this.levelNum,
    required this.unlocked,
    required this.completed,
    required this.stars,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = completed
        ? GameColors.doorOpen
        : unlocked
            ? accent
            : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: unlocked ? color.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: unlocked ? 0.5 : 0.2)),
          boxShadow: unlocked
              ? [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 12)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              const Icon(Icons.lock, color: Colors.grey, size: 24)
            else ...[
              Text(
                '$levelNum',
                style: GoogleFonts.orbitron(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (stars > 0)
                Text(
                  '★' * stars,
                  style: const TextStyle(fontSize: 12, color: GameColors.key),
                ),
              if (completed && stars == 0)
                const Icon(Icons.check, color: GameColors.doorOpen, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
