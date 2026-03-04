class ResourceConfig {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final int tier;
  final double baseCapacity;
  final double capacityGrowth;

  const ResourceConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.tier,
    required this.baseCapacity,
    required this.capacityGrowth,
  });

  factory ResourceConfig.fromJson(Map<String, dynamic> json) {
    return ResourceConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      tier: json['tier'] as int,
      baseCapacity: (json['baseCapacity'] as num).toDouble(),
      capacityGrowth: (json['capacityGrowth'] as num).toDouble(),
    );
  }
}
