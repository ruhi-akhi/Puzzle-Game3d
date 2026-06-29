import 'package:flutter/material.dart';
import '../../game/models/level_data.dart';
import '../../game/services/level_loader.dart';
import '../../game/services/progress_service.dart';
import '../../theme/game_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final completed = await ProgressService.getCompletedLevels();
    final stars = <int, int>{};
    for (var i = 1; i <= widget.world.levelCount; i++) {
      final id = ProgressService.levelId(widget.world.id, i);
      stars[id] = await ProgressService.getStars(id);
    }
    if (mounted) {
      setState(() {
        _completed = completed;
        _stars = stars;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GameColors.neonCyan),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.world.name.toUpperCase(),
          style: const TextStyle(
            color: GameColors.neonCyan,
            letterSpacing: 3,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: GridView.builder(
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

          return FutureBuilder<bool>(
            future: ProgressService.isLevelUnlocked(widget.world.id, levelNum),
            builder: (context, snapshot) {
              final unlocked = snapshot.data ?? (levelNum == 1 && widget.world.id == 1);
              return _LevelTile(
                levelNum: levelNum,
                unlocked: unlocked,
                completed: isCompleted,
                stars: stars,
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
          );
        },
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final int levelNum;
  final bool unlocked;
  final bool completed;
  final int stars;
  final VoidCallback? onTap;

  const _LevelTile({
    required this.levelNum,
    required this.unlocked,
    required this.completed,
    required this.stars,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = completed
        ? GameColors.doorOpen
        : unlocked
            ? GameColors.neonCyan
            : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: unlocked ? color.withOpacity(0.08) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(unlocked ? 0.5 : 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              const Icon(Icons.lock, color: Colors.grey, size: 24)
            else ...[
              Text(
                '$levelNum',
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (stars > 0)
                Text(
                  '⭐' * stars,
                  style: const TextStyle(fontSize: 10),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
