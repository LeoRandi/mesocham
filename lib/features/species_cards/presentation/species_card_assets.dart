import '../domain/entities/species_card.dart';

extension SpeciesCardAsset on SpeciesCard {
  String get assetPath => switch (this) {
    SpeciesCard.superPredator => 'assets/species_cards/superdepredador.jpg',
    SpeciesCard.packPower => 'assets/species_cards/poder_de_la_manada.jpg',
    SpeciesCard.sourceOfLife => 'assets/species_cards/fuente_de_la_vida.jpg',
    SpeciesCard.kingOfTheSkies => 'assets/species_cards/rey_de_los_cielos.jpg',
    SpeciesCard.shadowHunter =>
      'assets/species_cards/cazador_de_las_sombras.jpg',
    SpeciesCard.colossusAmongGiants =>
      'assets/species_cards/coloso_entre_gigantes.jpg',
    SpeciesCard.armoredBeast => 'assets/species_cards/bestia_acorazada.jpg',
    SpeciesCard.unstoppableClash => 'assets/species_cards/choque_invatible.jpg',
  };
}
