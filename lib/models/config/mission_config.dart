import 'building_config.dart';

class MissionConfig {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int tier;
  final Map<String, double> requirements;
  final Map<String, double> rewards;
  final int cooldownSeconds;
  final UnlockCondition? unlockCondition;

  const MissionConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.tier,
    required this.requirements,
    required this.rewards,
    required this.cooldownSeconds,
    this.unlockCondition,
  });

  factory MissionConfig.fromJson(Map<String, dynamic> json) {
    return MissionConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      tier: json['tier'] as int,
      requirements: (json['requirements'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      rewards: (json['rewards'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      cooldownSeconds: json['cooldownSeconds'] as int,
      unlockCondition: json['unlockCondition'] != null
          ? UnlockCondition.fromJson(
              json['unlockCondition'] as Map<String, dynamic>)
          : null,
    );
  }
}
