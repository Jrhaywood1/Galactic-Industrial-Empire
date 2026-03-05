class PlanetUnlockCondition {
  final String type;
  final String? resourceId;
  final double? amount;
  final String? buildingId;
  final int? level;

  const PlanetUnlockCondition({
    required this.type,
    this.resourceId,
    this.amount,
    this.buildingId,
    this.level,
  });

  factory PlanetUnlockCondition.fromJson(Map<String, dynamic> json) {
    return PlanetUnlockCondition(
      type: (json['type'] ?? '').toString(),
      resourceId: (json['resourceId'] ?? json['resource'])?.toString(),
      amount: (json['amount'] as num?)?.toDouble(),
      buildingId: (json['buildingId'] ?? json['building'])?.toString(),
      level: (json['level'] as num?)?.toInt(),
    );
  }
}

class PlanetUnlockConfig {
  final String planetId;
  final String mode; // all | any
  final List<PlanetUnlockCondition> conditions;

  const PlanetUnlockConfig({
    required this.planetId,
    this.mode = 'all',
    required this.conditions,
  });

  factory PlanetUnlockConfig.fromJson(Map<String, dynamic> json) {
    final rawConditions = (json['conditions'] as List?) ?? const <dynamic>[];
    return PlanetUnlockConfig(
      planetId: (json['planetId'] ?? json['planet'] ?? '').toString(),
      mode: (json['mode'] ?? 'all').toString(),
      conditions: rawConditions
          .whereType<Map>()
          .map((c) => PlanetUnlockCondition.fromJson(Map<String, dynamic>.from(c)))
          .toList(growable: false),
    );
  }
}
