import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../battle/data/presets/champion_presets.dart';
import '../../../battle/domain/entities/champion.dart';
import '../../../battle/domain/entities/champion_preset.dart';
import '../../../battle/presentation/widgets/champion_type_emblem.dart';
import '../../data/player_preferences.dart';
import '../widgets/home_backdrop.dart';
import '../widgets/starter_champion_dialog.dart';

final List<ChampionPreset> _starterChampions = List.unmodifiable([
  ChampionPresets.byId['ornithosuchus']!,
  ChampionPresets.byId['protoceratops']!,
  ChampionPresets.byId['utahraptor']!,
]);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _promptController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat(reverse: true);
  late final Animation<double> _promptOpacity = CurvedAnimation(
    parent: _promptController,
    curve: Curves.easeInOut,
  );
  final _playerPreferences = PlayerPreferences();

  var _openingMenu = false;

  Future<void> _openMenu() async {
    if (_openingMenu) return;
    _openingMenu = true;

    try {
      final savedPlayerName = await _playerPreferences.getPlayerName();
      final unlockedChampionIds = await _playerPreferences
          .getUnlockedChampionIds();
      if (!mounted) return;

      if (savedPlayerName == null) {
        final playerName = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          barrierColor: AppColors.ink.withValues(alpha: 0.78),
          builder: (context) => const _PlayerNameDialog(),
        );
        if (!mounted) return;

        if (playerName == null) {
          _openingMenu = false;
          return;
        }
        await _playerPreferences.savePlayerName(playerName);
        if (!mounted) return;
      }

      if (unlockedChampionIds.isEmpty) {
        final starterChampionId = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          barrierColor: AppColors.ink.withValues(alpha: 0.82),
          builder: (context) =>
              StarterChampionDialog(champions: _starterChampions),
        );
        if (!mounted) return;

        if (starterChampionId == null) {
          _openingMenu = false;
          return;
        }
        await _playerPreferences.unlockChampion(starterChampionId);
        if (!mounted) return;
      }

      Navigator.of(context).pushNamed('/loading', arguments: '/menu');
    } on Object {
      if (!mounted) return;
      _openingMenu = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update player data. Please try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _openMenu,
        const SingleActivator(LogicalKeyboardKey.space): _openMenu,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Semantics(
            button: true,
            label: 'Comenzar la expedición en Mesozoic Champions',
            onTap: _openMenu,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openMenu,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const HomeBackdrop(),
                    _HomeTitle(promptOpacity: _promptOpacity),
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

class _HomeTitle extends StatelessWidget {
  const _HomeTitle({required this.promptOpacity});

  final Animation<double> promptOpacity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxHeight < 430 || constraints.maxWidth < 760;
          final emblemSize = compact ? 78.0 : 122.0;
          final titleSize = compact ? 41.0 : 70.0;
          final titleSideWidth = titleSize * 6.5;
          final contentWidth = (constraints.maxWidth * 0.94)
              .clamp(0.0, 1540.0)
              .toDouble();

          return Center(
            child: SizedBox(
              width: contentWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: titleSideWidth,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _OutlinedTitleWord(
                                text: 'MESOZOIC',
                                fontSize: titleSize,
                              ),
                            ),
                          ),
                          SizedBox(width: compact ? 15 : 28),
                          _ChampionLogo(size: emblemSize),
                          SizedBox(width: compact ? 15 : 28),
                          SizedBox(
                            width: titleSideWidth,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _OutlinedTitleWord(
                                text: 'CHAMPIONS',
                                fontSize: titleSize,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 16 : 27),
                  Center(
                    child: FadeTransition(
                      opacity: promptOpacity,
                      child: Text(
                        'Comenzar la expedición',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.bone,
                          fontSize: compact ? 12 : 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: compact ? 3.1 : 4.8,
                          shadows: const [
                            Shadow(
                              color: Color(0xB3130F0B),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlayerNameDialog extends StatefulWidget {
  const _PlayerNameDialog();

  @override
  State<_PlayerNameDialog> createState() => _PlayerNameDialogState();
}

class _PlayerNameDialogState extends State<_PlayerNameDialog> {
  final _nameController = TextEditingController();
  var _canConfirm = false;

  void _updateConfirmationState(String value) {
    final canConfirm = value.trim().isNotEmpty;
    if (canConfirm != _canConfirm) {
      setState(() => _canConfirm = canConfirm);
    }
  }

  void _confirm() {
    final playerName = _nameController.text.trim();
    if (playerName.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(playerName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Container(
          width: 460,
          padding: const EdgeInsets.fromLTRB(28, 25, 28, 24),
          decoration: BoxDecoration(
            color: AppColors.deepEarth,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.amber, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.58),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: AppColors.amber.withValues(alpha: 0.14),
                blurRadius: 22,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.account_circle_rounded,
                  color: AppColors.amber,
                  size: 44,
                ),
                const SizedBox(height: 10),
                Text(
                  'Bienvenido, paleontólogo',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.bone,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Elige el nombre que te representará en tu expedición.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.sand.withValues(alpha: 0.78),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.username],
                  onChanged: _updateConfirmationState,
                  onSubmitted: (_) {
                    if (_canConfirm) _confirm();
                  },
                  style: const TextStyle(
                    color: AppColors.bone,
                    fontWeight: FontWeight.w700,
                  ),
                  cursorColor: AppColors.amber,
                  decoration: InputDecoration(
                    labelText: 'Nombre del jugador',
                    hintText: 'Ingresa tu nombre',
                    prefixIcon: const Icon(Icons.person_rounded),
                    filled: true,
                    fillColor: AppColors.ink.withValues(alpha: 0.58),
                    labelStyle: const TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.sand.withValues(alpha: 0.42),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.amber,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _canConfirm ? _confirm : null,
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlinedTitleWord extends StatelessWidget {
  const _OutlinedTitleWord({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      height: 0.9,
      letterSpacing: fontSize * 0.035,
    );

    return Stack(
      children: [
        Text(
          text,
          style: baseStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize * 0.095
              ..strokeJoin = StrokeJoin.round
              ..color = AppColors.ink,
          ),
        ),
        Text(
          text,
          style: baseStyle.copyWith(
            color: AppColors.bone,
            shadows: const [
              Shadow(
                color: Color(0xA6130F0B),
                blurRadius: 15,
                offset: Offset(0, 6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChampionLogo extends StatelessWidget {
  const _ChampionLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ChampionTypeEmblem(
      type: ChampionType.jaw,
      size: size,
      shadows: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.62),
          blurRadius: size * 0.2,
          offset: Offset(0, size * 0.08),
        ),
        BoxShadow(
          color: AppColors.bone.withValues(alpha: 0.24),
          blurRadius: size * 0.09,
          spreadRadius: size * 0.025,
        ),
      ],
    );
  }
}
