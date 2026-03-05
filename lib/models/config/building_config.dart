class UnlockCondition {
  final String type;
  final String? buildingId;
  final String? resourceId;
  final String? prestigeType;
  final int? level;
  final double? amount;

  const UnlockCondition({
    required this.type,
    this.buildingId,
    this.resourceId,
    this.prestigeType,
    this.level,
    this.amount,
  });

  factory UnlockCondition.fromJson(Map<String, dynamic> json) {
    return UnlockCondition(
      type: json['type'] as String,
      buildingId: json['buildingId'] as String?,
      resourceId: json['resourceId'] as String?,
      prestigeType: json['prestigeType'] as String?,
      level: json['level'] as int?,
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }
}

class BuildingMilestoneConfig {
  final int count;
  final double outputMultiplier;
  final double speedMultiplier;

  const BuildingMilestoneConfig({
    required this.count,
    this.outputMultiplier = 1.0,
    this.speedMultiplier = 1.0,
  });

  factory BuildingMilestoneConfig.fromJson(Map<String, dynamic> json) {
    return BuildingMilestoneConfig(
      count: (json['count'] as num).toInt(),
      outputMultiplier: (json['outputMultiplier'] as num?)?.toDouble() ?? 1.0,
      speedMultiplier: (json['speedMultiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class BuildingConfig {
  final String id;
  final String name;
  final String description;
  final String category;
  final int tier;
  final String icon;
  final UnlockCondition? unlockCondition;
  final Map<String, double> baseCost;
  final double costScaling;
  final Map<String, double> produces;
  final Map<String, double> consumes;
  final double productionMultiplierPerLevel;
  final double cycleSeconds;
  final int maxLevel;
  final List<BuildingMilestoneConfig> milestones;

  const BuildingConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.tier,
    required this.icon,
    this.unlockCondition,
    required this.baseCost,
    required this.costScaling,
    required this.produces,
    required this.consumes,
    required this.productionMultiplierPerLevel,
    this.cycleSeconds = 4.0,
    required this.maxLevel,
    this.milestones = const <BuildingMilestoneConfig>[],
  });

  factory BuildingConfig.fromJson(Map<String, dynamic> json) {
    final milestones = ((json['milestones'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((m) => BuildingMilestoneConfig.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false)
      ..sort((a, b) => a.count.compareTo(b.count));

    return BuildingConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      tier: json['tier'] as int,
      icon: json['icon'] as String,
      unlockCondition: json['unlockCondition'] != null
          ? UnlockCondition.fromJson(json['unlockCondition'] as Map<String, dynamic>)
          : null,
      baseCost: (json['baseCost'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      costScaling: (json['costScaling'] as num).toDouble(),
      produces: (json['produces'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      consumes: (json['consumes'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      productionMultiplierPerLevel:
          (json['productionMultiplierPerLevel'] as num).toDouble(),
      cycleSeconds: (json['cycleSeconds'] as num?)?.toDouble() ?? 4.0,
      maxLevel: json['maxLevel'] as int,
      milestones: milestones,
    );
  }
}
