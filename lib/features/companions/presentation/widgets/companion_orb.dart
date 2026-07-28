import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/companion.dart';
import '../companion_assets.dart';

class CompanionOrb extends StatelessWidget {
  const CompanionOrb({
    super.key,
    required this.companion,
    required this.diameter,
    this.wild = false,
    this.queued = false,
  });

  final Companion companion;
  final double diameter;
  final bool wild;
  final bool queued;

  @override
  Widget build(BuildContext context) {
    final tooltip = '${companion.name}\n${companion.effectDescription}';
    final borderColor = wild ? AppColors.amber : AppColors.bone;

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Semantics(
        image: true,
        label: tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          width: diameter,
          height: diameter,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.deepEarth,
            border: Border.all(color: borderColor, width: wild ? 2.5 : 1.5),
            boxShadow: [
              BoxShadow(
                color: (wild ? AppColors.amber : Colors.black).withValues(
                  alpha: wild ? 0.56 : 0.48,
                ),
                blurRadius: wild ? 18 : 7,
                spreadRadius: wild ? 2 : 0,
                offset: wild ? Offset.zero : const Offset(0, 2),
              ),
            ],
          ),
          child: ColorFiltered(
            colorFilter: queued
                ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
            child: Opacity(
              opacity: queued ? 0.62 : 1,
              child: Image.asset(
                companion.assetPath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
