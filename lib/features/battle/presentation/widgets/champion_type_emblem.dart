import 'package:flutter/material.dart';

import '../../domain/entities/champion.dart';

class ChampionTypeEmblem extends StatelessWidget {
  const ChampionTypeEmblem({
    super.key,
    required this.type,
    required this.size,
    this.shadows = const [],
  });

  static const _sourceWidth = 1448.0;
  static const _sourceHeight = 2048.0;
  static const _cropExtent = 482.0;

  final ChampionType type;
  final double size;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    final (cropLeft, cropTop) = switch (type) {
      ChampionType.jaw => (81.5, 49.0),
      ChampionType.nest => (872.5, 49.0),
      ChampionType.water => (81.5, 553.5),
      ChampionType.wings => (872.5, 553.5),
      ChampionType.crown => (81.5, 1051.5),
      ChampionType.titan => (872.5, 1051.5),
      ChampionType.claws => (81.5, 1538.5),
      ChampionType.plates => (872.5, 1538.5),
    };
    final scale = size / _cropExtent;

    return DecoratedBox(
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: shadows),
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            minHeight: 0,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: Transform.translate(
              offset: Offset(-cropLeft * scale, -cropTop * scale),
              child: SizedBox(
                width: _sourceWidth * scale,
                height: _sourceHeight * scale,
                child: Image.asset(
                  'assets/images/champion_emblems.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
