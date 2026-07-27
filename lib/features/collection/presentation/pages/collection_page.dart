import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../battle/presentation/widgets/battle_backdrop.dart';
import '../../../champions/domain/entities/champion.dart';
import '../../../champions/domain/repositories/champion_catalog.dart';
import '../../../champions/presentation/widgets/champion_card.dart';
import '../../../home/data/player_preferences.dart';
import 'champion_info_page.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({
    super.key,
    required this.catalog,
    required this.playerPreferences,
  });

  final ChampionCatalog catalog;
  final PlayerPreferences playerPreferences;

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  Map<String, int> _championCounts = const {};
  Set<String> _discoveredChampionIds = const {};
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  Future<void> _loadCollection() async {
    try {
      final counts = await widget.playerPreferences
          .getChampionCollectionCounts();
      final discoveredIds = await widget.playerPreferences
          .getDiscoveredChampionIds();
      if (!mounted) return;
      setState(() {
        _championCounts = counts;
        _discoveredChampionIds = discoveredIds;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  void _openChampionInfo(
    Champion champion,
    int copyCount, {
    required bool discovered,
  }) {
    final definition = widget.catalog.definitionById(champion.id);
    if (definition == null) return;

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        settings: RouteSettings(name: '/collection/${champion.id}'),
        transitionDuration: const Duration(milliseconds: 330),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChampionInfoPage(
              champion: champion,
              preset: definition,
              copyCount: copyCount,
              discovered: discovered,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.045, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
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
                imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: Transform.scale(
                  scale: 1.04,
                  child: const BattleBackdrop(),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x5C2E1D14),
                      Color(0x2E9A5134),
                      Color(0xB3130F0B),
                    ],
                    stops: [0, 0.48, 1],
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact =
                        constraints.maxHeight < 560 ||
                        constraints.maxWidth < 900;
                    final cardHeight = compact
                        ? ChampionCard.compactHeight
                        : ChampionCard.largeHeight;
                    final cardWidth = cardHeight * ChampionCard.aspectRatio;
                    final rowExtent =
                        cardHeight + (compact ? 27 : 36) + (compact ? 12 : 20);
                    final champions = [
                      ...widget.catalog.champions.where(
                        (champion) => (_championCounts[champion.id] ?? 0) > 0,
                      ),
                      ...widget.catalog.champions.where(
                        (champion) => (_championCounts[champion.id] ?? 0) == 0,
                      ),
                    ];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CollectionHeader(
                          compact: compact,
                          loading: _loading,
                          onBack: _goBack,
                        ),
                        Expanded(
                          child: GridView.builder(
                            scrollCacheExtent: ScrollCacheExtent.pixels(
                              rowExtent,
                            ),
                            padding: EdgeInsets.fromLTRB(
                              compact ? 18 : 34,
                              compact ? 8 : 16,
                              compact ? 18 : 34,
                              compact ? 20 : 32,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent:
                                      cardWidth + (compact ? 24 : 38),
                                  mainAxisExtent:
                                      cardHeight + (compact ? 27 : 36),
                                  crossAxisSpacing: compact ? 8 : 14,
                                  mainAxisSpacing: compact ? 12 : 20,
                                ),
                            itemCount: champions.length,
                            itemBuilder: (context, index) {
                              final champion = champions[index];
                              final storedCount =
                                  _championCounts[champion.id] ?? 0;
                              final count = storedCount < 0 ? 0 : storedCount;
                              final discovered =
                                  count > 0 ||
                                  _discoveredChampionIds.contains(champion.id);

                              return _CollectionEntry(
                                champion: champion,
                                count: count,
                                cardHeight: cardHeight,
                                compact: compact,
                                onTap: () => _openChampionInfo(
                                  champion,
                                  count,
                                  discovered: discovered,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({
    required this.compact,
    required this.loading,
    required this.onBack,
  });

  final bool compact;
  final bool loading;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 62 : 92,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : 24,
          compact ? 8 : 17,
          compact ? 12 : 24,
          compact ? 5 : 10,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onBack,
                tooltip: 'Back to main menu',
                iconSize: compact ? 21 : 27,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            Text(
              'COLLECTION',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppColors.bone,
                fontSize: compact ? 29 : 43,
                letterSpacing: compact ? 2.2 : 3.4,
                shadows: const [
                  Shadow(
                    color: Color(0xB3130F0B),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
            if (loading)
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox.square(
                  dimension: compact ? 18 : 22,
                  child: const CircularProgressIndicator(
                    color: AppColors.amber,
                    strokeWidth: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CollectionEntry extends StatelessWidget {
  const _CollectionEntry({
    required this.champion,
    required this.count,
    required this.cardHeight,
    required this.compact,
    required this.onTap,
  });

  final Champion champion;
  final int count;
  final double cardHeight;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unlocked = count > 0;

    return Semantics(
      button: true,
      label: '${champion.name}, collected $count times',
      child: Tooltip(
        message: champion.name,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(compact ? 12 : 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChampionCard.collection(
                  champion: champion,
                  height: cardHeight,
                  unlocked: unlocked,
                ),
                SizedBox(height: compact ? 4 : 7),
                Text(
                  'x$count',
                  style: TextStyle(
                    color: unlocked
                        ? AppColors.bone
                        : AppColors.sand.withValues(alpha: 0.48),
                    fontSize: compact ? 13 : 18,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                    shadows: const [
                      Shadow(
                        color: Color(0xD1130F0B),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
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
