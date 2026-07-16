import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class BattleBackdrop extends StatelessWidget {
  const BattleBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _BattleBackdropPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BattleBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF52331F), Color(0xFF21150F), Color(0xFF432A1D)],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.amber.withValues(alpha: 0.12),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: size.width * 0.42,
            ),
          );
    canvas.drawRect(rect, glowPaint);

    final stonePaint = Paint()
      ..color = AppColors.sand.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (var i = 0; i < 34; i++) {
      final x = (i * 149.0) % size.width;
      final y = (i * i * 47.0) % size.height;
      final radius = 8.0 + (i % 7) * 5;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: radius * 1.7,
          height: radius,
        ),
        stonePaint,
      );
    }

    final ringPaint = Paint()
      ..color = AppColors.bone.withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(14, size.width * 0.016);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      math.min(size.width, size.height) * 0.34,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
