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
  @override
  void initState() {
    super.initState();
    ProgressService.syncFromStars();
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: worlds.length,
        itemBuilder: (context, index) {
          final world = worlds[index];
          return _WorldCard(
            key: ValueKey('world_${world.id}'),
            world: world,
          );
        },
      ),
    );
  }
}

class _WorldCard extends StatefulWidget {
  final WorldInfo world;
  const _WorldCard({super.key, required this.world});

  @override
  State<_WorldCard> createState() => _WorldCardState();
}

class _WorldCardState extends State<_WorldCard> {
  bool _unlocked = false;
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    ProgressService.syncFromStars().then((_) => _refresh());
  }

  Future<void> _refresh() async {
    final unlocked = await ProgressService.isWorldUnlocked(widget.world.id);
    final count = await ProgressService.getWorldCompletedCount(widget.world.id);
    if (mounted) {
      setState(() {
        _unlocked = unlocked;
        _completedCount = count;
      });
    }
  }

  Color get _worldColor {
    switch (widget.world.id) {
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
        onTap: _unlocked
            ? () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LevelSelectScreen(world: widget.world),
                  ),
                );
                _refresh();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _unlocked
                ? _worldColor.withOpacity(0.08)
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _unlocked
                  ? _worldColor.withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
              width: 2,
            ),
            boxShadow: _unlocked
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
                    '${widget.world.id}',
                    style: TextStyle(
                      color: _unlocked ? _worldColor : Colors.grey,
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
                      widget.world.name,
                      style: TextStyle(
                        color: _unlocked ? GameColors.hudText : Colors.grey,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.world.mechanic,
                      style: TextStyle(
                        color: _worldColor.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_completedCount / ${widget.world.levelCount} completed',
                      style: TextStyle(
                        color: GameColors.hudText.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _unlocked ? Icons.arrow_forward_ios : Icons.lock,
                color: _unlocked ? _worldColor : Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
