enum Companion {
  dragonfly(
    name: 'Libélula',
    effectDescription: 'All moves deal 10 additional damage.',
  ),
  ammonoidea(
    name: 'Ammonoidea',
    effectDescription: 'Increases maximum and current HP by 20.',
  ),
  weta(
    name: 'Weta',
    effectDescription:
        'Inflicts permanent Famine on the rival, reducing maximum HP by 10 '
        'at the end of every turn.',
  ),
  horseshoeCrab(
    name: 'Cangrejo herradura',
    effectDescription: 'Reduces damage received from every source by 10.',
  ),
  longisquama(
    name: 'Longuisquama',
    effectDescription: 'Critical attacks deal 30 additional damage.',
  ),
  didelphodon(
    name: 'Didelphodon',
    effectDescription: 'Every damaging move applies one Bleeding stack.',
  ),
  simosuchus(
    name: 'Simosuchus',
    effectDescription: 'Enemy champion debuffs cannot be applied.',
  ),
  iberomesornis(
    name: 'Iberomesornis',
    effectDescription: 'Restores 10 HP whenever the bearer wins a showdown.',
  ),
  beetle(
    name: 'Escarabajo',
    effectDescription: 'Doubles the effects of every other companion.',
  ),
  henodus(
    name: 'Henodus',
    effectDescription:
        'Provides Jagged Scales and reapplies it at the end of every turn.',
  );

  const Companion({required this.name, required this.effectDescription});

  final String name;
  final String effectDescription;
}
