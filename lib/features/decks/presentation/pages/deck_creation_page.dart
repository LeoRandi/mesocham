import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../battle/presentation/widgets/battle_backdrop.dart';
import '../../../champions/domain/entities/champion.dart';
import '../../../champions/domain/repositories/champion_catalog.dart';
import '../../../champions/presentation/widgets/champion_card.dart';
import '../../../collection/presentation/pages/champion_info_page.dart';
import '../../../home/data/player_preferences.dart';
import '../../domain/entities/player_deck.dart';

class DeckCreationPage extends StatefulWidget {
  const DeckCreationPage({
    super.key,
    required this.catalog,
    required this.playerPreferences,
    this.deckToEdit,
  });

  final ChampionCatalog catalog;
  final PlayerPreferences playerPreferences;
  final PlayerDeck? deckToEdit;

  @override
  State<DeckCreationPage> createState() => _DeckCreationPageState();
}

class _DeckCreationPageState extends State<DeckCreationPage> {
  final _nameController = TextEditingController();
  final List<String?> _championIds = List.filled(
    PlayerDeck.championCount,
    null,
  );

  Map<String, int> _championCounts = const {};
  Set<String> _discoveredChampionIds = const {};
  var _selectedSlot = 0;
  var _deckOrdinal = 1;
  var _isFavorite = false;
  var _loading = true;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final deckToEdit = widget.deckToEdit;
    if (deckToEdit != null) {
      _nameController.text = deckToEdit.name;
      _isFavorite = deckToEdit.isFavorite;
      for (var index = 0; index < PlayerDeck.championCount; index++) {
        _championIds[index] = deckToEdit.championIds[index];
      }
    }
    _loadDeckData();
  }

  Future<void> _loadDeckData() async {
    try {
      final countsFuture = widget.playerPreferences
          .getChampionCollectionCounts();
      final discoveredIdsFuture = widget.playerPreferences
          .getDiscoveredChampionIds();
      final decksFuture = widget.playerPreferences.getDecks();
      final counts = await countsFuture;
      final discoveredIds = await discoveredIdsFuture;
      final decks = await decksFuture;
      if (!mounted) return;

      _deckOrdinal = decks.length + 1;
      if (widget.deckToEdit == null) {
        _nameController.text = 'Deck-$_deckOrdinal';
      }
      setState(() {
        _championCounts = counts;
        _discoveredChampionIds = discoveredIds;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      if (widget.deckToEdit == null) {
        _nameController.text = 'Deck-$_deckOrdinal';
      }
      setState(() => _loading = false);
      _showMessage('No se pudo cargar tu colección.', isError: true);
    }
  }

  void _goBack() {
    if (!_saving) Navigator.of(context).pop();
  }

  void _selectSlot(int index) {
    if (_selectedSlot == index) return;
    setState(() => _selectedSlot = index);
  }

  void _selectChampion(Champion champion) {
    if (_loading || _saving) return;

    final ownedCopies = _championCounts[champion.id] ?? 0;
    final copiesInOtherSlots = <int>[
      for (var index = 0; index < _championIds.length; index++)
        if (index != _selectedSlot && _championIds[index] == champion.id) index,
    ].length;
    if (copiesInOtherSlots >= ownedCopies) {
      _showMessage('No tienes más copias de ${champion.name}.');
      return;
    }

    setState(() {
      _championIds[_selectedSlot] = champion.id;
      final nextEmptySlot = _championIds.indexWhere((id) => id == null);
      if (nextEmptySlot != -1) {
        _selectedSlot = nextEmptySlot;
      }
    });
  }

  void _openChampionInfo(Champion champion) {
    final definition = widget.catalog.definitionById(champion.id);
    if (definition == null) return;
    final copyCount = _championCounts[champion.id] ?? 0;
    final discovered =
        copyCount > 0 || _discoveredChampionIds.contains(champion.id);

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        settings: RouteSettings(name: '/deck-creation/champion/${champion.id}'),
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

  Future<void> _saveDeck() async {
    if (_loading || _saving) return;
    final championIds = _championIds.whereType<String>().toList();
    if (championIds.length != PlayerDeck.championCount) {
      _showMessage('Selecciona 3 campeones antes de guardar.');
      return;
    }

    final selectedCounts = <String, int>{};
    for (final championId in championIds) {
      selectedCounts[championId] = (selectedCounts[championId] ?? 0) + 1;
    }
    final invalidSelection = selectedCounts.entries.any(
      (entry) => entry.value > (_championCounts[entry.key] ?? 0),
    );
    if (invalidSelection) {
      _showMessage(
        'El mazo usa más copias de las que tienes disponibles.',
        isError: true,
      );
      return;
    }

    final enteredName = PlayerDeck.normalizeName(_nameController.text);
    final fallbackName = widget.deckToEdit?.name ?? 'Deck-$_deckOrdinal';
    final deckName = enteredName.isEmpty ? fallbackName : enteredName;
    final deck =
        widget.deckToEdit?.updated(
          name: deckName,
          championIds: championIds,
          isFavorite: _isFavorite,
        ) ??
        PlayerDeck.create(
          name: deckName,
          championIds: championIds,
          isFavorite: _isFavorite,
        );

    setState(() => _saving = true);
    try {
      await widget.playerPreferences.saveDeck(deck);
      if (!mounted) return;
      Navigator.of(context).pop(deck);
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('No se pudo guardar el mazo.', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.danger : AppColors.deepEarth,
        ),
      );
  }

  @override
  void dispose() {
    _nameController.dispose();
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
                      Color(0xA62E1D14),
                      Color(0x4D9A5134),
                      Color(0xE6130F0B),
                    ],
                    stops: [0, 0.5, 1],
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact =
                        constraints.maxHeight < 640 ||
                        constraints.maxWidth < 900;
                    final cardHeight = compact
                        ? ChampionCard.compactHeight
                        : ChampionCard.largeHeight;
                    final cardWidth = cardHeight * ChampionCard.aspectRatio;
                    final rowExtent = cardHeight + (compact ? 40 : 48);
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
                        _DeckCreationHeader(
                          compact: compact,
                          editing: widget.deckToEdit != null,
                          loading: _loading,
                          isFavorite: _isFavorite,
                          nameController: _nameController,
                          onBack: _goBack,
                          onFavoriteChanged: () =>
                              setState(() => _isFavorite = !_isFavorite),
                        ),
                        SizedBox(
                          height: compact ? 145 : 198,
                          child: _ChampionSlots(
                            compact: compact,
                            selectedSlot: _selectedSlot,
                            championIds: _championIds,
                            catalog: widget.catalog,
                            onSelected: _selectSlot,
                            onChampionInfo: _openChampionInfo,
                          ),
                        ),
                        Container(
                          height: 1,
                          margin: EdgeInsets.symmetric(
                            horizontal: compact ? 18 : 34,
                          ),
                          color: AppColors.sand.withValues(alpha: 0.25),
                        ),
                        Expanded(
                          child: _loading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.amber,
                                  ),
                                )
                              : GridView.builder(
                                  key: const ValueKey('deck-champion-list'),
                                  scrollCacheExtent: ScrollCacheExtent.pixels(
                                    rowExtent,
                                  ),
                                  padding: EdgeInsets.fromLTRB(
                                    compact ? 18 : 34,
                                    compact ? 12 : 18,
                                    compact ? 80 : 118,
                                    compact ? 82 : 106,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent:
                                            cardWidth + (compact ? 28 : 42),
                                        mainAxisExtent: rowExtent,
                                        crossAxisSpacing: compact ? 8 : 14,
                                        mainAxisSpacing: compact ? 10 : 18,
                                      ),
                                  itemCount: champions.length,
                                  itemBuilder: (context, index) {
                                    final champion = champions[index];
                                    final owned =
                                        _championCounts[champion.id] ?? 0;
                                    final used = _championIds
                                        .where((id) => id == champion.id)
                                        .length;
                                    final canSelect =
                                        owned > used ||
                                        _championIds[_selectedSlot] ==
                                            champion.id;
                                    return _DeckChampionEntry(
                                      champion: champion,
                                      owned: owned,
                                      used: used,
                                      cardHeight: cardHeight,
                                      compact: compact,
                                      canSelect: canSelect,
                                      onTap: () => _selectChampion(champion),
                                      onSecondaryTap: () =>
                                          _openChampionInfo(champion),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Positioned(
                right: MediaQuery.sizeOf(context).width < 900 ? 18 : 34,
                bottom:
                    MediaQuery.paddingOf(context).bottom +
                    (MediaQuery.sizeOf(context).height < 640 ? 16 : 28),
                child: _SaveDeckButton(
                  saving: _saving,
                  onPressed: _loading ? null : _saveDeck,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckCreationHeader extends StatelessWidget {
  const _DeckCreationHeader({
    required this.compact,
    required this.editing,
    required this.loading,
    required this.isFavorite,
    required this.nameController,
    required this.onBack,
    required this.onFavoriteChanged,
  });

  final bool compact;
  final bool editing;
  final bool loading;
  final bool isFavorite;
  final TextEditingController nameController;
  final VoidCallback onBack;
  final VoidCallback onFavoriteChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 66 : 94,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 10 : 22,
          compact ? 8 : 17,
          compact ? 14 : 28,
          compact ? 6 : 11,
        ),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('deck-creation-back'),
              onPressed: onBack,
              tooltip: 'Volver',
              iconSize: compact ? 22 : 28,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            SizedBox(width: compact ? 3 : 12),
            Expanded(
              child: Text(
                editing ? 'EDITAR MAZO' : 'CREACIÓN DE MAZO',
                maxLines: 1,
                overflow: TextOverflow.fade,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.bone,
                  fontSize: compact ? 22 : 38,
                  letterSpacing: compact ? 1.6 : 2.8,
                  shadows: const [
                    Shadow(
                      color: Color(0xB3130F0B),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: compact ? 5 : 16),
            IconButton(
              key: const ValueKey('deck-favorite-toggle'),
              onPressed: loading ? null : onFavoriteChanged,
              tooltip: isFavorite
                  ? 'Quitar de favoritos'
                  : 'Marcar como favorito',
              iconSize: compact ? 25 : 32,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  key: ValueKey(isFavorite),
                  color: isFavorite
                      ? AppColors.scissors
                      : AppColors.sand.withValues(alpha: 0.5),
                ),
              ),
            ),
            SizedBox(
              width: compact ? 180 : 288,
              height: compact ? 42 : 50,
              child: TextField(
                key: const ValueKey('deck-name-field'),
                controller: nameController,
                enabled: !loading,
                maxLength: PlayerDeck.maxNameLength,
                maxLines: 1,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿĀ-ɏ0-9 .-]'),
                  ),
                  LengthLimitingTextInputFormatter(PlayerDeck.maxNameLength),
                ],
                style: TextStyle(
                  color: AppColors.bone,
                  fontSize: compact ? 14 : 17,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Nombre del mazo',
                  filled: true,
                  fillColor: AppColors.ink.withValues(alpha: 0.68),
                  contentPadding: EdgeInsets.fromLTRB(
                    compact ? 13 : 16,
                    compact ? 9 : 12,
                    5,
                    compact ? 9 : 12,
                  ),
                  suffixIcon: Icon(
                    Icons.edit_rounded,
                    size: compact ? 18 : 21,
                    color: AppColors.teal,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.sand.withValues(alpha: 0.55),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.health,
                      width: 2,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.sand.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChampionSlots extends StatelessWidget {
  const _ChampionSlots({
    required this.compact,
    required this.selectedSlot,
    required this.championIds,
    required this.catalog,
    required this.onSelected,
    required this.onChampionInfo,
  });

  final bool compact;
  final int selectedSlot;
  final List<String?> championIds;
  final ChampionCatalog catalog;
  final ValueChanged<int> onSelected;
  final ValueChanged<Champion> onChampionInfo;

  @override
  Widget build(BuildContext context) {
    final firstHeight = compact ? 110.0 : 164.0;
    final otherHeight = compact ? 94.0 : 140.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final slots = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var index = 0; index < championIds.length; index++) ...[
              _DeckChampionSlot(
                index: index,
                champion: championIds[index] == null
                    ? null
                    : catalog.championById(championIds[index]!),
                selected: selectedSlot == index,
                height: index == 0 ? firstHeight : otherHeight,
                onTap: () => onSelected(index),
                onSecondaryTap: championIds[index] == null
                    ? null
                    : () {
                        final champion = catalog.championById(
                          championIds[index]!,
                        );
                        if (champion != null) onChampionInfo(champion);
                      },
              ),
              if (index != championIds.length - 1)
                SizedBox(width: compact ? 13 : 25),
            ],
          ],
        );

        if (constraints.maxWidth < 560) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PRIMER CAMPEÓN',
                    style: TextStyle(
                      color: AppColors.health,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    Icons.arrow_downward_rounded,
                    color: AppColors.health,
                    size: 17,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              slots,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FirstChampionArrow(compact: compact),
            SizedBox(width: compact ? 14 : 28),
            slots,
          ],
        );
      },
    );
  }
}

class _FirstChampionArrow extends StatelessWidget {
  const _FirstChampionArrow({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _ArrowBannerPainter(),
      child: SizedBox(
        width: compact ? 124 : 178,
        height: compact ? 42 : 58,
        child: Padding(
          padding: EdgeInsets.only(
            left: compact ? 10 : 16,
            right: compact ? 24 : 34,
          ),
          child: Center(
            child: Text(
              'PRIMER\nCAMPEÓN',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: compact ? 10 : 14,
                height: 1.05,
                fontWeight: FontWeight.w900,
                letterSpacing: compact ? 0.8 : 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowBannerPainter extends CustomPainter {
  const _ArrowBannerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.health;
    final bodyWidth = size.width - size.height * 0.42;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, bodyWidth + 5, size.height),
        Radius.circular(size.height * 0.28),
      ),
      paint,
    );
    final point = Path()
      ..moveTo(bodyWidth, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(bodyWidth, size.height)
      ..close();
    canvas.drawPath(point, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowBannerPainter oldDelegate) => false;
}

class _DeckChampionSlot extends StatelessWidget {
  const _DeckChampionSlot({
    required this.index,
    required this.champion,
    required this.selected,
    required this.height,
    required this.onTap,
    required this.onSecondaryTap,
  });

  final int index;
  final Champion? champion;
  final bool selected;
  final double height;
  final VoidCallback onTap;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final width = height * ChampionCard.aspectRatio;
    return Semantics(
      button: true,
      selected: selected,
      label: champion == null
          ? 'Posición ${index + 1}, vacía'
          : 'Posición ${index + 1}, ${champion!.name}',
      child: Tooltip(
        message: champion == null
            ? 'Seleccionar posición ${index + 1}'
            : 'Seleccionar posición ${index + 1}\n'
                  'Clic derecho: ver información',
        child: InkWell(
          key: ValueKey('deck-slot-$index'),
          onTap: onTap,
          onSecondaryTap: champion == null ? null : onSecondaryTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? AppColors.health
                    : AppColors.sand.withValues(alpha: 0.45),
                width: selected ? 4 : 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.health.withValues(alpha: 0.38),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ]
                  : const [],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (champion != null)
                  ChampionCard.collection(
                    champion: champion!,
                    height: height,
                    unlocked: true,
                  )
                else
                  Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.sand.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: height * 0.28,
                          color: selected
                              ? AppColors.health
                              : AppColors.sand.withValues(alpha: 0.48),
                        ),
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: AppColors.sand.withValues(alpha: 0.62),
                            fontWeight: FontWeight.w900,
                            fontSize: height * 0.13,
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  left: -9,
                  top: -9,
                  child: Container(
                    width: height < 120 ? 23 : 29,
                    height: height < 120 ? 23 : 29,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.health : AppColors.deepEarth,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bone, width: 1.5),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: selected ? AppColors.ink : AppColors.bone,
                        fontSize: height < 120 ? 11 : 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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

class _DeckChampionEntry extends StatelessWidget {
  const _DeckChampionEntry({
    required this.champion,
    required this.owned,
    required this.used,
    required this.cardHeight,
    required this.compact,
    required this.canSelect,
    required this.onTap,
    required this.onSecondaryTap,
  });

  final Champion champion;
  final int owned;
  final int used;
  final double cardHeight;
  final bool compact;
  final bool canSelect;
  final VoidCallback onTap;
  final VoidCallback onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final unlocked = owned > 0;
    final remaining = (owned - used).clamp(0, owned);
    return Semantics(
      button: canSelect,
      enabled: canSelect,
      label: '${champion.name}, $remaining de $owned copias disponibles',
      child: Tooltip(
        message:
            '${champion.name} · '
            '${unlocked ? '$remaining disponibles' : 'No descubierto'}\n'
            'Clic derecho: ver información',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('deck-champion-${champion.id}'),
            onTap: canSelect ? onTap : null,
            onSecondaryTap: onSecondaryTap,
            mouseCursor: canSelect
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden,
            borderRadius: BorderRadius.circular(compact ? 12 : 18),
            child: AnimatedOpacity(
              opacity: canSelect ? 1 : 0.52,
              duration: const Duration(milliseconds: 160),
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
                    unlocked
                        ? '$remaining disponibles · x$owned'
                        : 'NO DISPONIBLE',
                    maxLines: 1,
                    style: TextStyle(
                      color: canSelect
                          ? AppColors.bone
                          : AppColors.sand.withValues(alpha: 0.55),
                      fontSize: compact ? 10 : 12,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.45,
                      shadows: const [
                        Shadow(
                          color: Color(0xD1130F0B),
                          blurRadius: 5,
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
      ),
    );
  }
}

class _SaveDeckButton extends StatelessWidget {
  const _SaveDeckButton({required this.saving, required this.onPressed});

  final bool saving;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: const ValueKey('save-deck-button'),
      onPressed: saving ? null : onPressed,
      style: FilledButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.health,
        disabledForegroundColor: AppColors.sand,
        disabledBackgroundColor: AppColors.earth,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
        elevation: 10,
        shadowColor: Colors.black,
        side: const BorderSide(color: AppColors.bone, width: 1.5),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
      icon: saving
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          : const Icon(Icons.save_rounded),
      label: Text(saving ? 'GUARDANDO...' : 'GUARDAR'),
    );
  }
}
