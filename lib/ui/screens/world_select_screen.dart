import 'package:flutter/material.dart';
import '../../game/models/level_data.dart';
import '../../game/services/progress_service.dart';
import '../../theme/game_colors.dart';
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GameColors.neonCyan),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SELECT WORLD',
          style: TextStyle(
            color: GameColors.neonCyan,
            letterSpacing: 3,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
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

  Color get _worldColor {
    switch (world.id) {
      case 1:
        return GameColors.neonCyan;
      case 2:
        return GameColors.laser;
      case 3:
        return GameColors.ice;
      case 4:
        return GameColors.clone;
      case 5:
        return GameColors.gravity;
      default:
        return GameColors.neonPink;
    }
  }

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
                ? _worldColor.withOpacity(0.08)
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unlocked
                  ? _worldColor.withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
              width: 2,
            ),
            boxShadow: unlocked
                ? [BoxShadow(color: _worldColor.withOpacity(0.2), blurRadius: 12)]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _worldColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${world.id}',
                    style: TextStyle(
                      color: unlocked ? _worldColor : Colors.grey,
                      fontSize: 24,
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
                      style: TextStyle(
                        color: unlocked ? GameColors.hudText : Colors.grey,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      world.mechanic,
                      style: TextStyle(
                        color: _worldColor.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedCount / ${world.levelCount} completed',
                      style: TextStyle(
                        color: unlocked
                            ? GameColors.doorOpen.withOpacity(0.8)
                            : GameColors.hudText.withOpacity(0.5),
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
