class PlanetConfig {
  final String id;
  final String name;
  final int order;
  final bool unlockedByDefault;

  const PlanetConfig({
    required this.id,
    required this.name,
    required this.order,
    this.unlockedByDefault = false,
  });

  factory PlanetConfig.fromJson(Map<String, dynamic> json) {
    return PlanetConfig(
      id: (json['id'] ?? json['planetId'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? json['id'] ?? '').toString(),
      order: (json['order'] as num?)?.toInt() ?? 0,
      unlockedByDefault: (json['unlockedByDefault'] as bool?) ??
          ((json['starting'] as bool?) ?? false),
    );
  }
}
