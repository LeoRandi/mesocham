import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PlayerPreferences {
  PlayerPreferences({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _playerNameKey = 'player_name';
  static const _unlockedChampionIdsKey = 'unlocked_champion_ids';
  static const _championCollectionCountsKey = 'champion_collection_counts';
  static const _discoveredChampionIdsKey = 'discovered_champion_ids';

  final SharedPreferencesAsync _preferences;

  Future<String?> getPlayerName() async {
    final playerName = (await _preferences.getString(_playerNameKey))?.trim();
    return playerName == null || playerName.isEmpty ? null : playerName;
  }

  Future<void> savePlayerName(String playerName) {
    return _preferences.setString(_playerNameKey, playerName.trim());
  }

  Future<List<String>> getUnlockedChampionIds() async {
    return (await getDiscoveredChampionIds()).toList(growable: false);
  }

  Future<void> saveUnlockedChampionIds(Iterable<String> championIds) async {
    final uniqueIds = championIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final currentCounts = await getChampionCollectionCounts();
    await saveChampionCollectionCounts({
      ...currentCounts,
      for (final id in uniqueIds) id: currentCounts[id] ?? 1,
    });
  }

  Future<void> unlockChampion(String championId) async {
    final normalizedId = championId.trim();
    if (normalizedId.isEmpty) return;

    final counts = await getChampionCollectionCounts();
    if ((counts[normalizedId] ?? 0) > 0) return;

    await saveChampionCollectionCounts({...counts, normalizedId: 1});
  }

  Future<Map<String, int>> getChampionCollectionCounts() async {
    final counts = <String, int>{};
    final encodedCounts = await _preferences.getString(
      _championCollectionCountsKey,
    );
    var decodedStoredCounts = false;

    if (encodedCounts != null) {
      try {
        final decoded = jsonDecode(encodedCounts);
        if (decoded is Map<String, dynamic>) {
          decodedStoredCounts = true;
          for (final MapEntry(:key, :value) in decoded.entries) {
            final normalizedId = key.trim();
            final count = value is num ? value.toInt() : null;
            if (normalizedId.isNotEmpty && count != null && count > 0) {
              counts[normalizedId] = count;
            }
          }
        }
      } on FormatException {
        // Fall through to the legacy unlocked-ID migration below.
      }
    }

    if (!decodedStoredCounts) {
      final legacyIds =
          await _preferences.getStringList(_unlockedChampionIdsKey) ?? const [];
      for (final id in legacyIds) {
        final normalizedId = id.trim();
        if (normalizedId.isNotEmpty) {
          counts.putIfAbsent(normalizedId, () => 1);
        }
      }
    }

    return Map.unmodifiable(counts);
  }

  Future<Set<String>> getDiscoveredChampionIds() async {
    final discoveredIds = <String>{};
    final storedDiscoveredIds =
        await _preferences.getStringList(_discoveredChampionIdsKey) ?? const [];
    final legacyUnlockedIds =
        await _preferences.getStringList(_unlockedChampionIdsKey) ?? const [];

    for (final id in [...storedDiscoveredIds, ...legacyUnlockedIds]) {
      final normalizedId = id.trim();
      if (normalizedId.isNotEmpty) {
        discoveredIds.add(normalizedId);
      }
    }
    discoveredIds.addAll((await getChampionCollectionCounts()).keys);

    return Set.unmodifiable(discoveredIds);
  }

  Future<void> saveChampionCollectionCounts(
    Map<String, int> championCounts,
  ) async {
    final discoveredIds = (await getDiscoveredChampionIds()).toSet();
    final normalizedCounts = <String, int>{};
    for (final MapEntry(:key, :value) in championCounts.entries) {
      final normalizedId = key.trim();
      if (normalizedId.isNotEmpty && value > 0) {
        normalizedCounts[normalizedId] = value;
        discoveredIds.add(normalizedId);
      }
    }

    await _preferences.setString(
      _championCollectionCountsKey,
      jsonEncode(normalizedCounts),
    );
    await _preferences.setStringList(
      _unlockedChampionIdsKey,
      discoveredIds.toList(growable: false),
    );
    await _preferences.setStringList(
      _discoveredChampionIdsKey,
      discoveredIds.toList(growable: false),
    );
  }

  Future<void> addChampion(String championId) async {
    final normalizedId = championId.trim();
    if (normalizedId.isEmpty) return;

    final counts = await getChampionCollectionCounts();
    await saveChampionCollectionCounts({
      ...counts,
      normalizedId: (counts[normalizedId] ?? 0) + 1,
    });
  }
}
