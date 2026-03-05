class ContractTemplateConfig {
  final String id;
  final String type; // delivery | multi | manufacturing | rush
  final Map<String, int> requirements; // resourceId -> amount
  final Map<String, int> rewards; // rewardId/resourceId -> amount
  final int tier;
  final int weight;

  /// Rush duration in seconds (JSON field: rushTime).
  final int? rushTime;

  ContractTemplateConfig({
    required this.id,
    required this.type,
    required this.requirements,
    required this.rewards,
    required this.tier,
    required this.weight,
    this.rushTime,
  });

  factory ContractTemplateConfig.fromJson(Map<String, dynamic> json) {
    return ContractTemplateConfig(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      requirements: _intMap(json['requirements']),
      rewards: _intMap(json['rewards']),
      tier: (json['tier'] is num) ? (json['tier'] as num).toInt() : 1,
      weight: (json['weight'] is num) ? (json['weight'] as num).toInt() : 1,
      rushTime: (json['rushTime'] is num) ? (json['rushTime'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'requirements': requirements,
        'rewards': rewards,
        'tier': tier,
        'weight': weight,
        if (rushTime != null) 'rushTime': rushTime,
      };

  static Map<String, int> _intMap(dynamic raw) {
    if (raw is Map) {
      final out = <String, int>{};
      raw.forEach((k, v) {
        final key = k.toString();
        if (v is num) {
          out[key] = v.toInt();
        } else if (v is String) {
          out[key] = int.tryParse(v) ?? 0;
        }
      });
      return out;
    }
    return <String, int>{};
  }
}
