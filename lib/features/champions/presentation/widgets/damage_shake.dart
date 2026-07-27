import 'package:flutter/material.dart';

class DamageShake extends StatefulWidget {
  const DamageShake({
    super.key,
    required this.trigger,
    required this.child,
    this.distance = 4,
  });

  final int trigger;
  final double distance;
  final Widget child;

  @override
  State<DamageShake> createState() => _DamageShakeState();
}

class _DamageShakeState extends State<DamageShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late Animation<double> _offset = _buildOffset();

  @override
  void initState() {
    super.initState();
    if (widget.trigger > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward(from: 0);
      });
    }
  }

  @override
  void didUpdateWidget(covariant DamageShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.distance != oldWidget.distance) {
      _offset = _buildOffset();
    }
    if (widget.trigger > 0 && widget.trigger != oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  Animation<double> _buildOffset() {
    final distance = widget.distance;
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -distance), weight: 12),
      TweenSequenceItem(
        tween: Tween(begin: -distance, end: distance),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: distance, end: -distance * 0.7),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -distance * 0.7, end: distance * 0.7),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: distance * 0.7, end: 0),
        weight: 18,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      child: widget.child,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_offset.value, 0),
          child: child,
        );
      },
    );
  }
}
