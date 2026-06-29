import 'package:flutter/material.dart';
import '../../theme/game_colors.dart';

class NeonButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final IconData? icon;
  final bool small;

  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.icon,
    this.small = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? GameColors.neonCyan;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final glow = _hovered ? 0.6 : 0.2 + _controller.value * 0.2;
          return GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.small ? 16 : 32,
                vertical: widget.small ? 8 : 14,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(_hovered ? 0.15 : 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(glow),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: color, size: widget.small ? 16 : 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: color,
                      fontSize: widget.small ? 12 : 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
