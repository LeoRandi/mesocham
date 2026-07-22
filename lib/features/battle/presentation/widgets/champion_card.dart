import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/champion.dart';
import 'champion_type_emblem.dart';

class ChampionCard extends StatelessWidget {
  const ChampionCard({
    super.key,
    required this.champion,
    required this.height,
    required this.currentHealth,
    required this.maximumHealth,
    this.defeated = false,
  });

  final Champion champion;
  final double height;
  final double currentHealth;
  final double maximumHealth;
  final bool defeated;

  @override
  Widget build(BuildContext context) {
    final width = height * (319 / 502);
    final compact = height < 125;
    final borderWidth = compact ? 1.5 : 2.5;
    final outerRadius = compact ? 10.0 : 16.0;
    final contentPadding = compact ? 4.0 : 7.0;
    final headerHeight = compact ? 10.0 : 15.0;
    final portraitRadius = outerRadius * 0.78;
    final nameStyle = TextStyle(
      color: AppColors.bone,
      fontSize: compact ? 8 : 12,
      height: 1.25,
      fontWeight: FontWeight.w900,
      letterSpacing: compact ? 0.15 : 0.25,
      shadows: const [Shadow(color: Colors.black87, blurRadius: 2)],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: defeated ? const Color(0xFF4B4038) : const Color(0xFFB86F49),
        borderRadius: BorderRadius.circular(outerRadius),
        border: Border.all(
          color: defeated ? Colors.white38 : AppColors.ink,
          width: borderWidth,
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
              borderRadius: BorderRadius.circular(outerRadius - borderWidth),
              color: Colors.black.withValues(alpha: 0.42),
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(outerRadius - borderWidth),
        child: Padding(
          padding: EdgeInsets.all(contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: headerHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: headerHeight,
                      padding: EdgeInsets.all(compact ? 0.75 : 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.ink,
                          width: compact ? 0.8 : 1.2,
                        ),
                      ),
                      child: ChampionTypeEmblem(
                        type: champion.type,
                        size: headerHeight - (compact ? 1.5 : 2),
                      ),
                    ),
                    SizedBox(width: compact ? 3 : 5),
                    Expanded(
                      child: _MarqueeText(
                        text: champion.name,
                        style: nameStyle,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 3 : 5),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4E7CE),
                    borderRadius: BorderRadius.circular(portraitRadius),
                    border: Border.all(
                      color: AppColors.ink,
                      width: compact ? 1.2 : 2,
                    ),
                  ),
                  child: _ChampionPortrait(
                    champion: champion,
                    fallbackSize: width * 0.42,
                  ),
                ),
              ),
              SizedBox(height: compact ? 3 : 5),
              _CardHealthBar(
                current: currentHealth,
                maximum: maximumHealth,
                compact: compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChampionPortrait extends StatelessWidget {
  const _ChampionPortrait({required this.champion, required this.fallbackSize});

  final Champion champion;
  final double fallbackSize;

  @override
  Widget build(BuildContext context) {
    final imageAssetPath = champion.closeUpAssetPath ?? champion.imageAssetPath;

    if (imageAssetPath == null) {
      return Center(
        child: ChampionTypeEmblem(type: champion.type, size: fallbackSize),
      );
    }

    return Image.asset(
      imageAssetPath,
      width: double.infinity,
      fit: BoxFit.fitWidth,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => Center(
        child: ChampionTypeEmblem(type: champion.type, size: fallbackSize),
      ),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  const _MarqueeText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _position = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 35),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 35),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final overflow = (textPainter.width - constraints.maxWidth)
            .clamp(0.0, double.infinity)
            .toDouble();

        if (overflow == 0) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.text,
              maxLines: 1,
              softWrap: false,
              style: widget.style,
            ),
          );
        }

        return Semantics(
          label: widget.text,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _position,
              builder: (context, child) => Transform.translate(
                offset: Offset(-overflow * _position.value, 0),
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: textPainter.width,
                  maxWidth: textPainter.width,
                  child: child,
                ),
              ),
              child: ExcludeSemantics(
                child: Text(
                  widget.text,
                  maxLines: 1,
                  softWrap: false,
                  style: widget.style,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CardHealthBar extends StatelessWidget {
  const _CardHealthBar({
    required this.current,
    required this.maximum,
    required this.compact,
  });

  final double current;
  final double maximum;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final target = maximum == 0
        ? 0.0
        : (current / maximum).clamp(0.0, 1.0).toDouble();
    final currentLabel = _formatHealth(current);
    final maximumLabel = _formatHealth(maximum);
    final barHeight = compact ? 9.0 : 14.0;

    return Semantics(
      label: '$currentLabel of $maximumLabel health points',
      child: Container(
        height: barHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF321510),
          borderRadius: BorderRadius.circular(compact ? 1.5 : 2.5),
          border: Border.all(color: AppColors.ink, width: compact ? 0.8 : 1.2),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: target),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF21B94D), AppColors.health],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Text(
                '$currentLabel / $maximumLabel',
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 5.5 : 8,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHealth(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class ChampionEmblem extends StatelessWidget {
  const ChampionEmblem({super.key, this.imageAssetPath, this.defeated = false});

  final String? imageAssetPath;
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
            child: imageAssetPath == null
                ? ClipRect(
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
                  )
                : Image.asset(
                    imageAssetPath!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
          ),
        );
      },
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
        child: AspectRatio(aspectRatio: 1, child: ChampionEmblem()),
      ),
    );
  }
}
