import '../config/game_config.dart';
import '../contracts/contract_instance.dart';

class GameState {
  Map<String, double> resources;
  Map<String, int> buildingLevels;
  Set<String> unlockedTechs;
  Set<String> completedContracts;

  // Runtime progression state.
  Set<String> unlockedBuildings;
  Map<String, double> cycleProgressSeconds;
  Map<String, double> pendingOfflineEarnings;
  int pendingOfflineSeconds;
  Map<String, int> missionNextAvailableMs;
  String buyAmountSetting;

  String currentPlanetId;
  Set<String> unlockedPlanets;

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
    required this.unlockedBuildings,
    required this.cycleProgressSeconds,
    required this.pendingOfflineEarnings,
    this.pendingOfflineSeconds = 0,
    required this.missionNextAvailableMs,
    this.buyAmountSetting = 'x1',
    this.currentPlanetId = 'planet_1',
    Set<String>? unlockedPlanets,
    required this.lastTickTimestamp,
    this.totalPlaytimeSeconds = 0,
    List<ContractInstance>? activeContracts,
    List<ContractInstance>? contractOffers,
    this.nextContractRefreshMs = 0,
    this.contractRngSeed = 0,
    this.contractRefreshCount = 0,
    this.contractOfferCounter = 0,
  })  : unlockedPlanets = Set<String>.from(unlockedPlanets ?? const <String>{'planet_1'}),
        activeContracts =
            List<ContractInstance>.from(activeContracts ?? const <ContractInstance>[]),
        contractOffers =
            List<ContractInstance>.from(contractOffers ?? const <ContractInstance>[]);

  factory GameState.newGame(GameConfig config) {
    final resources = {for (final r in config.resourceList) r.id: 0.0};
    resources['credits'] = 50.0;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final initialPlanetId =
        config.planetList.isNotEmpty ? config.planetList.first.id : 'planet_1';

    return GameState(
      resources: resources,
      buildingLevels: {for (final b in config.buildingList) b.id: 0},
      unlockedTechs: <String>{},
      completedContracts: <String>{},
      unlockedBuildings: {
        for (final b in config.buildingList)
          if (b.unlockCondition == null) b.id,
      },
      cycleProgressSeconds: {
        for (final b in config.buildingList) b.id: 0.0,
      },
      pendingOfflineEarnings: <String, double>{},
      pendingOfflineSeconds: 0,
      missionNextAvailableMs: <String, int>{},
      buyAmountSetting: 'x1',
      currentPlanetId: initialPlanetId,
      unlockedPlanets: {
        initialPlanetId,
        for (final p in config.planetList)
          if (p.unlockedByDefault) p.id,
      },
      lastTickTimestamp: nowMs,
      // ContractSystem defaults.
      activeContracts: <ContractInstance>[],
      contractOffers: <ContractInstance>[],
      nextContractRefreshMs: nowMs,
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
        'unlockedBuildings': unlockedBuildings.toList(),
        'cycleProgressSeconds': cycleProgressSeconds,
        'pendingOfflineEarnings': pendingOfflineEarnings,
        'pendingOfflineSeconds': pendingOfflineSeconds,
        'missionNextAvailableMs': missionNextAvailableMs,
        'buyAmountSetting': buyAmountSetting,
        'currentPlanetId': currentPlanetId,
        'unlockedPlanets': unlockedPlanets.toList(),
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
      resources: _doubleMap(json['resources']),
      buildingLevels: _intMap(json['buildingLevels']),
      unlockedTechs: Set<String>.from((json['unlockedTechs'] as List?) ?? const []),
      completedContracts: Set<String>.from((json['completedContracts'] as List?) ?? const []),
      unlockedBuildings: Set<String>.from((json['unlockedBuildings'] as List?) ?? const []),
      cycleProgressSeconds: _doubleMap(json['cycleProgressSeconds']),
      pendingOfflineEarnings: _doubleMap(json['pendingOfflineEarnings']),
      pendingOfflineSeconds: (json['pendingOfflineSeconds'] as num?)?.toInt() ?? 0,
      missionNextAvailableMs: _intMap(json['missionNextAvailableMs']),
      buyAmountSetting: (json['buyAmountSetting'] as String?) ?? 'x1',
      currentPlanetId: (json['currentPlanetId'] as String?) ?? 'planet_1',
      unlockedPlanets:
          Set<String>.from((json['unlockedPlanets'] as List?) ?? const <String>['planet_1']),
      lastTickTimestamp: (json['lastTickTimestamp'] as num).toInt(),
      totalPlaytimeSeconds: (json['totalPlaytimeSeconds'] as int?) ?? 0,
      activeContracts: activeRaw
          .whereType<Map>()
          .map((m) => ContractInstance.fromJson(Map<String, dynamic>.from(m)))
          .toList(growable: true),
      contractOffers: offersRaw
          .whereType<Map>()
          .map((m) => ContractInstance.fromJson(Map<String, dynamic>.from(m)))
          .toList(growable: true),
      nextContractRefreshMs: (json['nextContractRefreshMs'] as num?)?.toInt() ?? 0,
      contractRngSeed: (json['contractRngSeed'] as num?)?.toInt() ?? 0,
      contractRefreshCount: (json['contractRefreshCount'] as num?)?.toInt() ?? 0,
      contractOfferCounter: (json['contractOfferCounter'] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, double> _doubleMap(dynamic raw) {
    if (raw is! Map) return <String, double>{};
    return raw.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
  }

  static Map<String, int> _intMap(dynamic raw) {
    if (raw is! Map) return <String, int>{};
    return raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
  }
}
