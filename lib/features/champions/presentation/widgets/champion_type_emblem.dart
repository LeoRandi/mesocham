import 'package:flutter/material.dart';

import '../../domain/entities/champion.dart';

class ChampionTypeEmblem extends StatelessWidget {
  const ChampionTypeEmblem({
    super.key,
    required this.type,
    required this.size,
    this.shadows = const [],
  });

  static const assetPaths = [
    'assets/images/jaws.png',
    'assets/images/nest.png',
    'assets/images/wings.png',
    'assets/images/plates.png',
    'assets/images/claws.png',
    'assets/images/titan.png',
    'assets/images/water.png',
    'assets/images/crown.png',
  ];

  static String assetPathFor(ChampionType type) => switch (type) {
    ChampionType.jaw => 'assets/images/jaws.png',
    ChampionType.nest => 'assets/images/nest.png',
    ChampionType.wings => 'assets/images/wings.png',
    ChampionType.plates => 'assets/images/plates.png',
    ChampionType.claws => 'assets/images/claws.png',
    ChampionType.titan => 'assets/images/titan.png',
    ChampionType.water => 'assets/images/water.png',
    ChampionType.crown => 'assets/images/crown.png',
  };

  final ChampionType type;
  final double size;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: shadows),
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: Image.asset(
            assetPathFor(type),
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: 256,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
