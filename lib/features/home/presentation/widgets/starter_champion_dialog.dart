import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../battle/domain/entities/champion.dart';
import '../../../battle/domain/entities/champion_preset.dart';
import '../../../battle/presentation/widgets/champion_type_emblem.dart';

class StarterChampionDialog extends StatelessWidget {
  const StarterChampionDialog({super.key, required this.champions})
    : assert(champions.length == 3);

  final List<ChampionPreset> champions;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 520;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 28,
          vertical: compact ? 12 : 24,
        ),
        child: Container(
          width: 900,
          padding: EdgeInsets.fromLTRB(
            compact ? 18 : 30,
            compact ? 16 : 25,
            compact ? 18 : 30,
            compact ? 17 : 28,
          ),
          decoration: BoxDecoration(
            color: AppColors.deepEarth,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.amber, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.62),
                blurRadius: 38,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: AppColors.amber.withValues(alpha: 0.13),
                blurRadius: 24,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CHOOSE YOUR FIRST CHAMPION',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.bone,
                    fontSize: compact ? 18 : null,
                    fontWeight: FontWeight.w900,
                    letterSpacing: compact ? 1 : 1.4,
                  ),
                ),
                SizedBox(height: compact ? 3 : 7),
                Text(
                  'Select a card to unlock it and begin your expedition.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.sand.withValues(alpha: 0.76),
                    fontSize: compact ? 10 : 13,
                  ),
                ),
                SizedBox(height: compact ? 12 : 22),
                SizedBox(
                  height: compact ? 154 : 224,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (
                        var index = 0;
                        index < champions.length;
                        index++
                      ) ...[
                        Expanded(
                          child: _StarterChoiceCard(
                            champion: champions[index],
                            compact: compact,
                            autofocus: index == 0,
                            onSelected: () =>
                                Navigator.of(context).pop(champions[index].id),
                          ),
                        ),
                        if (index != champions.length - 1)
                          SizedBox(width: compact ? 8 : 16),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarterChoiceCard extends StatefulWidget {
  const _StarterChoiceCard({
    required this.champion,
    required this.compact,
    required this.autofocus,
    required this.onSelected,
  });

  final ChampionPreset champion;
  final bool compact;
  final bool autofocus;
  final VoidCallback onSelected;

  @override
  State<_StarterChoiceCard> createState() => _StarterChoiceCardState();
}

class _StarterChoiceCardState extends State<_StarterChoiceCard> {
  var _hovered = false;
  var _focused = false;

  Color get _accent => switch (widget.champion.type) {
    ChampionType.jaw => AppColors.danger,
    ChampionType.crown => AppColors.amber,
    ChampionType.claws => const Color(0xFFC7C4C5),
    ChampionType.titan => const Color(0xFFA945B2),
    _ => AppColors.teal,
  };

  @override
  Widget build(BuildContext context) {
    final highlighted = _hovered || _focused;
    final accent = _accent;

    return Semantics(
      button: true,
      label: 'Select ${widget.champion.name}',
      child: AnimatedScale(
        scale: highlighted ? 1.025 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(accent, AppColors.deepEarth, 0.54)!,
                AppColors.ink,
              ],
            ),
            borderRadius: BorderRadius.circular(widget.compact ? 13 : 17),
            border: Border.all(
              color: highlighted ? AppColors.bone : accent,
              width: highlighted ? 2.5 : 1.7,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: highlighted ? 0.38 : 0.17),
                blurRadius: highlighted ? 20 : 10,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(widget.compact ? 13 : 17),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              autofocus: widget.autofocus,
              mouseCursor: SystemMouseCursors.click,
              onTap: widget.onSelected,
              onHover: (hovered) => setState(() => _hovered = hovered),
              onFocusChange: (focused) => setState(() => _focused = focused),
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              splashColor: accent.withValues(alpha: 0.2),
              child: Padding(
                padding: EdgeInsets.all(widget.compact ? 8 : 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChampionTypeEmblem(
                      type: widget.champion.type,
                      size: widget.compact ? 67 : 106,
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.46),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    SizedBox(height: widget.compact ? 7 : 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.champion.name.toUpperCase(),
                        maxLines: 1,
                        style: TextStyle(
                          color: AppColors.bone,
                          fontSize: widget.compact ? 11 : 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    SizedBox(height: widget.compact ? 4 : 7),
                    Text(
                      '${_typeLabel(widget.champion.type)}  /  ${_periodLabel(widget.champion.period)}',
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        color: accent,
                        fontSize: widget.compact ? 7 : 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _typeLabel(ChampionType type) => switch (type) {
    ChampionType.jaw => 'JAW',
    ChampionType.nest => 'NEST',
    ChampionType.wings => 'WINGS',
    ChampionType.plates => 'PLATES',
    ChampionType.claws => 'CLAWS',
    ChampionType.titan => 'TITAN',
    ChampionType.water => 'WATER',
    ChampionType.crown => 'CROWN',
  };

  String _periodLabel(MesozoicPeriod period) => switch (period) {
    MesozoicPeriod.triassic => 'TRIASSIC',
    MesozoicPeriod.jurassic => 'JURASSIC',
    MesozoicPeriod.cretaceous => 'CRETACEOUS',
    MesozoicPeriod.chimera => 'CHIMERA',
  };
}
