import '../../../species_cards/domain/entities/species_card.dart';

class BattleSpeciesCardSlot {
  const BattleSpeciesCardSlot({
    required this.card,
    this.consumed = false,
    this.bearerIndex,
  });

  final SpeciesCard card;
  final bool consumed;
  final int? bearerIndex;

  BattleSpeciesCardSlot equipTo(int index) {
    if (consumed) return this;
    return BattleSpeciesCardSlot(
      card: card,
      consumed: true,
      bearerIndex: index,
    );
  }

  BattleSpeciesCardSlot clearBearer() {
    if (!consumed || bearerIndex == null) return this;
    return BattleSpeciesCardSlot(card: card, consumed: true);
  }
}
