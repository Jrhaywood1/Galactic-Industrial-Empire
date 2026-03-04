import '../config/game_config.dart';

class GameState {
  Map<String, double> resources;
  Map<String, int> buildingLevels;
  Set<String> unlockedTechs;
  Set<String> completedContracts;
  int lastTickTimestamp;
  int totalPlaytimeSeconds;

  GameState({
    required this.resources,
    required this.buildingLevels,
    required this.unlockedTechs,
    required this.completedContracts,
    required this.lastTickTimestamp,
    this.totalPlaytimeSeconds = 0,
  });

  factory GameState.newGame(GameConfig config) {
    final resources = <String, double>{
      for (final r in config.resourceList) r.id: 0.0,
    };
    resources['credits'] = 50.0;

    return GameState(
      resources: resources,
      buildingLevels: {for (final b in config.buildingList) b.id: 0},
      unlockedTechs: {},
      completedContracts: {},
      lastTickTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => {
        'resources': resources,
        'buildingLevels': buildingLevels,
        'unlockedTechs': unlockedTechs.toList(),
        'completedContracts': completedContracts.toList(),
        'lastTickTimestamp': lastTickTimestamp,
        'totalPlaytimeSeconds': totalPlaytimeSeconds,
      };

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      resources: (json['resources'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      buildingLevels: (json['buildingLevels'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      unlockedTechs: Set<String>.from(json['unlockedTechs'] as List),
      completedContracts: Set<String>.from((json['completedContracts'] as List?) ?? const []),
      lastTickTimestamp: json['lastTickTimestamp'] as int,
      totalPlaytimeSeconds: (json['totalPlaytimeSeconds'] as int?) ?? 0,
    );
  }
}
