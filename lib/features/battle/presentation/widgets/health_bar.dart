import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class HealthBar extends StatelessWidget {
  const HealthBar({
    super.key,
    required this.current,
    required this.maximum,
    required this.width,
    this.compact = false,
  });

  final int current;
  final int maximum;
  final double width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final target = maximum == 0 ? 0.0 : current / maximum;
    final height = compact ? 15.0 : 20.0;

    return Semantics(
      label: '$current of $maximum health points',
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF3B1514),
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: AppColors.bone, width: compact ? 1 : 1.5),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: target),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: value > 0.28
                            ? const [Color(0xFF2CBF5A), AppColors.health]
                            : const [Color(0xFFC92F2A), AppColors.danger],
                      ),
                    ),
                  ),
                );
              },
            ),
            Center(
              child: Text(
                '$current / $maximum',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 8 : 10,
                  fontWeight: FontWeight.w900,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
