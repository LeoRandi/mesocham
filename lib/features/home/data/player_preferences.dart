import 'package:shared_preferences/shared_preferences.dart';

class PlayerPreferences {
  PlayerPreferences({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _playerNameKey = 'player_name';
  static const _unlockedChampionIdsKey = 'unlocked_champion_ids';

  final SharedPreferencesAsync _preferences;

  Future<String?> getPlayerName() async {
    final playerName = (await _preferences.getString(_playerNameKey))?.trim();
    return playerName == null || playerName.isEmpty ? null : playerName;
  }

  Future<void> savePlayerName(String playerName) {
    return _preferences.setString(_playerNameKey, playerName.trim());
  }

  Future<List<String>> getUnlockedChampionIds() async {
    final storedIds =
        await _preferences.getStringList(_unlockedChampionIdsKey) ?? const [];
    return storedIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  Future<void> saveUnlockedChampionIds(Iterable<String> championIds) {
    final uniqueIds = championIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return _preferences.setStringList(_unlockedChampionIdsKey, uniqueIds);
  }

  Future<void> unlockChampion(String championId) async {
    final unlockedIds = await getUnlockedChampionIds();
    final normalizedId = championId.trim();
    if (normalizedId.isEmpty || unlockedIds.contains(normalizedId)) return;

    await saveUnlockedChampionIds([...unlockedIds, normalizedId]);
  }
}
