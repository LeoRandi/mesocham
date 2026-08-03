import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum _PaletteExpansion { none, fight, swap, speciesCards }

class BattleControls extends StatelessWidget {
  const BattleControls({
    super.key,
    required this.onFight,
    required this.onSpeciesCards,
    required this.onSwap,
    required this.fightEnabled,
    required this.speciesCardsEnabled,
    required this.swapEnabled,
    required this.focusNodes,
    required this.canFocus,
    this.expandedFight = false,
    this.expandedSwap = false,
    this.expandedSpeciesCards = false,
    this.expansionProgress = 1,
    this.actionKeyPrefix = 'battle-action',
    this.dimDisabledActions = true,
  }) : assert(focusNodes.length == 3),
       assert(
         !(expandedFight && expandedSwap) &&
             !(expandedFight && expandedSpeciesCards) &&
             !(expandedSwap && expandedSpeciesCards),
       );

  static const expandedFightWidthFactor = 1.18;
  static const expandedFightHeightFactor = 1.18;
  static const expandedSwapHeightFactor = 1.24;
  static const expandedSwapWidthFactor = (1 + expandedSwapHeightFactor) / 2;
  static const expandedSpeciesCardsWidthFactor = 1.24;
  static const expandedSpeciesCardsHeightFactor =
      (1 + expandedSpeciesCardsWidthFactor) / 2;

  final VoidCallback onFight;
  final VoidCallback onSpeciesCards;
  final VoidCallback onSwap;
  final bool fightEnabled;
  final bool speciesCardsEnabled;
  final bool swapEnabled;
  final List<FocusNode?> focusNodes;
  final bool canFocus;
  final bool expandedFight;
  final bool expandedSwap;
  final bool expandedSpeciesCards;
  final double expansionProgress;
  final String actionKeyPrefix;
  final bool dimDisabledActions;

