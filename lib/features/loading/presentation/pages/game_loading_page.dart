import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../champions/domain/entities/champion.dart';
import '../../../champions/domain/repositories/champion_catalog.dart';
import '../../../champions/presentation/widgets/champion_type_emblem.dart';
import '../../../species_cards/domain/entities/species_card.dart';
import '../../../species_cards/presentation/species_card_assets.dart';

class GameLoadingPage extends StatefulWidget {
  const GameLoadingPage({
    super.key,
    required this.catalog,
    required this.destinationRoute,
    this.retainedRouteName,
    this.minimumWaitDuration = const Duration(milliseconds: 500),
  });

  // Route future loading flows through this screen so navigation only
  // continues after the destination's image assets have decoded successfully.
  final ChampionCatalog catalog;
  final String destinationRoute;
  final String? retainedRouteName;
  final Duration minimumWaitDuration;

  @override
  State<GameLoadingPage> createState() => _GameLoadingPageState();
}

class _GameLoadingPageState extends State<GameLoadingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _logoController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat(reverse: true);
  late final Animation<double> _logoOpacity = CurvedAnimation(
    parent: _logoController,
    curve: Curves.easeInOut,
  );

  Animation<double>? _routeAnimation;
  Object? _loadError;
  var _loadInProgress = false;
  var _loadAttempt = 0;

  List<_DestinationImage> get _destinationImages {
    final typeEmblems = [
      for (final assetPath in ChampionTypeEmblem.assetPaths)
        _DestinationImage(assetPath, cacheWidth: 256),
    ];

    return switch (widget.destinationRoute) {
      '/collection' || '/battle' => [
        ...typeEmblems,
        if (widget.destinationRoute == '/battle')
          const _DestinationImage('assets/images/champion_emblems.png'),
        if (widget.destinationRoute == '/battle')
          for (final card in SpeciesCard.values)
            _DestinationImage(card.assetPath, cacheWidth: 512),
        for (final champion in widget.catalog.champions) ...[
          _DestinationImage(champion.imageAssetPath, cacheWidth: 256),
          if (champion.closeUpAssetPath != null)
            _DestinationImage(champion.closeUpAssetPath!, cacheWidth: 256),
        ],
      ],
      _ => typeEmblems,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeAnimation != null || _loadInProgress || _loadAttempt > 0) return;

    _routeAnimation = ModalRoute.of(context)?.animation;
    if (_routeAnimation == null || _routeAnimation!.isCompleted) {
      _startLoading();
    } else {
      _routeAnimation!.addStatusListener(_handleRouteStatus);
    }
  }

  void _handleRouteStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    _routeAnimation?.removeStatusListener(_handleRouteStatus);
    _startLoading();
  }

  void _startLoading() {
    if (_loadInProgress) return;

    setState(() {
      _loadInProgress = true;
      _loadError = null;
    });
    final attempt = ++_loadAttempt;
    _loadAssetsAndNavigate(attempt);
  }

  Future<void> _loadAssetsAndNavigate(int attempt) async {
    final minimumWait = Future<void>.delayed(widget.minimumWaitDuration);

    try {
      await Future.wait([minimumWait, _precacheDestinationImages()]);
      if (!mounted || attempt != _loadAttempt) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        widget.destinationRoute,
        (route) =>
            widget.retainedRouteName != null &&
            route.settings.name == widget.retainedRouteName,
      );
    } on Object catch (error) {
      await minimumWait;
      if (!mounted || attempt != _loadAttempt) return;

      setState(() {
        _loadInProgress = false;
        _loadError = error;
      });
    }
  }

  Future<void> _precacheDestinationImages() async {
    final images = _destinationImages;
    const batchSize = 8;

    for (var start = 0; start < images.length; start += batchSize) {
      if (!mounted) return;
      final end = (start + batchSize).clamp(0, images.length);
      await Future.wait([
        for (var index = start; index < end; index++)
          _precacheImage(images[index]),
      ]);
    }
  }

  Future<void> _precacheImage(_DestinationImage image) async {
    final assetProvider = AssetImage(image.assetPath);
    final provider = image.cacheWidth == null
        ? assetProvider
        : ResizeImage.resizeIfNeeded(image.cacheWidth, null, assetProvider);
    Object? loadError;
    StackTrace? loadStackTrace;

    await precacheImage(
      provider,
      context,
      onError: (error, stackTrace) {
        loadError = error;
        loadStackTrace = stackTrace;
      },
    );

    if (loadError != null) {
      Error.throwWithStackTrace(
        StateError('Could not load ${image.assetPath}: $loadError'),
        loadStackTrace ?? StackTrace.current,
      );
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_handleRouteStatus);
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Semantics(
          label: _loadError == null
              ? 'Loading Mesozoic Champions'
              : 'Mesozoic Champions asset loading failed',
          child: SafeArea(
            minimum: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final logoSize = (constraints.maxHeight * 0.16)
                    .clamp(54.0, 92.0)
                    .toDouble();

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_loadError != null)
                      Center(
                        child: _LoadingErrorCard(
                          error: _loadError!,
                          onRetry: _startLoading,
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: FadeTransition(
                        opacity: _logoOpacity,
                        child: ChampionTypeEmblem(
                          type: ChampionType.jaw,
                          size: logoSize,
                          shadows: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.16),
                              blurRadius: logoSize * 0.16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingErrorCard extends StatelessWidget {
  const _LoadingErrorCard({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 430,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.deepEarth,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.danger, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_rounded,
            color: AppColors.danger,
            size: 38,
          ),
          const SizedBox(height: 10),
          const Text(
            'ASSETS COULD NOT BE PREPARED',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.bone,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.sand.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('RETRY'),
          ),
        ],
      ),
    );
  }
}

class _DestinationImage {
  const _DestinationImage(this.assetPath, {this.cacheWidth});

  final String assetPath;
  final int? cacheWidth;
}
