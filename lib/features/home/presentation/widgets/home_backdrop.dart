import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class HomeBackdrop extends StatelessWidget {
  const HomeBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFC79761),
                  Color(0xFFB77C47),
                  Color(0xFF865335),
                ],
                stops: [0, 0.54, 1],
              ),
            ),
          ),
          CustomPaint(painter: _ScalePatternPainter()),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.05),
                radius: 0.72,
                colors: [
                  Color(0x00FFF3D5),
                  Color(0x18130F0B),
                  Color(0x99130F0B),
                ],
                stops: [0, 0.61, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x4D130F0B),
                  Color(0x00130F0B),
                  Color(0x66130F0B),
                ],
                stops: [0, 0.43, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScalePatternPainter extends CustomPainter {
  const _ScalePatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide / 9).clamp(30.0, 72.0).toDouble();
    final rowHeight = radius * 0.68;
    final strokeWidth = math.max(1.2, radius * 0.035);
    final outlinePaint = Paint()
      ..color = AppColors.deepEarth.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final highlightPaint = Paint()
      ..color = AppColors.sand.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, strokeWidth * 0.45);

    var row = -2;
    for (var y = -radius; y < size.height + radius; y += rowHeight) {
      final offset = row.isEven ? 0.0 : radius;
      for (
        var x = -radius * 2 + offset;
        x < size.width + radius * 2;
        x += radius * 2
      ) {
        final scaleRect = Rect.fromCenter(
          center: Offset(x, y),
          width: radius * 2,
          height: radius * 1.6,
        );
        canvas.drawArc(scaleRect, 0, math.pi, false, outlinePaint);
        canvas.drawArc(
          scaleRect.translate(0, strokeWidth * 1.6),
          0,
          math.pi,
          false,
          highlightPaint,
        );
      }
      row++;
    }

    final grainPaint = Paint()..color = AppColors.ink.withValues(alpha: 0.08);
    for (var index = 0; index < 90; index++) {
      final x = (index * 137.0 + index * index * 7.0) % size.width;
      final y = (index * 83.0 + index * index * 19.0) % size.height;
      final grainRadius = 0.7 + (index % 4) * 0.42;
      canvas.drawCircle(Offset(x, y), grainRadius, grainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScalePatternPainter oldDelegate) => false;
}
