import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../champions/domain/repositories/champion_catalog.dart';
import '../../domain/entities/player_deck.dart';

enum DeckListPurpose { battle, edit }

class DeckListDialog extends StatelessWidget {
  const DeckListDialog({
    super.key,
    required this.decks,
    required this.catalog,
    required this.purpose,
  });

  final List<PlayerDeck> decks;
  final ChampionCatalog catalog;
  final DeckListPurpose purpose;

  bool get _editing => purpose == DeckListPurpose.edit;

  @override
  Widget build(BuildContext context) {
    final orderedDecks = [...decks]
      ..sort((first, second) {
        if (first.isFavorite != second.isFavorite) {
          return first.isFavorite ? -1 : 1;
        }
        return first.createdAt.compareTo(second.createdAt);
      });
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;
    final dialogHeight = (126 + orderedDecks.length * 104)
        .clamp(260.0, maxHeight)
        .toDouble();

    return Dialog(
      key: ValueKey(_editing ? 'museum-deck-dialog' : 'arena-deck-dialog'),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Container(
        width: 720,
        height: dialogHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.deepEarth,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.amber, width: 1.6),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 30, spreadRadius: 4),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 10, 13),
              child: Row(
                children: [
                  Icon(
                    _editing ? Icons.edit_note_rounded : Icons.style_rounded,
                    color: AppColors.amber,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editing ? 'TUS MAZOS' : 'ELIGE UN MAZO',
                          style: const TextStyle(
                            color: AppColors.bone,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.7,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _editing
                              ? 'Selecciona un mazo para editarlo.'
                              : 'El primer campeón será el que empiece el combate.',
                          style: const TextStyle(
                            color: AppColors.sand,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Cancelar',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.sand.withValues(alpha: 0.24)),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: orderedDecks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 9),
                itemBuilder: (context, index) {
                  final deck = orderedDecks[index];
                  return _DeckListTile(
                    deck: deck,
                    catalog: catalog,
                    editing: _editing,
                    onTap: () => Navigator.of(context).pop(deck),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckListTile extends StatelessWidget {
  const _DeckListTile({
    required this.deck,
    required this.catalog,
    required this.editing,
    required this.onTap,
  });

  final PlayerDeck deck;
  final ChampionCatalog catalog;
  final bool editing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final keyPrefix = editing ? 'museum' : 'arena';
    return Material(
      color: AppColors.ink.withValues(alpha: 0.54),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: ValueKey('$keyPrefix-deck-${deck.id}'),
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 88,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: deck.isFavorite
                  ? AppColors.scissors.withValues(alpha: 0.68)
                  : AppColors.sand.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            children: [
              Icon(
                deck.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: deck.isFavorite
                    ? AppColors.scissors
                    : AppColors.sand.withValues(alpha: 0.42),
                size: 25,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  deck.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.bone,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              for (var index = 0; index < deck.championIds.length; index++) ...[
                _DeckChampionPortrait(
                  championId: deck.championIds[index],
                  order: index + 1,
                  catalog: catalog,
                ),
                if (index != deck.championIds.length - 1)
                  const SizedBox(width: 7),
              ],
              const SizedBox(width: 12),
              if (editing)
                OutlinedButton.icon(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.health,
                    side: const BorderSide(color: AppColors.health),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('EDITAR'),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.health,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckChampionPortrait extends StatelessWidget {
  const _DeckChampionPortrait({
    required this.championId,
    required this.order,
    required this.catalog,
  });

  final String championId;
  final int order;
  final ChampionCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final champion = catalog.championById(championId);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 47,
          height: 62,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.earth,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: order == 1 ? AppColors.health : AppColors.sand,
              width: order == 1 ? 2.2 : 1.1,
            ),
          ),
          child: champion == null
              ? const Icon(Icons.help_outline_rounded, color: AppColors.sand)
              : Image.asset(
                  champion.imageAssetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.pets_rounded, color: AppColors.sand),
                ),
        ),
        Positioned(
          left: -5,
          top: -5,
          child: Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: order == 1 ? AppColors.health : AppColors.deepEarth,
              border: Border.all(color: AppColors.bone),
            ),
            child: Text(
              '$order',
              style: TextStyle(
                color: order == 1 ? AppColors.ink : AppColors.bone,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
