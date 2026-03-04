import 'building_config.dart';

class AchievementCondition {
  final String type;
  final String? buildingId;
  final String? resourceId;
  final int? level;
  final double? amount;
  final int? count;
  final int? seconds;
  final int? tier;

  const AchievementCondition({
    required this.type,
    this.buildingId,
    this.resourceId,
    this.level,
    this.amount,
    this.count,
    this.seconds,
    this.tier,
  });

  factory AchievementCondition.fromJson(Map<String, dynamic> json) {
    return AchievementCondition(
      type: json['type'] as String,
      buildingId: json['buildingId'] as String?,
      resourceId: json['resourceId'] as String?,
      level: json['level'] as int?,
      amount: (json['amount'] as num?)?.toDouble(),
      count: json['count'] as int?,
      seconds: json['seconds'] as int?,
      tier: json['tier'] as int?,
    );
  }
}

class AchievementConfig {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final AchievementCondition condition;
  final Map<String, double> reward;

  const AchievementConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.condition,
    required this.reward,
  });

  factory AchievementConfig.fromJson(Map<String, dynamic> json) {
    return AchievementConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      category: json['category'] as String,
      condition: AchievementCondition.fromJson(
          json['condition'] as Map<String, dynamic>),
      reward: (json['reward'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }
}
