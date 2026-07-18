import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/input/number_focus_shortcuts.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/menu_backdrop.dart';

const _menuDestinations = [
  _MenuDestination(
    id: 'arena',
    title: 'ARENA',
    subtitle: 'Play and master the battle system',
    description:
        'Play Fossil Race, enter the Extinction Coliseum, or learn the rules in the tutorial.',
    sections: 'FOSSIL RACE  /  EXTINCTION COLISEUM  /  TUTORIAL',
    icon: Icons.sports_mma_rounded,
    accent: AppColors.amber,
    enabled: true,
  ),
  _MenuDestination(
    id: 'excavation',
    title: 'EXCAVATION',
    subtitle: 'Unearth new champions',
    description:
        'Excavate three champions every 12 hours, or spend a pickaxe to skip the wait.',
    sections: 'EXCAVATE  /  EXCAVATION POINTS',
    icon: Icons.construction_rounded,
    accent: AppColors.teal,
    enabled: false,
  ),
  _MenuDestination(
    id: 'museum',
    title: 'MUSEUM',
    subtitle: 'Manage your discoveries and teams',
    description:
        'Study your collection, build champion decks, and trade duplicates with other players.',
    sections: 'COLLECTION  /  DECKS  /  BLACK MARKET',
    icon: Icons.museum_rounded,
    accent: AppColors.sand,
    enabled: false,
  ),
  _MenuDestination(
    id: 'missions',
    title: 'MISSIONS',
    subtitle: 'Complete objectives and earn rewards',
    description:
        'Finish daily and predefined missions to earn excavation points and pickaxes.',
    sections: 'DAILY  /  PREDEFINED',
    icon: Icons.assignment_turned_in_rounded,
    accent: AppColors.health,
    enabled: false,
  ),
];

const _arenaModes = [
  _MenuDestination(
    id: 'fossil-race',
    title: 'FOSSIL RACE',
    subtitle: 'Single-player expedition',
    description:
        'Face AI-controlled decks to gain experience and uncover rewards from the Mesozoic Era.',
    sections: 'SINGLE PLAYER  /  EXPERIENCE  /  REWARDS',
    icon: Icons.travel_explore_rounded,
    accent: AppColors.amber,
    enabled: true,
  ),
  _MenuDestination(
    id: 'extinction-coliseum',
    title: 'EXTINCTION COLISEUM',
    subtitle: 'Friendly and ranked PvP matches',
    description:
        'Challenge other paleontologists in friendly matches or compete for a place in the rankings.',
    sections: 'FRIENDLY  /  RANKED  /  RANKINGS',
    icon: Icons.emoji_events_rounded,
    accent: AppColors.danger,
    enabled: false,
  ),
  _MenuDestination(
    id: 'tutorial',
    title: 'TUTORIAL',
    subtitle: 'Learn the battle mechanics',
    description:
        'Learn how champions, moves, and Rock, Paper, Scissors battles work and earn one pickaxe.',
    sections: 'TRAINING  /  PICKAXE REWARD',
    icon: Icons.school_rounded,
    accent: AppColors.teal,
    enabled: false,
  ),
];

enum _MenuLevel { main, arena }

class GameMenuPage extends StatefulWidget {
  const GameMenuPage({super.key});

  @override
  State<GameMenuPage> createState() => _GameMenuPageState();
}

class _GameMenuPageState extends State<GameMenuPage> {
  late final List<FocusNode> _menuFocusNodes = List.generate(
    _menuDestinations.length,
    (index) => FocusNode(debugLabel: _menuDestinations[index].title),
  );
  late final List<FocusNode> _arenaFocusNodes = List.generate(
    _arenaModes.length,
    (index) => FocusNode(debugLabel: _arenaModes[index].title),
  );
  var _level = _MenuLevel.main;
  var _selectedIndex = 0;

  List<_MenuDestination> get _destinations => switch (_level) {
    _MenuLevel.main => _menuDestinations,
    _MenuLevel.arena => _arenaModes,
  };

  List<FocusNode> get _focusNodes => switch (_level) {
    _MenuLevel.main => _menuFocusNodes,
    _MenuLevel.arena => _arenaFocusNodes,
  };

