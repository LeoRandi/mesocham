import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Bottom layer of the menu: a changing color field and large visual motif.
class MenuDestinationBackdrop extends StatelessWidget {
  const MenuDestinationBackdrop({
    super.key,
    required this.accent,
    required this.icon,
  });

  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(accent, AppColors.earth, 0.35)!,
              Color.lerp(accent, AppColors.ink, 0.72)!,
              AppColors.ink,
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -90,
              top: -120,
              child: _BackdropOrb(
                size: 430,
                color: AppColors.bone.withValues(alpha: 0.055),
              ),
            ),
            Positioned(
              right: 110,
              bottom: -180,
              child: _BackdropOrb(
                size: 520,
                color: accent.withValues(alpha: 0.1),
              ),
            ),
            Align(
              alignment: const Alignment(0.72, -0.16),
              child: Icon(
                icon,
                size: 270,
                color: AppColors.bone.withValues(alpha: 0.82),
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 34,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Second menu layer: the fixed dark navigation panel and its jagged edge.
class MenuLeftPanel extends StatelessWidget {
  const MenuLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        painter: _MenuLeftPanelPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _MenuLeftPanelPainter extends CustomPainter {
  const _MenuLeftPanelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final edgePoints = _edgePoints(size);
    final edge = Path()..moveTo(edgePoints.first.dx, edgePoints.first.dy);
    for (final point in edgePoints.skip(1)) {
      edge.lineTo(point.dx, point.dy);
    }
    final panel = Path()
      ..moveTo(0, 0)
      ..lineTo(edgePoints.first.dx, edgePoints.first.dy);
    for (final point in edgePoints.skip(1)) {
      panel.lineTo(point.dx, point.dy);
    }
    panel
      ..lineTo(0, size.height)
      ..close();

    final panelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.deepEarth, AppColors.ink],
      ).createShader(bounds);
    canvas.drawPath(panel, panelPaint);

    canvas.save();
    canvas.clipPath(panel);
    final speckPaint = Paint()..color = AppColors.sand.withValues(alpha: 0.055);
    for (var index = 0; index < 34; index++) {
      final x = (index * 83.0) % (size.width * 0.62);
      final y = (index * index * 31.0) % size.height;
      canvas.drawCircle(Offset(x, y), 1.3 + (index % 4).toDouble(), speckPaint);
    }
    canvas.restore();

    final edgePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(5, size.width * 0.0045)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(edge, edgePaint);

    final glowPaint = Paint()
      ..color = AppColors.bone.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(edge, glowPaint);
  }

  List<Offset> _edgePoints(Size size) {
    final width = size.width;
    final height = size.height;
    return [
      Offset(width * 0.61, 0),
      Offset(width * 0.625, height * 0.08),
      Offset(width * 0.612, height * 0.15),
      Offset(width * 0.64, height * 0.23),
      Offset(width * 0.625, height * 0.31),
      Offset(width * 0.66, height * 0.4),
      Offset(width * 0.645, height * 0.49),
      Offset(width * 0.68, height * 0.59),
      Offset(width * 0.668, height * 0.68),
      Offset(width * 0.695, height * 0.77),
      Offset(width * 0.688, height * 0.86),
      Offset(width * 0.72, height),
    ];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
