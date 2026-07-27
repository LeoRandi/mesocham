abstract final class ChampionArtworkAssets {
  static String collectionImageFor(String championId) {
    return switch (championId) {
      'ornithosuchus' => 'assets/dinos/ornitosuchus.png',
      _ => 'assets/dinos/$championId.jpg',
    };
  }
}
