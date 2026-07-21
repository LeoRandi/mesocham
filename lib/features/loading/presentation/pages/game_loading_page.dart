import 'dart:async';

import 'package:flutter/material.dart';

import '../../../battle/domain/entities/champion.dart';
import '../../../battle/presentation/widgets/champion_type_emblem.dart';

class GameLoadingPage extends StatefulWidget {
  const GameLoadingPage({
    super.key,
    required this.destinationRoute,
    this.retainedRouteName,
    this.waitDuration = const Duration(seconds: 2),
  });

  // This is the app's go-to loading screen. Route future loading flows through
  // this class so they share the same black transition and blinking game logo.
  final String destinationRoute;
  final String? retainedRouteName;
  final Duration waitDuration;

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
  Timer? _navigationTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeAnimation != null || _navigationTimer != null) return;

    _routeAnimation = ModalRoute.of(context)?.animation;
    if (_routeAnimation == null || _routeAnimation!.isCompleted) {
      _startNavigationTimer();
    } else {
      _routeAnimation!.addStatusListener(_handleRouteStatus);
    }
  }

  void _handleRouteStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    _routeAnimation?.removeStatusListener(_handleRouteStatus);
    _startNavigationTimer();
  }

  void _startNavigationTimer() {
    if (_navigationTimer != null) return;

    _navigationTimer = Timer(widget.waitDuration, () {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        widget.destinationRoute,
        (route) =>
            widget.retainedRouteName != null &&
            route.settings.name == widget.retainedRouteName,
      );
    });
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_handleRouteStatus);
    _navigationTimer?.cancel();
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
          label: 'Loading Mesozoic Champions',
          child: SafeArea(
            minimum: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final logoSize = (constraints.maxHeight * 0.16)
                    .clamp(54.0, 92.0)
                    .toDouble();

                return Align(
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
