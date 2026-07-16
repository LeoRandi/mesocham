import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class MenuBackdrop extends StatelessWidget {
  const MenuBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _MenuBackdropPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MenuBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leftRect = Offset.zero & size;
    final leftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.deepEarth, AppColors.ink],
      ).createShader(leftRect);
    canvas.drawRect(leftRect, leftPaint);

    final splitX = size.width * 0.56;
    final rightPath = Path()
      ..moveTo(splitX, 0)
      ..lineTo(splitX + size.width * 0.025, size.height * 0.12)
      ..lineTo(splitX - size.width * 0.012, size.height * 0.25)
      ..lineTo(splitX + size.width * 0.035, size.height * 0.41)
      ..lineTo(splitX + size.width * 0.008, size.height * 0.57)
      ..lineTo(splitX + size.width * 0.055, size.height * 0.73)
      ..lineTo(splitX + size.width * 0.03, size.height * 0.87)
      ..lineTo(splitX + size.width * 0.075, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();

    final rightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7A3C24), Color(0xFF2A1811)],
      ).createShader(leftRect);
    canvas.drawPath(rightPath, rightPaint);

    final speckPaint = Paint()..color = AppColors.sand.withValues(alpha: 0.07);
    for (var i = 0; i < 30; i++) {
      final x = (i * 83.0) % size.width;
      final y = (i * i * 31.0) % size.height;
      canvas.drawCircle(Offset(x, y), 1.5 + (i % 4).toDouble(), speckPaint);
    }

    final fracturePaint = Paint()
      ..color = AppColors.bone.withValues(alpha: 0.74)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, size.width * 0.0022)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fracture = Path()
      ..moveTo(splitX, 0)
      ..lineTo(splitX + size.width * 0.025, size.height * 0.12)
      ..lineTo(splitX - size.width * 0.012, size.height * 0.25)
      ..lineTo(splitX + size.width * 0.035, size.height * 0.41)
      ..lineTo(splitX + size.width * 0.008, size.height * 0.57)
      ..lineTo(splitX + size.width * 0.055, size.height * 0.73)
      ..lineTo(splitX + size.width * 0.03, size.height * 0.87)
      ..lineTo(splitX + size.width * 0.075, size.height);
    canvas.drawPath(fracture, fracturePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FossilSeal extends StatelessWidget {
  const FossilSeal({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.ink.withValues(alpha: 0.58),
        border: Border.all(color: AppColors.amber, width: size * 0.035),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(
        Icons.travel_explore_rounded,
        size: size * 0.54,
        color: AppColors.bone,
      ),
    );
  }
}
