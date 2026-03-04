class ContractRequirementConfig {
  final String? resourceId;
  final String? buildingId;
  final double amount;

  const ContractRequirementConfig({
    this.resourceId,
    this.buildingId,
    required this.amount,
  });

  factory ContractRequirementConfig.fromJson(Map<String, dynamic> json) {
    return ContractRequirementConfig(
      resourceId: json['resource'] as String? ?? json['resourceId'] as String?,
      buildingId: json['buildingId'] as String?,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class ContractConfig {
  final String id;
  final String title;
  final String description;
  final String type;
  final bool repeatable;
  final List<ContractRequirementConfig> requirements;
  final Map<String, double> rewards;

  const ContractConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.repeatable,
    required this.requirements,
    required this.rewards,
  });

  factory ContractConfig.fromJson(Map<String, dynamic> json) {
    return ContractConfig(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'delivery',
      repeatable: (json['repeatable'] as bool?) ?? false,
      requirements: (json['requirements'] as List)
          .map((e) => ContractRequirementConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      rewards: (json['rewards'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }
}
