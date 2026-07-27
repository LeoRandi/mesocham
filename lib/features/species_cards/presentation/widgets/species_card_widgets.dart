import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/species_card.dart';
import '../species_card_assets.dart';

class SpeciesCardTile extends StatelessWidget {
  const SpeciesCardTile({
    super.key,
    required this.card,
    required this.selected,
    required this.equipped,
    required this.enabled,
    this.onPressed,
  });

  final SpeciesCard card;
  final bool selected;
  final bool equipped;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tooltip = '${card.name}\n${card.effectDescription}';

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: Semantics(
        button: enabled,
        selected: selected,
        enabled: enabled,
        label: tooltip,
        child: AnimatedScale(
          scale: selected ? 1.08 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.deepEarth,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: selected
                    ? AppColors.bone
                    : AppColors.sand.withValues(alpha: 0.7),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.amber.withValues(alpha: 0.58),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                canRequestFocus: enabled,
                onTap: enabled ? onPressed : null,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColorFiltered(
                      colorFilter: equipped
                          ? const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            )
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.dst,
                            ),
                      child: Image.asset(
                        card.assetPath,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    if (selected)
                      ColoredBox(color: AppColors.bone.withValues(alpha: 0.14)),
                    if (equipped)
                      ColoredBox(color: AppColors.ink.withValues(alpha: 0.42)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SpeciesCardBearer extends StatelessWidget {
  const SpeciesCardBearer({
    super.key,
    required this.bearerHeight,
    required this.card,
    required this.effectActive,
    required this.child,
    this.mini = false,
  });

  final double bearerHeight;
  final SpeciesCard? card;
  final bool effectActive;
  final Widget child;
  final bool mini;

  @override
  Widget build(BuildContext context) {
    final equippedCard = card;
    if (equippedCard == null) return child;

    final pillHeight = bearerHeight * (mini ? 0.5 : 0.46);
    final pillWidth = pillHeight * (mini ? 0.32 : 0.3);
    final tooltip = effectActive
        ? '${equippedCard.name}\n${equippedCard.effectDescription}'
        : '${equippedCard.name}\n${equippedCard.effectDescription}\n'
              'Inactive while the bearer is in reserve.';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -pillWidth * 0.46,
          top: (bearerHeight - pillHeight) / 2,
          child: Tooltip(
            message: tooltip,
            waitDuration: const Duration(milliseconds: 250),
            child: Semantics(
              label: tooltip,
              child: AnimatedOpacity(
                opacity: effectActive ? 1 : 0.58,
                duration: const Duration(milliseconds: 220),
                child: Container(
                  width: pillWidth,
                  height: pillHeight,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(pillWidth),
                    border: Border.all(
                      color: effectActive
                          ? AppColors.bone
                          : AppColors.sand.withValues(alpha: 0.6),
                      width: mini ? 1 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.52),
                        blurRadius: mini ? 4 : 8,
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                  child: ColorFiltered(
                    colorFilter: effectActive
                        ? const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          )
                        : const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          ),
                    child: Image.asset(
                      equippedCard.assetPath,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
