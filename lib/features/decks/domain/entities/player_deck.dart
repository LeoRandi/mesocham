class PlayerDeck {
  PlayerDeck({
    required this.id,
    required String name,
    required List<String> championIds,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    this.schemaVersion = currentSchemaVersion,
  }) : name = normalizeName(name),
       championIds = List.unmodifiable(championIds) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'A deck needs a stable ID.');
    }
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'A deck needs a name.');
    }
    if (championIds.length != championCount ||
        championIds.any((championId) => championId.trim().isEmpty)) {
      throw ArgumentError.value(
        championIds,
        'championIds',
        'A deck needs exactly $championCount champions.',
      );
    }
  }

  static const currentSchemaVersion = 1;
  static const championCount = 3;
  static const maxNameLength = 12;

  factory PlayerDeck.create({
    required String name,
    required List<String> championIds,
    required bool isFavorite,
    DateTime? now,
  }) {
    final timestamp = (now ?? DateTime.now()).toUtc();
    return PlayerDeck(
      id: 'deck_${timestamp.microsecondsSinceEpoch}',
      name: name,
      championIds: championIds,
      isFavorite: isFavorite,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  final int schemaVersion;
  final String id;
  final String name;
  final List<String> championIds;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlayerDeck updated({
    required String name,
    required List<String> championIds,
    required bool isFavorite,
    DateTime? now,
  }) {
    return PlayerDeck(
      schemaVersion: currentSchemaVersion,
      id: id,
      name: name,
      championIds: championIds,
      isFavorite: isFavorite,
      createdAt: createdAt,
      updatedAt: (now ?? DateTime.now()).toUtc(),
    );
  }

  static String filterNameInput(String input) {
    final filtered = StringBuffer();
    var characterCount = 0;
    for (final rune in input.runes) {
      if (!_isAllowedNameRune(rune)) continue;
      if (characterCount == maxNameLength) break;
      filtered.writeCharCode(rune);
      characterCount++;
    }
    return filtered.toString();
  }

  static String normalizeName(String input) => filterNameInput(input).trim();

  static bool _isAllowedNameRune(int rune) {
    final isAsciiLetter =
        (rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A);
    final isDigit = rune >= 0x30 && rune <= 0x39;
    final isLatinLetter =
        (rune >= 0x00C0 && rune <= 0x00D6) ||
        (rune >= 0x00D8 && rune <= 0x00F6) ||
        (rune >= 0x00F8 && rune <= 0x024F);
    return isAsciiLetter ||
        isDigit ||
        isLatinLetter ||
        rune == 0x20 ||
        rune == 0x2D ||
        rune == 0x2E;
  }

  Map<String, Object> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'name': name,
    'championIds': championIds,
    'isFavorite': isFavorite,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  static PlayerDeck? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;

    final id = json['id'];
    final name = json['name'];
    final encodedChampionIds = json['championIds'];
    final isFavorite = json['isFavorite'];
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    final updatedAt = DateTime.tryParse(json['updatedAt']?.toString() ?? '');
    if (id is! String ||
        name is! String ||
        encodedChampionIds is! List ||
        isFavorite is! bool ||
        createdAt == null ||
        updatedAt == null) {
      return null;
    }

    final championIds = <String>[];
    for (final championId in encodedChampionIds) {
      if (championId is! String || championId.trim().isEmpty) return null;
      championIds.add(championId.trim());
    }

    try {
      return PlayerDeck(
        schemaVersion: json['schemaVersion'] is num
            ? (json['schemaVersion']! as num).toInt()
            : currentSchemaVersion,
        id: id,
        name: normalizeName(name).isEmpty ? 'Deck' : name,
        championIds: championIds,
        isFavorite: isFavorite,
        createdAt: createdAt.toUtc(),
        updatedAt: updatedAt.toUtc(),
      );
    } on ArgumentError {
      return null;
    }
  }
}
