import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../battle/presentation/widgets/battle_backdrop.dart';
import '../../../champions/domain/entities/battle_gesture.dart';
import '../../../champions/domain/entities/champion.dart';
import '../../../champions/domain/entities/champion_definition.dart';
import '../../../champions/domain/entities/champion_move.dart';
import '../../../champions/presentation/widgets/champion_card.dart';
import '../../../champions/presentation/widgets/champion_type_emblem.dart';

class ChampionInfoPage extends StatefulWidget {
  const ChampionInfoPage({
    super.key,
    required this.champion,
    required this.preset,
    required this.copyCount,
    required this.discovered,
  });

  final Champion champion;
  final ChampionDefinition preset;
  final int copyCount;
  final bool discovered;

  @override
  State<ChampionInfoPage> createState() => _ChampionInfoPageState();
}

class _ChampionInfoPageState extends State<ChampionInfoPage> {
  final _dossierScrollController = ScrollController();
  var _selectedMoveIndex = 0;

  void _goBack() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _dossierScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _goBack},
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                child: Transform.scale(
                  scale: 1.05,
                  child: const BattleBackdrop(),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x6BB86F49),
                      Color(0x52533322),
                      Color(0x8A2E1D14),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact =
                        constraints.maxHeight < 560 ||
                        constraints.maxWidth < 900;

                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 10 : 22,
                        compact ? 8 : 15,
                        compact ? 12 : 24,
                        compact ? 10 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _InfoHeader(
                            compact: compact,
                            championName: widget.discovered
                                ? widget.champion.name
                                : '???',
                            onBack: _goBack,
                          ),
                          SizedBox(height: compact ? 7 : 14),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: (constraints.maxWidth * 0.31)
                                      .clamp(190.0, 420.0)
                                      .toDouble(),
                                  child: _ChampionCardColumn(
                                    champion: widget.champion,
                                    copyCount: widget.copyCount,
                                    compact: compact,
                                    discovered: widget.discovered,
                                  ),
                                ),
                                SizedBox(width: compact ? 12 : 24),
                                Expanded(
                                  child: _ChampionDossier(
                                    champion: widget.champion,
                                    preset: widget.preset,
                                    selectedMoveIndex: _selectedMoveIndex,
                                    scrollController: _dossierScrollController,
                                    compact: compact,
                                    discovered: widget.discovered,
                                    onMoveSelected: (index) {
                                      setState(
                                        () => _selectedMoveIndex = index,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoHeader extends StatelessWidget {
  const _InfoHeader({
    required this.compact,
    required this.championName,
    required this.onBack,
  });

  final bool compact;
  final String championName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 40 : 50,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Back to Collection',
            iconSize: compact ? 21 : 27,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          SizedBox(width: compact ? 9 : 14),
          Container(
            width: compact ? 3 : 4,
            height: compact ? 24 : 31,
            decoration: BoxDecoration(
              color: AppColors.amber,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: compact ? 9 : 13),
          Expanded(
            child: Text(
              'CHAMPION ARCHIVE  /  ${championName.toUpperCase()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.bone,
                fontSize: compact ? 11 : 14,
                fontWeight: FontWeight.w900,
                letterSpacing: compact ? 1.5 : 2.1,
                shadows: const [
                  Shadow(
                    color: Color(0xB3130F0B),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChampionCardColumn extends StatelessWidget {
  const _ChampionCardColumn({
    required this.champion,
    required this.copyCount,
    required this.compact,
    required this.discovered,
  });

  final Champion champion;
  final int copyCount;
  final bool compact;
  final bool discovered;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final copyAreaHeight = compact ? 32.0 : 46.0;
        final availableCardHeight = math.max(
          120.0,
          constraints.maxHeight - copyAreaHeight,
        );
        final widthBoundHeight =
            constraints.maxWidth / ChampionCard.aspectRatio;
        final cardHeight = math.min(
          480.0,
          math.min(availableCardHeight, widthBoundHeight),
        );

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChampionCard(
              champion: champion,
              height: cardHeight,
              currentHealth: champion.maxHealth.toDouble(),
              maximumHealth: champion.maxHealth.toDouble(),
              portraitFit: BoxFit.contain,
              obscured: !discovered,
            ),
            SizedBox(height: compact ? 7 : 11),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 18,
                vertical: compact ? 5 : 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.72),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 9,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'YOU HAVE  x$copyCount',
                style: TextStyle(
                  color: copyCount > 0 ? AppColors.bone : AppColors.sand,
                  fontSize: compact ? 10 : 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: compact ? 1 : 1.5,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChampionDossier extends StatelessWidget {
  const _ChampionDossier({
    required this.champion,
    required this.preset,
    required this.selectedMoveIndex,
    required this.scrollController,
    required this.compact,
    required this.discovered,
    required this.onMoveSelected,
  });

  final Champion champion;
  final ChampionDefinition preset;
  final int selectedMoveIndex;
  final ScrollController scrollController;
  final bool compact;
  final bool discovered;
  final ValueChanged<int> onMoveSelected;

  @override
  Widget build(BuildContext context) {
    final selectedMove = champion.moves[selectedMoveIndex];
    final gap = compact ? 9.0 : 14.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 14 : 20),
      child: CustomPaint(
        painter: const _ParchmentPainter(),
        child: Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 27,
              compact ? 15 : 25,
              compact ? 20 : 31,
              compact ? 18 : 29,
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                color: AppColors.ink,
                fontSize: compact ? 10.5 : 13,
                height: 1.35,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    discovered ? preset.name.toUpperCase() : '???',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: compact ? 24 : 38,
                      height: 0.95,
                      fontWeight: FontWeight.w900,
                      letterSpacing: compact ? 0.8 : 1.2,
                    ),
                  ),
                  SizedBox(height: compact ? 5 : 8),
                  Text(
                    discovered
                        ? 'SPECIES  /  ${preset.scientificName}'
                        : 'SPECIES  /  ???',
                    style: TextStyle(
                      color: AppColors.deepEarth.withValues(alpha: 0.82),
                      fontSize: compact ? 12 : 17,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: gap),
                  Wrap(
                    spacing: compact ? 7 : 10,
                    runSpacing: compact ? 6 : 8,
                    children: [
                      _DossierChip(
                        label: discovered ? _typeLabel(champion.type) : '???',
                        compact: compact,
                        emblemType: discovered ? champion.type : null,
                        icon: discovered ? null : Icons.lock_rounded,
                      ),
                      _DossierChip(
                        label: discovered
                            ? _periodLabel(champion.period)
                            : '???',
                        compact: compact,
                        icon: Icons.history_edu_rounded,
                      ),
                      if (discovered &&
                          preset.family != null &&
                          preset.family!.trim().isNotEmpty)
                        _DossierChip(
                          label: preset.family!,
                          compact: compact,
                          icon: Icons.account_tree_rounded,
                        ),
                      _DossierChip(
                        label: discovered ? '${champion.maxHealth} HP' : '???',
                        compact: compact,
                        icon: Icons.favorite_rounded,
                      ),
                    ],
                  ),
                  SizedBox(height: gap),
                  const _InkDivider(),
                  SizedBox(height: gap),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacksCards = constraints.maxWidth < 520;
                      final cardWidth = stacksCards
                          ? constraints.maxWidth
                          : (constraints.maxWidth - gap) / 2;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _ParchmentFactCard(
                              title: 'DISCOVERY',
                              icon: Icons.explore_rounded,
                              body: discovered ? preset.discovery : '???',
                              compact: compact,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _ParchmentFactCard(
                              title: 'SIZE & WEIGHT',
                              icon: Icons.straighten_rounded,
                              body: discovered
                                  ? preset.estimatedSizeAndWeight
                                  : '???',
                              compact: compact,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: compact ? 14 : 22),
                  _SectionTitle(
                    title: 'MOVES',
                    icon: Icons.sports_mma_rounded,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 7 : 11),
                  Row(
                    children: [
                      for (
                        var index = 0;
                        index < champion.moves.length;
                        index++
                      )
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index == champion.moves.length - 1
                                  ? 0
                                  : compact
                                  ? 5
                                  : 8,
                            ),
                            child: _MoveTab(
                              move: champion.moves[index],
                              selected: selectedMoveIndex == index,
                              compact: compact,
                              obscured: !discovered,
                              onTap: () => onMoveSelected(index),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: compact ? 7 : 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _MoveDetails(
                      key: ValueKey(selectedMove.gesture),
                      move: selectedMove,
                      compact: compact,
                      obscured: !discovered,
                    ),
                  ),
                  SizedBox(height: compact ? 14 : 22),
                  _SectionTitle(
                    title: 'FIELD NOTES',
                    icon: Icons.auto_stories_rounded,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 7 : 11),
                  Container(
                    padding: EdgeInsets.all(compact ? 11 : 16),
                    decoration: BoxDecoration(
                      color: const Color(0x24FFFFFF),
                      borderRadius: BorderRadius.circular(compact ? 9 : 12),
                      border: Border.all(
                        color: AppColors.deepEarth.withValues(alpha: 0.34),
                      ),
                    ),
                    child: Text(
                      discovered ? preset.curiosity : '???',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: compact ? 10.5 : 13.5,
                        height: 1.48,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DossierChip extends StatelessWidget {
  const _DossierChip({
    required this.label,
    required this.compact,
    this.icon,
    this.emblemType,
  }) : assert(icon != null || emblemType != null);

  final String label;
  final bool compact;
  final IconData? icon;
  final ChampionType? emblemType;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 18.0 : 23.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 6 : 8,
        compact ? 4 : 5,
        compact ? 9 : 12,
        compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.deepEarth.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.deepEarth.withValues(alpha: 0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emblemType != null)
            ChampionTypeEmblem(type: emblemType!, size: iconSize)
          else
            Icon(icon, size: iconSize, color: AppColors.deepEarth),
          SizedBox(width: compact ? 5 : 7),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppColors.ink,
              fontSize: compact ? 8 : 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParchmentFactCard extends StatelessWidget {
  const _ParchmentFactCard({
    required this.title,
    required this.icon,
    required this.body,
    required this.compact,
  });

  final String title;
  final IconData icon;
  final String body;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(compact ? 9 : 12),
        border: Border.all(color: AppColors.deepEarth.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.deepEarth, size: compact ? 16 : 20),
              SizedBox(width: compact ? 6 : 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: compact ? 9 : 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 9),
          Text(
            body,
            style: TextStyle(
              color: AppColors.ink.withValues(alpha: 0.86),
              fontSize: compact ? 9.5 : 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.compact,
  });

  final String title;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.deepEarth, size: compact ? 19 : 24),
        SizedBox(width: compact ? 7 : 10),
        Text(
          title,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: compact ? 15 : 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(width: compact ? 8 : 12),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.deepEarth.withValues(alpha: 0.38),
          ),
        ),
      ],
    );
  }
}

class _MoveTab extends StatelessWidget {
  const _MoveTab({
    required this.move,
    required this.selected,
    required this.compact,
    required this.obscured,
    required this.onTap,
  });

  final ChampionMove move;
  final bool selected;
  final bool compact;
  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = obscured ? AppColors.deepEarth : _gestureColor(move.gesture);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(compact ? 8 : 11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 5 : 8,
            vertical: compact ? 7 : 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.24)
                : AppColors.deepEarth.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(compact ? 8 : 11),
            border: Border.all(
              color: selected
                  ? accent
                  : AppColors.deepEarth.withValues(alpha: 0.31),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                obscured ? Icons.lock_rounded : _gestureIcon(move.gesture),
                color: selected ? accent : AppColors.deepEarth,
                size: compact ? 18 : 24,
              ),
              SizedBox(height: compact ? 3 : 5),
              Text(
                obscured ? '???' : _gestureLabel(move.gesture),
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: compact ? 7.5 : 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoveDetails extends StatelessWidget {
  const _MoveDetails({
    super.key,
    required this.move,
    required this.compact,
    required this.obscured,
  });

  final ChampionMove move;
  final bool compact;
  final bool obscured;

  @override
  Widget build(BuildContext context) {
    final accent = obscured ? AppColors.deepEarth : _gestureColor(move.gesture);
    final potencyLabel = move.potency == move.potency.roundToDouble()
        ? move.potency.toStringAsFixed(0)
        : move.potency.toStringAsFixed(1);

    return Container(
      clipBehavior: Clip.antiAlias,
      constraints: BoxConstraints(minHeight: compact ? 76 : 108),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(compact ? 9 : 12),
        border: Border.all(color: accent.withValues(alpha: 0.65)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(compact ? 11 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      obscured ? '???' : move.name,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: compact ? 12 : 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: compact ? 5 : 8),
                    Text(
                      obscured ? '???' : move.description,
                      style: TextStyle(
                        color: AppColors.ink.withValues(alpha: 0.84),
                        fontSize: compact ? 9.5 : 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!obscured && move.effectTurns > 0) ...[
                      SizedBox(height: compact ? 5 : 8),
                      Text(
                        'Effect duration: ${move.effectTurns} turns',
                        style: TextStyle(
                          color: AppColors.deepEarth,
                          fontSize: compact ? 8.5 : 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _MovePowerPanel(
              potencyLabel: obscured ? '???' : potencyLabel,
              critical: !obscured && move.isCritical,
              color: accent,
              compact: compact,
              obscured: obscured,
            ),
          ],
        ),
      ),
    );
  }
}

class _MovePowerPanel extends StatelessWidget {
  const _MovePowerPanel({
    required this.potencyLabel,
    required this.critical,
    required this.color,
    required this.compact,
    required this.obscured,
  });

  final String potencyLabel;
  final bool critical;
  final Color color;
  final bool compact;
  final bool obscured;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: obscured
          ? 'Unknown move power'
          : '$potencyLabel power${critical ? ', critical move' : ''}',
      child: Container(
        width: compact ? 78 : 112,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          border: Border(
            left: BorderSide(
              color: color.withValues(alpha: 0.82),
              width: compact ? 1.5 : 2,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                potencyLabel,
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: compact ? 25 : 36,
                  height: 0.9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(height: compact ? 3 : 5),
            Text(
              'POWER',
              style: TextStyle(
                color: AppColors.ink.withValues(alpha: 0.72),
                fontSize: compact ? 8 : 11,
                fontWeight: FontWeight.w900,
                letterSpacing: compact ? 1 : 1.5,
              ),
            ),
            if (critical) ...[
              SizedBox(height: compact ? 6 : 9),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: compact ? 3 : 5),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.8),
                  ),
                ),
                child: Text(
                  'CRITICAL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: compact ? 6.5 : 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InkDivider extends StatelessWidget {
  const _InkDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.deepEarth.withValues(alpha: 0.62),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _ParchmentPainter extends CustomPainter {
  const _ParchmentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paperPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF0D49C), Color(0xFFE4BD76), Color(0xFFD6A866)],
        stops: [0, 0.58, 1],
      ).createShader(rect);
    canvas.drawRect(rect, paperPaint);

    final edgePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          AppColors.deepEarth.withValues(alpha: 0.2),
        ],
        stops: const [0.64, 1],
      ).createShader(rect);
    canvas.drawRect(rect, edgePaint);

    final stainPaint = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index < 18; index++) {
      final x = (index * 137.0 + index * index * 11) % size.width;
      final y = (index * 83.0 + index * index * 17) % size.height;
      final radius = 5.0 + (index % 5) * 4;
      stainPaint.color = AppColors.earth.withValues(
        alpha: 0.025 + (index % 3) * 0.012,
      );
      canvas.drawCircle(Offset(x, y), radius, stainPaint);
    }

    final fiberPaint = Paint()
      ..color = AppColors.deepEarth.withValues(alpha: 0.05)
      ..strokeWidth = 0.8;
    for (var index = 0; index < 22; index++) {
      final y = (index * 47.0 + 13) % size.height;
      final x = (index * 89.0) % size.width;
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(size.width, x + 36 + index % 4 * 9), y + 2),
        fiberPaint,
      );
    }

    final borderPaint = Paint()
      ..color = AppColors.deepEarth.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect.deflate(1), borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ParchmentPainter oldDelegate) => false;
}

String _typeLabel(ChampionType type) => switch (type) {
  ChampionType.jaw => 'Jaw',
  ChampionType.nest => 'Nest',
  ChampionType.wings => 'Wings',
  ChampionType.plates => 'Plates',
  ChampionType.claws => 'Claws',
  ChampionType.titan => 'Titan',
  ChampionType.water => 'Water',
  ChampionType.crown => 'Crown',
};

String _periodLabel(MesozoicPeriod period) => switch (period) {
  MesozoicPeriod.triassic => 'Triassic',
  MesozoicPeriod.jurassic => 'Jurassic',
  MesozoicPeriod.cretaceous => 'Cretaceous',
  MesozoicPeriod.chimera => 'Chimera',
};

String _gestureLabel(BattleGesture gesture) => switch (gesture) {
  BattleGesture.rock => 'ROCK',
  BattleGesture.paper => 'PAPER',
  BattleGesture.scissors => 'SCISSORS',
};

IconData _gestureIcon(BattleGesture gesture) => switch (gesture) {
  BattleGesture.rock => Icons.landscape_rounded,
  BattleGesture.paper => Icons.description_rounded,
  BattleGesture.scissors => Icons.content_cut_rounded,
};

Color _gestureColor(BattleGesture gesture) => switch (gesture) {
  BattleGesture.rock => AppColors.rock,
  BattleGesture.paper => AppColors.paper,
  BattleGesture.scissors => AppColors.scissors,
};