  @override
  Widget build(BuildContext context) {
    final expansion = expandedFight
        ? _PaletteExpansion.fight
        : expandedSwap
        ? _PaletteExpansion.swap
        : expandedSpeciesCards
        ? _PaletteExpansion.speciesCards
        : _PaletteExpansion.none;
    return AspectRatio(
      aspectRatio: expansion == _PaletteExpansion.swap
          ? expandedSwapWidthFactor / expandedSwapHeightFactor
          : expansion == _PaletteExpansion.speciesCards
          ? expandedSpeciesCardsWidthFactor / expandedSpeciesCardsHeightFactor
          : 1,
      child: CustomPaint(
        painter: _ActionPalettePainter(
          expansion: expansion,
          progress: expansionProgress,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _TriangleAction(
              label: 'FIGHT',
              enabled: fightEnabled,
              onTap: onFight,
              focusNode: focusNodes[0],
              canFocus: canFocus,
              shortcutNumber: 1,
              actionKeyPrefix: actionKeyPrefix,
              dimWhenDisabled: dimDisabledActions,
              clipper: _FightTriangleClipper(
                expansion: expansion,
                progress: expansionProgress,
              ),
              content: _FightActionContent(
                expansion: expansion,
                progress: expansionProgress,
              ),
            ),
            _TriangleAction(
              label: 'SPECIES CARDS',
              enabled: speciesCardsEnabled,
              onTap: onSpeciesCards,
              focusNode: focusNodes[1],
              canFocus: canFocus,
              shortcutNumber: 2,
              actionKeyPrefix: actionKeyPrefix,
              dimWhenDisabled: dimDisabledActions,
              clipper: _SpeciesTriangleClipper(
                expansion: expansion,
                progress: expansionProgress,
              ),
              content: _SpeciesActionContent(
                expansion: expansion,
                progress: expansionProgress,
              ),
            ),
            _TriangleAction(
              label: 'SWAP',
              enabled: swapEnabled,
              onTap: onSwap,
              focusNode: focusNodes[2],
              canFocus: canFocus,
              shortcutNumber: 3,
              actionKeyPrefix: actionKeyPrefix,
              dimWhenDisabled: dimDisabledActions,
              clipper: _SwapTriangleClipper(
                expansion: expansion,
                progress: expansionProgress,
              ),
              content: _SwapActionContent(
                expansion: expansion,
                progress: expansionProgress,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TriangleAction extends StatefulWidget {
  const _TriangleAction({
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.focusNode,
    required this.canFocus,
    required this.shortcutNumber,
    required this.actionKeyPrefix,
    required this.dimWhenDisabled,
    required this.clipper,
    required this.content,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final bool canFocus;
  final int shortcutNumber;
  final String actionKeyPrefix;
  final bool dimWhenDisabled;
  final CustomClipper<Path> clipper;
  final Widget content;

  @override
  State<_TriangleAction> createState() => _TriangleActionState();
}

class _TriangleActionState extends State<_TriangleAction> {
  bool _focused = false;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        (event.logicalKey != LogicalKeyboardKey.enter &&
            event.logicalKey != LogicalKeyboardKey.space)) {
      return KeyEventResult.ignored;
    }
    if (widget.enabled) widget.onTap();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: Focus(
        key: ValueKey('${widget.actionKeyPrefix}-${widget.shortcutNumber}'),
        focusNode: widget.focusNode,
        canRequestFocus: widget.canFocus && widget.focusNode != null,
        onFocusChange: (focused) => setState(() => _focused = focused),
        onKeyEvent: _handleKeyEvent,
        child: ClipPath(
          clipper: widget.clipper,
          child: Material(
            color: _focused
                ? Colors.white.withValues(alpha: 0.24)
                : Colors.transparent,
            child: InkWell(
              canRequestFocus: false,
              onTap: widget.enabled
                  ? () {
                      widget.focusNode?.requestFocus();
                      widget.onTap();
                    }
                  : null,
              overlayColor: WidgetStatePropertyAll(
                Colors.white.withValues(alpha: 0.18),
              ),
              child: Opacity(
                opacity: widget.enabled || !widget.dimWhenDisabled ? 1 : 0.42,
                child: widget.content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteGeometry {
  const _PaletteGeometry({
    required this.size,
    required this.baseSide,
    required this.baseLeft,
    required this.baseTop,
    required this.progress,
  });

  factory _PaletteGeometry.forSize(
    Size size,
    _PaletteExpansion expansion,
    double progress,
  ) {
    final amount = progress.clamp(0.0, 1.0);
    final targetWidthFactor = switch (expansion) {
      _PaletteExpansion.none => 1.0,
      _PaletteExpansion.fight => BattleControls.expandedFightWidthFactor,
      _PaletteExpansion.swap => BattleControls.expandedSwapWidthFactor,
      _PaletteExpansion.speciesCards =>
        BattleControls.expandedSpeciesCardsWidthFactor,
    };
    final targetHeightFactor = switch (expansion) {
      _PaletteExpansion.none => 1.0,
      _PaletteExpansion.fight => BattleControls.expandedFightHeightFactor,
      _PaletteExpansion.swap => BattleControls.expandedSwapHeightFactor,
      _PaletteExpansion.speciesCards =>
        BattleControls.expandedSpeciesCardsHeightFactor,
    };
    final widthFactor = 1 + (targetWidthFactor - 1) * amount;
    final heightFactor = 1 + (targetHeightFactor - 1) * amount;
    final baseSide = switch (expansion) {
      _PaletteExpansion.none => size.shortestSide,
      _PaletteExpansion.fight => size.width / widthFactor,
      _PaletteExpansion.swap => size.height / heightFactor,
      _PaletteExpansion.speciesCards => size.width / widthFactor,
    };
    return _PaletteGeometry(
      size: size,
      baseSide: baseSide,
      baseLeft: (size.width - baseSide) / 2,
      baseTop: (size.height - baseSide) / 2,
      progress: amount,
    );
  }

  final Size size;
  final double baseSide;
  final double baseLeft;
  final double baseTop;
  final double progress;

  Offset get center => Offset(size.width / 2, size.height / 2);
  Rect get baseRect => Rect.fromLTWH(baseLeft, baseTop, baseSide, baseSide);

  Path get fightPath => Path()
    ..moveTo(baseLeft, baseTop)
    ..lineTo(baseLeft + baseSide, baseTop)
    ..lineTo(baseLeft, baseTop + baseSide)
    ..close();

  Path get expandedFightPath => Path()
    ..moveTo(baseLeft * (1 - progress), baseTop * (1 - progress))
    ..lineTo(
      baseRect.right + (size.width - baseRect.right) * progress,
      baseTop * (1 - progress),
    )
    ..lineTo(
      baseLeft * (1 - progress),
      baseRect.bottom + (size.height - baseRect.bottom) * progress,
    )
    ..close();

  Path get swapPath => Path()
    ..moveTo(baseLeft + baseSide, baseTop)
    ..lineTo(baseLeft + baseSide, baseTop + baseSide)
    ..lineTo(center.dx, center.dy)
    ..close();

  Path get speciesPath => Path()
    ..moveTo(baseLeft, baseTop + baseSide)
    ..lineTo(baseLeft + baseSide, baseTop + baseSide)
    ..lineTo(center.dx, center.dy)
    ..close();

  Path get expandedSwapPath => Path()
    ..moveTo(
      baseRect.right + (size.width - baseRect.right) * progress,
      baseTop * (1 - progress),
    )
    ..lineTo(
      baseRect.right + (size.width - baseRect.right) * progress,
      baseRect.bottom + (size.height - baseRect.bottom) * progress,
    )
    ..lineTo(center.dx, center.dy)
    ..close();

  Path get expandedSpeciesPath => Path()
    ..moveTo(
      baseLeft * (1 - progress),
      baseRect.bottom + (size.height - baseRect.bottom) * progress,
    )
    ..lineTo(
      baseRect.right + (size.width - baseRect.right) * progress,
      baseRect.bottom + (size.height - baseRect.bottom) * progress,
    )
    ..lineTo(center.dx, center.dy)
    ..close();
}

class _FightActionContent extends StatelessWidget {
  const _FightActionContent({required this.expansion, required this.progress});

  final _PaletteExpansion expansion;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = _PaletteGeometry.forSize(
          constraints.biggest,
          expansion,
          progress,
        );
        final side = geometry.baseSide;
        final fightProgress = expansion == _PaletteExpansion.fight
            ? geometry.progress
            : 0.0;
        final iconLeft =
            (geometry.baseLeft + side * 0.09) * (1 - fightProgress) +
            side * 0.06 * fightProgress;
        final iconTop =
            (geometry.baseTop + side * 0.10) * (1 - fightProgress) +
            side * 0.06 * fightProgress;
        final labelLeft =
            (geometry.baseLeft + side * 0.05) * (1 - fightProgress) +
            side * 0.02 * fightProgress;
        final labelTop =
            (geometry.baseTop + side * 0.40) * (1 - fightProgress) +
            side * 0.38 * fightProgress;
        return Stack(
          children: [
            Positioned(
              left: iconLeft,
              top: iconTop,
              width: side * 0.32,
              height: side * 0.32,
              child: SvgPicture.asset(
                'assets/images/fight_icon.svg',
                semanticsLabel: 'Fight',
              ),
            ),
            Positioned(
              left: labelLeft,
              top: labelTop,
              width: side * 0.52,
              child: _ActionLabel(label: 'FIGHT', fontSize: side * 0.12),
            ),
          ],
        );
      },
    );
  }
}

class _SwapActionContent extends StatelessWidget {
  const _SwapActionContent({required this.expansion, required this.progress});

  final _PaletteExpansion expansion;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = _PaletteGeometry.forSize(
          constraints.biggest,
          expansion,
          progress,
        );
        final side = geometry.baseSide;
        final rightInset = expansion == _PaletteExpansion.swap
            ? (constraints.maxWidth - geometry.baseRect.right) *
                  (1 - geometry.progress)
            : constraints.maxWidth - geometry.baseRect.right;
        return Stack(
          children: [
            Positioned(
              right: rightInset + side * 0.04,
              top: geometry.baseTop + side * 0.35,
              width: side * 0.28,
              height: side * 0.28,
              child: Image.asset(
                'assets/images/swap_icon.png',
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned(
              right: rightInset + side * 0.015,
              top: geometry.baseTop + side * 0.62,
              width: side * 0.34,
              child: _ActionLabel(label: 'SWAP', fontSize: side * 0.09),
            ),
          ],
        );
      },
    );
  }
}

class _SpeciesActionContent extends StatelessWidget {
  const _SpeciesActionContent({
    required this.expansion,
    required this.progress,
  });

  final _PaletteExpansion expansion;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = _PaletteGeometry.forSize(
          constraints.biggest,
          expansion,
          progress,
        );
        final side = geometry.baseSide;
        final speciesExpanded = expansion == _PaletteExpansion.speciesCards;
        final speciesScale =
            1 +
            (BattleControls.expandedSpeciesCardsWidthFactor - 1) *
                geometry.progress;
        final iconLeft = speciesExpanded
            ? geometry.center.dx - side * 0.09
            : geometry.baseLeft + side * 0.41;
        final iconTop = speciesExpanded
            ? geometry.center.dy +
                  speciesScale *
                      (geometry.baseTop + side * 0.67 - geometry.center.dy)
            : geometry.baseTop + side * 0.67;
        final labelLeft = speciesExpanded
            ? geometry.center.dx - side * 0.25
            : geometry.baseLeft + side * 0.25;
        final bottomInset = speciesExpanded
            ? (constraints.maxHeight - geometry.baseRect.bottom) *
                      (1 - geometry.progress) +
                  side * 0.025
            : constraints.maxHeight - geometry.baseRect.bottom + side * 0.025;
        return Stack(
          children: [
            Positioned(
              left: iconLeft,
              top: iconTop,
              width: side * 0.18,
              height: side * 0.18,
              child: Image.asset(
                'assets/images/card_icon.png',
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned(
              left: labelLeft,
              bottom: bottomInset,
              width: side * 0.50,
              child: _ActionLabel(
                label: 'SPECIES\nCARDS',
                fontSize: side * 0.075,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionLabel extends StatelessWidget {
  const _ActionLabel({required this.label, required this.fontSize});

  final String label;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        height: 0.9,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _ActionPalettePainter extends CustomPainter {
  const _ActionPalettePainter({
    required this.expansion,
    required this.progress,
  });

  final _PaletteExpansion expansion;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = _PaletteGeometry.forSize(size, expansion, progress);

    final fightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2E9B45), Color(0xFFA8CF45)],
      ).createShader(Offset.zero & size);
    final swapPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF168CF1), Color(0xFF82C9F4)],
      ).createShader(Offset.zero & size);
    final speciesPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xFFFF4D3D), Color(0xFFE53B32)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(geometry.fightPath, fightPaint);
    canvas.drawPath(geometry.swapPath, swapPaint);
    canvas.drawPath(geometry.speciesPath, speciesPaint);

    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(geometry.baseRect, borderPaint);
    canvas.drawLine(
      geometry.baseRect.bottomLeft,
      geometry.baseRect.topRight,
      borderPaint,
    );
    canvas.drawLine(
      geometry.center,
      geometry.baseRect.bottomRight,
      borderPaint,
    );
    if (expansion == _PaletteExpansion.fight) {
      canvas.drawPath(geometry.expandedFightPath, fightPaint);
      canvas.drawPath(geometry.expandedFightPath, borderPaint);
    } else if (expansion == _PaletteExpansion.swap) {
      canvas.drawPath(geometry.expandedSwapPath, swapPaint);
      canvas.drawPath(geometry.expandedSwapPath, borderPaint);
    } else if (expansion == _PaletteExpansion.speciesCards) {
      canvas.drawPath(geometry.expandedSpeciesPath, speciesPaint);
      canvas.drawPath(geometry.expandedSpeciesPath, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ActionPalettePainter oldDelegate) =>
      oldDelegate.expansion != expansion || oldDelegate.progress != progress;
}

class _FightTriangleClipper extends CustomClipper<Path> {
  const _FightTriangleClipper({
    required this.expansion,
    required this.progress,
  });

  final _PaletteExpansion expansion;
  final double progress;

  @override
  Path getClip(Size size) {
    final geometry = _PaletteGeometry.forSize(size, expansion, progress);
    return expansion == _PaletteExpansion.fight
        ? geometry.expandedFightPath
        : geometry.fightPath;
  }

  @override
  bool shouldReclip(covariant _FightTriangleClipper oldClipper) =>
      oldClipper.expansion != expansion || oldClipper.progress != progress;
}

class _SwapTriangleClipper extends CustomClipper<Path> {
  const _SwapTriangleClipper({required this.expansion, required this.progress});

  final _PaletteExpansion expansion;
  final double progress;

  @override
  Path getClip(Size size) {
    final geometry = _PaletteGeometry.forSize(size, expansion, progress);
    return expansion == _PaletteExpansion.swap
        ? geometry.expandedSwapPath
        : geometry.swapPath;
  }

  @override
  bool shouldReclip(covariant _SwapTriangleClipper oldClipper) =>
      oldClipper.expansion != expansion || oldClipper.progress != progress;
}

class _SpeciesTriangleClipper extends CustomClipper<Path> {
  const _SpeciesTriangleClipper({
    required this.expansion,
    required this.progress,
  });

  final _PaletteExpansion expansion;
  final double progress;

  @override
  Path getClip(Size size) {
    final geometry = _PaletteGeometry.forSize(size, expansion, progress);
    return expansion == _PaletteExpansion.speciesCards
        ? geometry.expandedSpeciesPath
        : geometry.speciesPath;
  }

  @override
  bool shouldReclip(covariant _SpeciesTriangleClipper oldClipper) =>
      oldClipper.expansion != expansion || oldClipper.progress != progress;
}