  void _selectDestination(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  void _activateDestination(int index) {
    switch ((_level, index)) {
      case (_MenuLevel.main, 0):
        _openArena();
      case (_MenuLevel.arena, 0):
        Navigator.of(context).pushNamed('/battle');
      default:
        break;
    }
  }

  void _openArena() {
    setState(() {
      _level = _MenuLevel.arena;
      _selectedIndex = 0;
    });
    _requestFocusAfterFrame(_arenaFocusNodes.first);
  }

  void _closeArena() {
    if (_level != _MenuLevel.arena) return;

    setState(() {
      _level = _MenuLevel.main;
      _selectedIndex = 0;
    });
    _requestFocusAfterFrame(_menuFocusNodes.first);
  }

  void _requestFocusAfterFrame(FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final focusNode in [..._menuFocusNodes, ..._arenaFocusNodes]) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        if (_level == _MenuLevel.arena)
          const SingleActivator(LogicalKeyboardKey.escape): _closeArena,
      },
      child: Shortcuts(
        shortcuts: numberFocusShortcuts(_focusNodes),
        child: Focus(
          autofocus: true,
          skipTraversal: true,
          child: FocusTraversalGroup(
            child: Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final compact =
                      constraints.maxHeight < 600 ||
                      constraints.maxWidth < 1050;
                  final showKeyboardHints =
                      kIsWeb || defaultTargetPlatform == TargetPlatform.windows;
                  final selectedDestination = _destinations[_selectedIndex];
                  final menuWidth = constraints.maxWidth * 0.53;
                  final descriptionWidth = (constraints.maxWidth * 0.25)
                      .clamp(210.0, 470.0)
                      .toDouble();

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Layer 1: selected destination visual and color.
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        child: MenuDestinationBackdrop(
                          key: ValueKey('backdrop-${selectedDestination.id}'),
                          accent: selectedDestination.accent,
                          icon: selectedDestination.icon,
                        ),
                      ),
                      // Layer 2: fixed navigation surface with its jagged edge.
                      const MenuLeftPanel(),
                      // Layer 3: independent selected-option explanation card.
                      Positioned(
                        right: compact ? 16 : 34,
                        bottom: compact ? 14 : 30,
                        width: descriptionWidth,
                        child: _MenuDescriptionCard(
                          compact: compact,
                          destination: selectedDestination,
                        ),
                      ),
                      // Layer 4: profile, headings, menu options and hints.
                      SafeArea(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 22 : 52,
                            compact ? 14 : 28,
                            0,
                            compact ? 14 : 26,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: menuWidth,
                              child: _MenuContent(
                                compact: compact,
                                destinations: _destinations,
                                focusNodes: _focusNodes,
                                selectedIndex: _selectedIndex,
                                showBack: _level == _MenuLevel.arena,
                                showKeyboardHints: showKeyboardHints,
                                onBack: _closeArena,
                                onSelected: _selectDestination,
                                onActivated: _activateDestination,
                              ),
                            ),
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
      ),
    );
  }
}

class _MenuContent extends StatelessWidget {
  const _MenuContent({
    required this.compact,
    required this.destinations,
    required this.focusNodes,
    required this.selectedIndex,
    required this.showBack,
    required this.showKeyboardHints,
    required this.onBack,
    required this.onSelected,
    required this.onActivated,
  });

