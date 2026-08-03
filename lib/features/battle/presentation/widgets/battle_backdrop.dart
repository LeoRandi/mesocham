import 'package:flutter/material.dart';

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
  static const _background = Color(0xFFB78B6C);
  static const _gold = Color(0xFFFFD000);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = _background);

    final goldPaint = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      goldPaint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height / 3,
      goldPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
