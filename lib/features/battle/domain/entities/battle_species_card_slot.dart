import '../../../species_cards/domain/entities/species_card.dart';

class BattleSpeciesCardSlot {
  const BattleSpeciesCardSlot({
    required this.card,
    this.consumed = false,
    this.lost = false,
    this.bearerIndex,
  }) : assert(!(consumed && lost)),
       assert(consumed || bearerIndex == null);

  final SpeciesCard card;
  final bool consumed;
  final bool lost;
  final int? bearerIndex;

  BattleSpeciesCardSlot equipTo(int index) {
    if (consumed || lost) return this;
    return BattleSpeciesCardSlot(
      card: card,
      consumed: true,
      bearerIndex: index,
    );
  }

  BattleSpeciesCardSlot markLost() {
    if (consumed || lost) return this;
    return BattleSpeciesCardSlot(card: card, lost: true);
  }

  BattleSpeciesCardSlot clearBearer() {
    if (!consumed || bearerIndex == null) return this;
    return BattleSpeciesCardSlot(card: card, consumed: true);
  }
}
