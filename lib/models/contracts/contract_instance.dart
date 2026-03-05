class ContractInstance {
  final String instanceId;
  final String templateId;
  final String type;

  final Map<String, int> requirements;
  final Map<String, int> delivered;
  final Map<String, int> rewards;

  final int? acceptedAtMs;
  final int? expiresAtMs;

  final bool completed;

  const ContractInstance({
    required this.instanceId,
    required this.templateId,
    required this.type,
    required this.requirements,
    required this.delivered,
    required this.rewards,
    required this.acceptedAtMs,
    required this.expiresAtMs,
    required this.completed,
  });

  ContractInstance copyWith({
    String? instanceId,
    String? templateId,
    String? type,
    Map<String, int>? requirements,
    Map<String, int>? delivered,
    Map<String, int>? rewards,
    int? acceptedAtMs,
    int? expiresAtMs,
    bool? completed,
  }) {
    return ContractInstance(
      instanceId: instanceId ?? this.instanceId,
      templateId: templateId ?? this.templateId,
      type: type ?? this.type,
      requirements: requirements ?? this.requirements,
      delivered: delivered ?? this.delivered,
      rewards: rewards ?? this.rewards,
      acceptedAtMs: acceptedAtMs ?? this.acceptedAtMs,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
      completed: completed ?? this.completed,
    );
  }

  bool isComplete() {
    for (final entry in requirements.entries) {
      final need = entry.value;
      final have = delivered[entry.key] ?? 0;
      if (have < need) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'instanceId': instanceId,
        'templateId': templateId,
        'type': type,
        'requirements': requirements,
        'delivered': delivered,
        'rewards': rewards,
        'acceptedAtMs': acceptedAtMs,
        'expiresAtMs': expiresAtMs,
        'completed': completed,
      };

  factory ContractInstance.fromJson(Map<String, dynamic> json) {
    final mapReq = _intMap(json['requirements']);
    final mapDel = _intMap(json['delivered']);
    final mapRew = _intMap(json['rewards']);

    return ContractInstance(
      instanceId: (json['instanceId'] ?? '').toString(),
      templateId: (json['templateId'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      requirements: mapReq,
      delivered: mapDel,
      rewards: mapRew,
      acceptedAtMs: (json['acceptedAtMs'] is num) ? (json['acceptedAtMs'] as num).toInt() : null,
      expiresAtMs: (json['expiresAtMs'] is num) ? (json['expiresAtMs'] as num).toInt() : null,
      completed: json['completed'] == true,
    );
  }

  static Map<String, int> _intMap(dynamic raw) {
    if (raw is Map) {
      final mapD = <String, int>{};
      raw.forEach((k, v) {
        final key = k.toString();
        if (v is num) {
          mapD[key] = v.toInt();
        } else if (v is String) {
          mapD[key] = int.tryParse(v) ?? 0;
        }
      });
      return mapD;
    }
    return <String, int>{};
  }
}
