import 'dart:math' as math;

import '../../../companions/domain/entities/companion.dart';

class CompanionRandomizer {
  CompanionRandomizer({math.Random? random})
    : _random = random ?? math.Random();

  final math.Random _random;

  Companion? chooseAppearing({required bool beetleBlocked}) {
    final candidates = [
      for (final companion in Companion.values)
        if (companion != Companion.beetle || !beetleBlocked) companion,
    ];
    return chooseFrom(candidates);
  }

  Companion? chooseFrom(Iterable<Companion> companions) {
    final candidates = companions.toList(growable: false);
    if (candidates.isEmpty) return null;
    return candidates[_random.nextInt(candidates.length)];
  }
}