  final bool compact;
  final List<_MenuDestination> destinations;
  final List<FocusNode> focusNodes;
  final int selectedIndex;
  final bool showBack;
  final bool showKeyboardHints;
  final VoidCallback onBack;
  final ValueChanged<int> onSelected;
  final ValueChanged<int> onActivated;

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 28.0 : 43.0;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (showBack) ...[
                  IconButton(
                    onPressed: onBack,
                    tooltip: showKeyboardHints
                        ? 'Back to main menu (Esc)'
                        : 'Back to main menu',
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 10),
                ],
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
              showBack ? 'Choose an Arena mode' : 'Choose your destination',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppColors.bone,
                fontSize: titleSize,
              ),
            ),
            SizedBox(height: compact ? 12 : 22),
            for (var index = 0; index < destinations.length; index++) ...[
              _MenuOptionButton(
                number: index + 1,
                destination: destinations[index],
                focusNode: focusNodes[index],
                selected: selectedIndex == index,
                compact: compact,
                onHighlighted: () => onSelected(index),
                onActivated: () => onActivated(index),
              ),
              if (index != destinations.length - 1)
                SizedBox(height: compact ? 6 : 9),
            ],
            const Spacer(),
            if (showKeyboardHints)
              Row(
                children: [
                  const Icon(
                    Icons.keyboard_alt_outlined,
                    size: 18,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    showBack
                        ? 'TAB OR 1-3 TO FOCUS  /  ESC TO GO BACK'
                        : 'TAB OR 1-4 TO FOCUS',
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

class _MenuOptionButton extends StatefulWidget {
  const _MenuOptionButton({
    required this.number,
    required this.destination,
    required this.focusNode,
    required this.selected,
    required this.compact,
    required this.onHighlighted,
    required this.onActivated,
  });

  final int number;
  final _MenuDestination destination;
  final FocusNode focusNode;
  final bool selected;
  final bool compact;
  final VoidCallback onHighlighted;
  final VoidCallback onActivated;

  @override
  State<_MenuOptionButton> createState() => _MenuOptionButtonState();
}

class _MenuOptionButtonState extends State<_MenuOptionButton> {
  var _hovered = false;
  var _focused = false;

  void _handleFocusChange(bool focused) {
    setState(() => _focused = focused);
    if (focused) widget.onHighlighted();
  }

  void _handlePointerEnter(PointerEnterEvent event) {
    setState(() => _hovered = true);
    widget.onHighlighted();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        (event.logicalKey != LogicalKeyboardKey.enter &&
            event.logicalKey != LogicalKeyboardKey.space)) {
      return KeyEventResult.ignored;
    }

    if (widget.destination.enabled) {
      widget.onActivated();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = _hovered || _focused || widget.selected;
    final destination = widget.destination;

    return Semantics(
      button: true,
      enabled: destination.enabled,
      label: '${widget.number}, ${destination.title}',
      child: Focus(
        key: ValueKey('menu-option-${destination.id}'),
        focusNode: widget.focusNode,
        onFocusChange: _handleFocusChange,
        onKeyEvent: _handleKeyEvent,
        child: MouseRegion(
          cursor: destination.enabled
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          onEnter: _handlePointerEnter,
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedScale(
            scale: _focused || _hovered ? 1.012 : 1,
            alignment: Alignment.centerLeft,
            duration: const Duration(milliseconds: 160),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                canRequestFocus: false,
                excludeFromSemantics: true,
                onTap: () {
                  widget.focusNode.requestFocus();
                  widget.onHighlighted();
                  if (destination.enabled) widget.onActivated();
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 540),
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compact ? 12 : 16,
                    vertical: widget.compact ? 7 : 11,
                  ),
                  decoration: BoxDecoration(
                    color: highlighted
                        ? destination.accent.withValues(alpha: 0.17)
                        : AppColors.bone.withValues(alpha: 0.055),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: highlighted
                          ? destination.accent
                          : AppColors.sand.withValues(alpha: 0.5),
                      width: _focused ? 2.4 : (highlighted ? 1.6 : 1),
                    ),
                    boxShadow: _focused
                        ? [
                            BoxShadow(
                              color: destination.accent.withValues(alpha: 0.3),
                              blurRadius: 14,
                            ),
                          ]
                        : const [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: widget.compact ? 31 : 38,
                        decoration: BoxDecoration(
                          color: destination.accent.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(width: widget.compact ? 10 : 14),
                      Icon(
                        destination.icon,
                        color: destination.accent,
                        size: widget.compact ? 20 : 25,
                      ),
                      SizedBox(width: widget.compact ? 10 : 14),
                      Expanded(
                        child: Text(
                          destination.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.bone,
                            fontSize: widget.compact ? 15 : 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),
                      SizedBox(width: widget.compact ? 6 : 10),
                      if (destination.enabled)
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: destination.accent,
                          size: widget.compact ? 19 : 24,
                        )
                      else
                        Text(
                          'SOON',
                          style: TextStyle(
                            color: AppColors.sand.withValues(alpha: 0.4),
                            fontSize: widget.compact ? 7 : 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuDescriptionCard extends StatelessWidget {
  const _MenuDescriptionCard({
    required this.compact,
    required this.destination,
  });

  final bool compact;
  final _MenuDestination destination;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey('description-${destination.id}'),
        padding: EdgeInsets.fromLTRB(
          compact ? 15 : 20,
          compact ? 13 : 17,
          compact ? 15 : 20,
          compact ? 14 : 18,
        ),
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(compact ? 14 : 18),
          border: Border.all(
            color: destination.accent.withValues(alpha: 0.9),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.52),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  destination.icon,
                  color: destination.accent,
                  size: compact ? 20 : 25,
                ),
                SizedBox(width: compact ? 8 : 11),
                Expanded(
                  child: Text(
                    destination.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.bone,
                      fontSize: compact ? 14 : 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 5 : 7),
            Text(
              destination.subtitle,
              style: TextStyle(
                color: destination.accent,
                fontSize: compact ? 9 : 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: compact ? 7 : 10),
            Text(
              destination.description,
              maxLines: compact ? 3 : 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.sand.withValues(alpha: 0.83),
                height: 1.35,
                fontSize: compact ? 10 : 12.5,
              ),
            ),
            SizedBox(height: compact ? 8 : 11),
            Container(
              height: 1,
              color: destination.accent.withValues(alpha: 0.35),
            ),
            SizedBox(height: compact ? 8 : 10),
            Text(
              destination.sections,
              style: TextStyle(
                color: AppColors.bone.withValues(alpha: 0.68),
                fontSize: compact ? 7 : 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
            SizedBox(height: compact ? 7 : 9),
            Text(
              destination.enabled ? 'AVAILABLE' : 'COMING SOON',
              style: TextStyle(
                color: destination.enabled
                    ? AppColors.health
                    : AppColors.sand.withValues(alpha: 0.48),
                fontSize: compact ? 7.5 : 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuDestination {
  const _MenuDestination({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.sections,
    required this.icon,
    required this.accent,
    required this.enabled,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String sections;
  final IconData icon;
  final Color accent;
  final bool enabled;
}
