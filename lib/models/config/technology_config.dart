class TechEffect {
  final String type;
  final String? target;
  final double? value;

  const TechEffect({
    required this.type,
    this.target,
    this.value,
  });

  factory TechEffect.fromJson(Map<String, dynamic> json) {
    return TechEffect(
      type: json['type'] as String,
      target: json['target'] as String?,
      value: (json['value'] as num?)?.toDouble(),
    );
  }
}

class TechnologyConfig {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int tier;
  final Map<String, double> cost;
  final List<String> prerequisites;
  final List<TechEffect> effects;

  const TechnologyConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.tier,
    required this.cost,
    required this.prerequisites,
    required this.effects,
  });

  factory TechnologyConfig.fromJson(Map<String, dynamic> json) {
    return TechnologyConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      tier: json['tier'] as int,
      cost: (json['cost'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      prerequisites: List<String>.from(json['prerequisites'] as List),
      effects: (json['effects'] as List)
          .map((e) => TechEffect.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
