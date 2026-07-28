import '../../../champions/domain/entities/champion.dart';

enum SpeciesCard {
  superPredator(
    championType: ChampionType.jaw,
    name: 'Superdepredador',
    effectDescription: '+50% potency on all damaging attacks.',
  ),
  packPower(
    championType: ChampionType.nest,
    name: 'Poder de la manada',
    effectDescription:
        'Every move resolves twice, including its secondary effects.',
  ),
  sourceOfLife(
    championType: ChampionType.water,
    name: 'Fuente de la vida',
    effectDescription:
        'Enemy critical attacks deal 66% less damage, and statuses they cause '
        'are reduced to exactly 1 turn.',
  ),
  kingOfTheSkies(
    championType: ChampionType.wings,
    name: 'Rey de los cielos',
    effectDescription:
        'When equipped, summons and equips three different random companions.',
  ),
  shadowHunter(
    championType: ChampionType.claws,
    name: 'Cazador de las sombras',
    effectDescription:
        'Critical attacks deal 66% more damage, and statuses they cause last '
        '2 additional turns.',
  ),
  colossusAmongGiants(
    championType: ChampionType.titan,
    name: 'Coloso entre gigantes',
    effectDescription:
        'Regenerates 8% of maximum HP at the end of every turn while active.',
  ),
  armoredBeast(
    championType: ChampionType.plates,
    name: 'Bestia acorazada',
    effectDescription:
        'Reduces all incoming damage by 33%, including while in reserve.',
  ),
  unstoppableClash(
    championType: ChampionType.crown,
    name: 'Choque invatible',
    effectDescription:
        "After a draw, the attack's secondary effects are still applied.",
  );

  const SpeciesCard({
    required this.championType,
    required this.name,
    required this.effectDescription,
  });

  final ChampionType championType;
  final String name;
  final String effectDescription;

  static SpeciesCard forChampionType(ChampionType type) {
    return values.firstWhere((card) => card.championType == type);
  }
}
