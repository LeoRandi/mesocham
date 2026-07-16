import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/champion.dart';

class ChampionCard extends StatelessWidget {
  const ChampionCard({
    super.key,
    required this.champion,
    required this.height,
    this.defeated = false,
  });

  final Champion champion;
  final double height;
  final bool defeated;

  @override
  Widget build(BuildContext context) {
    final width = height * 0.7;
    final compact = height < 125;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 9 : 14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: defeated
              ? const [Color(0xFF37312D), Color(0xFF171513)]
              : const [Color(0xFFA72B24), Color(0xFF4A1715)],
        ),
        border: Border.all(
          color: defeated ? Colors.white24 : AppColors.amber,
          width: compact ? 1.5 : 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: compact ? 7 : 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      foregroundDecoration: defeated
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(compact ? 9 : 14),
              color: Colors.black.withValues(alpha: 0.42),
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 7 : 12),
        child: Stack(
          children: [
            Positioned(
              top: height * 0.26,
              left: -width * 0.22,
              child: Icon(
                Icons.hexagon_outlined,
                color: AppColors.bone.withValues(alpha: 0.06),
                size: width * 1.4,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 5 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          champion.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.bone,
                            fontSize: compact ? 7.5 : 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        'ATK ${champion.attack}',
                        style: TextStyle(
                          color: AppColors.amber,
                          fontSize: compact ? 6.5 : 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 2 : 5),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ChampionEmblem(defeated: defeated),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 2 : 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CardTag(
                        label: _typeLabel(champion.type),
                        compact: compact,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          _periodLabel(champion.period),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: AppColors.sand,
                            fontSize: compact ? 5.2 : 7.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _periodLabel(MesozoicPeriod period) => switch (period) {
    MesozoicPeriod.triassic => 'TRIASSIC',
    MesozoicPeriod.jurassic => 'JURASSIC',
    MesozoicPeriod.cretaceous => 'CRETACEOUS',
  };

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
}

class ChampionEmblem extends StatelessWidget {
  const ChampionEmblem({super.key, this.defeated = false});

  final bool defeated;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;

        return ClipOval(
          child: ColorFiltered(
            colorFilter: defeated
                ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: 0,
                minHeight: 0,
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: SizedBox(
                  width: size * (1448 / 520),
                  height: size * (2048 / 520),
                  child: Image.asset(
                    'assets/images/champion_emblems.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CardTag extends StatelessWidget {
  const _CardTag({required this.label, required this.compact});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 3 : 5,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.amber,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.ink,
          fontSize: compact ? 5.8 : 7.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class MiniChampionCard extends StatelessWidget {
  const MiniChampionCard({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.7,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.earth,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.sand.withValues(alpha: 0.65)),
      ),
      padding: const EdgeInsets.all(3),
      child: const Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: ChampionEmblem(),
        ),
      ),
    );
  }
}
