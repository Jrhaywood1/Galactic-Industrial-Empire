class ContractRequirement {
  final String resource;
  final int amount;
  ContractRequirement({required this.resource, required this.amount});

  factory ContractRequirement.fromJson(Map<String, dynamic> j) =>
      ContractRequirement(resource: j["resource"], amount: j["amount"]);
}

class ContractRewards {
  final double credits;
  final int premium;
  ContractRewards({required this.credits, required this.premium});

  factory ContractRewards.fromJson(Map<String, dynamic> j) => ContractRewards(
        credits: (j["credits"] as num?)?.toDouble() ?? 0,
        premium: j["premium"] ?? 0,
      );
}

class ContractDef {
  final String id;
  final String title;
  final List<ContractRequirement> requirements;
  final ContractRewards rewards;

  ContractDef({required this.id, required this.title, required this.requirements, required this.rewards});

  factory ContractDef.fromJson(Map<String, dynamic> j) => ContractDef(
        id: j["id"],
        title: j["title"],
        requirements: (j["requirements"] as List).map((e) => ContractRequirement.fromJson(e)).toList(),
        rewards: ContractRewards.fromJson(j["rewards"] ?? {}),
      );
}