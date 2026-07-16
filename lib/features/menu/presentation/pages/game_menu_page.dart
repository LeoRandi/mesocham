import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/menu_backdrop.dart';

class GameMenuPage extends StatelessWidget {
  const GameMenuPage({super.key});

  void _openFossilRace(BuildContext context) {
    Navigator.of(context).pushNamed('/battle');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const MenuBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 520;
                final horizontalPadding = compact ? 26.0 : 56.0;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1500),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: compact ? 16 : 34,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 11,
                            child: _MenuContent(
                              compact: compact,
                              onFossilRacePressed: () =>
                                  _openFossilRace(context),
                            ),
                          ),
                          Expanded(
                            flex: 9,
                            child: _FeaturePanel(compact: compact),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuContent extends StatelessWidget {
  const _MenuContent({
    required this.compact,
    required this.onFossilRacePressed,
  });

  final bool compact;
  final VoidCallback onFossilRacePressed;

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 30.0 : 48.0;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _LevelBadge(),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    'MESOZOIC CHAMPIONS',
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.sand,
                      fontSize: compact ? 11 : 13,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              'Choose your\nexpedition',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppColors.bone,
                fontSize: titleSize,
              ),
            ),
            SizedBox(height: compact ? 16 : 30),
            _FossilRaceButton(onPressed: onFossilRacePressed),
            SizedBox(height: compact ? 10 : 18),
            Text(
              'Face an AI paleontologist, earn experience,\nand uncover rewards from the Mesozoic Era.',
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.bone.withValues(alpha: 0.66),
                height: 1.45,
                fontSize: compact ? 12 : 16,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.sports_esports_rounded,
                  size: 18,
                  color: AppColors.teal,
                ),
                const SizedBox(width: 8),
                Text(
                  'FOSSIL RACE · DEMO MATCH',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.teal,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.only(left: 5, right: 14),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.teal, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.bone,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 20,
              color: AppColors.earth,
            ),
          ),
          const SizedBox(width: 9),
          const Text(
            'LV. 1',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}

class _FossilRaceButton extends StatefulWidget {
  const _FossilRaceButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_FossilRaceButton> createState() => _FossilRaceButtonState();
}

class _FossilRaceButtonState extends State<_FossilRaceButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.018 : 1,
        alignment: Alignment.centerLeft,
        duration: const Duration(milliseconds: 180),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: _hovered
                    ? AppColors.amber.withValues(alpha: 0.22)
                    : AppColors.bone.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hovered ? AppColors.amber : AppColors.sand,
                  width: _hovered ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'FOSSIL RACE',
                          style: TextStyle(
                            color: AppColors.bone,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          'Single-player expedition',
                          style: TextStyle(color: AppColors.sand),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.amber,
                    size: 30,
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

class _FeaturePanel extends StatelessWidget {
  const _FeaturePanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: compact ? 30 : 72),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FossilSeal(size: compact ? 118 : 190),
          SizedBox(height: compact ? 14 : 26),
          Text(
            'FOSSIL RACE',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.bone,
              fontSize: compact ? 22 : 34,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 9),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 330),
            child: Text(
              'Read the rival, choose your move, and lead your champion to victory.',
              textAlign: TextAlign.center,
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.sand.withValues(alpha: 0.8),
                height: 1.4,
                fontSize: compact ? 12 : 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
