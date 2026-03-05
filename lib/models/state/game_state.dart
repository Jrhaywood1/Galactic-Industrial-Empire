import '../config/game_config.dart';
import '../contracts/contract_instance.dart';

class GameState {
  Map<String, double> resources;
  Map<String, int> buildingLevels;
  Set<String> unlockedTechs;
  Set<String> completedContracts;

  // ContractSystem persistence.
  List<ContractInstance> activeContracts;
  List<ContractInstance> contractOffers;
  int nextContractRefreshMs;
  int contractRngSeed;
  int contractRefreshCount;
  int contractOfferCounter;

  int lastTickTimestamp;
  int totalPlaytimeSeconds;

  GameState({
    required this.resources,
    required this.buildingLevels,
    required this.unlockedTechs,
    required this.completedContracts,
    required this.lastTickTimestamp,
    this.totalPlaytimeSeconds = 0,
    List<ContractInstance>? activeContracts,
    List<ContractInstance>? contractOffers,
    this.nextContractRefreshMs = 0,
    this.contractRngSeed = 0,
    this.contractRefreshCount = 0,
    this.contractOfferCounter = 0,
  })  : activeContracts = List<ContractInstance>.from(activeContracts ?? const <ContractInstance>[]),
        contractOffers = List<ContractInstance>.from(contractOffers ?? const <ContractInstance>[]);

  factory GameState.newGame(GameConfig config) {
    final resources = {for (final r in config.resourceList) r.id: 0.0};
    resources['credits'] = 50.0;

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    return GameState(
      resources: resources,
      buildingLevels: {for (final b in config.buildingList) b.id: 0},
      unlockedTechs: {},
      completedContracts: {},
      lastTickTimestamp: nowMs,
      // ContractSystem defaults.
      activeContracts: <ContractInstance>[],
      contractOffers: <ContractInstance>[],
      nextContractRefreshMs: nowMs, // generate immediately on first run
      contractRngSeed: nowMs,
      contractRefreshCount: 0,
      contractOfferCounter: 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'resources': resources,
        'buildingLevels': buildingLevels,
        'unlockedTechs': unlockedTechs.toList(),
        'completedContracts': completedContracts.toList(),
        'lastTickTimestamp': lastTickTimestamp,
        'totalPlaytimeSeconds': totalPlaytimeSeconds,
        // ContractSystem
        'activeContracts': activeContracts.map((c) => c.toJson()).toList(growable: false),
        'contractOffers': contractOffers.map((c) => c.toJson()).toList(growable: false),
        'nextContractRefreshMs': nextContractRefreshMs,
        'contractRngSeed': contractRngSeed,
        'contractRefreshCount': contractRefreshCount,
        'contractOfferCounter': contractOfferCounter,
      };

  factory GameState.fromJson(Map json) {
    final activeRaw = (json['activeContracts'] as List?) ?? const [];
    final offersRaw = (json['contractOffers'] as List?) ?? const [];

    return GameState(
      resources: (json['resources'] as Map)
          .map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
      buildingLevels: (json['buildingLevels'] as Map)
          .map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
      unlockedTechs: Set<String>.from((json['unlockedTechs'] as List?) ?? const []),
      completedContracts: Set<String>.from((json['completedContracts'] as List?) ?? const []),
      lastTickTimestamp: (json['lastTickTimestamp'] as num).toInt(),
      totalPlaytimeSeconds: (json['totalPlaytimeSeconds'] as int?) ?? 0,
      activeContracts: activeRaw
          .whereType<Map>()
          .map((m) => ContractInstance.fromJson(m))
          .toList(growable: true),
      contractOffers: offersRaw
          .whereType<Map>()
          .map((m) => ContractInstance.fromJson(m))
          .toList(growable: true),
      nextContractRefreshMs: (json['nextContractRefreshMs'] as num?)?.toInt() ?? 0,
      contractRngSeed: (json['contractRngSeed'] as num?)?.toInt() ?? 0,
      contractRefreshCount: (json['contractRefreshCount'] as num?)?.toInt() ?? 0,
      contractOfferCounter: (json['contractOfferCounter'] as num?)?.toInt() ?? 0,
    );
  }
}
