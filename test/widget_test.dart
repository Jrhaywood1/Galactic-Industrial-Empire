import 'package:flutter_test/flutter_test.dart';
import 'package:galactic_industrial_empire/models/config/resource_config.dart';
import 'package:galactic_industrial_empire/models/config/building_config.dart';
import 'package:galactic_industrial_empire/engine/game_engine.dart';
import 'package:galactic_industrial_empire/models/config/game_config.dart';
import 'package:galactic_industrial_empire/models/state/game_state.dart';

void main() {
  late GameConfig config;
  late GameEngine engine;

  setUp(() {
    final credits = ResourceConfig(
      id: 'credits',
      name: 'Credits',
      description: 'Currency',
      icon: 'monetization_on',
      color: '#FFD700',
      tier: 0,
      baseCapacity: 1000,
      capacityGrowth: 1.5,
    );

    final ore = ResourceConfig(
      id: 'ore',
      name: 'Ore',
      description: 'Raw ore',
      icon: 'landscape',
      color: '#B87333',
      tier: 1,
      baseCapacity: 500,
      capacityGrowth: 1.5,
    );

    final mine = BuildingConfig(
      id: 'asteroid_mine',
      name: 'Asteroid Mine',
      description: 'Extracts ore',
      category: 'extraction',
      tier: 1,
      icon: 'hardware',
      baseCost: {'credits': 10},
      costScaling: 1.15,
      produces: {'ore': 1.0},
      consumes: {},
      productionMultiplierPerLevel: 1.0,
      maxLevel: 1000,
    );

    config = GameConfig(
      resources: {'credits': credits, 'ore': ore},
      buildings: {'asteroid_mine': mine},
      technologies: {},
      achievements: {},
      missions: {},
      contracts: {},
      resourceList: [credits, ore],
      buildingList: [mine],
      technologyList: [],
      achievementList: [],
      missionList: [],
      contractList: [],
    );

    engine = GameEngine(
      config: config,
      state: GameState.newGame(config),
    );
  });

  test('new game starts with 50 credits', () {
    expect(engine.state.resources['credits'], 50.0);
  });

  test('can upgrade building when affordable', () {
    expect(engine.canUpgradeBuilding('asteroid_mine'), isTrue);
  });

  test('upgrading building deducts cost and increments level', () {
    engine.upgradeBuilding('asteroid_mine');
    expect(engine.state.buildingLevels['asteroid_mine'], 1);
    expect(engine.state.resources['credits']!, lessThan(50.0));
  });

  test('tick produces resources from buildings', () {
    engine.upgradeBuilding('asteroid_mine');
    final oreBefore = engine.state.resources['ore']!;
    engine.tick(1.0);
    expect(engine.state.resources['ore']!, greaterThan(oreBefore));
  });

  test('cost scales exponentially with level', () {
    final cost1 = engine.getUpgradeCost('asteroid_mine')['credits']!;
    engine.upgradeBuilding('asteroid_mine');
    final cost2 = engine.getUpgradeCost('asteroid_mine')['credits']!;
    expect(cost2, greaterThan(cost1));
    expect(cost2 / cost1, closeTo(1.15, 0.01));
  });

  test('milestones: no milestones keeps base output', () {
    final milestoneEngine = _buildMilestoneEngine(const <BuildingMilestoneConfig>[]);
    milestoneEngine.state.buildingLevels['mine'] = 5;

    final oreBefore = milestoneEngine.state.resources['ore'] ?? 0.0;
    milestoneEngine.tick(1.0);
    final gained = (milestoneEngine.state.resources['ore'] ?? 0.0) - oreBefore;

    expect(gained, closeTo(5.0, 0.0001));
  });

  test('milestones: single milestone output multiplier applies', () {
    final milestoneEngine = _buildMilestoneEngine(const <BuildingMilestoneConfig>[
      BuildingMilestoneConfig(count: 10, outputMultiplier: 2.0),
    ]);
    milestoneEngine.state.buildingLevels['mine'] = 10;

    final oreBefore = milestoneEngine.state.resources['ore'] ?? 0.0;
    milestoneEngine.tick(1.0);
    final gained = (milestoneEngine.state.resources['ore'] ?? 0.0) - oreBefore;

    expect(gained, closeTo(20.0, 0.0001));
  });

  test('milestones: highest tier selected, not stacked', () {
    final milestoneEngine = _buildMilestoneEngine(const <BuildingMilestoneConfig>[
      BuildingMilestoneConfig(count: 10, outputMultiplier: 1.10),
      BuildingMilestoneConfig(count: 25, outputMultiplier: 1.25, speedMultiplier: 1.10),
      BuildingMilestoneConfig(count: 50, outputMultiplier: 1.50, speedMultiplier: 1.25),
    ]);
    milestoneEngine.state.buildingLevels['mine'] = 30;

    final oreBefore = milestoneEngine.state.resources['ore'] ?? 0.0;
    milestoneEngine.tick(1.0);
    final gained = (milestoneEngine.state.resources['ore'] ?? 0.0) - oreBefore;

    expect(gained, closeTo(41.25, 0.0001));
  });

  test('milestones: missing optional fields default to 1.0', () {
    final cfg = BuildingConfig.fromJson(<String, dynamic>{
      'id': 'mine',
      'name': 'Mine',
      'description': 'desc',
      'category': 'extraction',
      'tier': 1,
      'icon': 'hardware',
      'unlockCondition': null,
      'baseCost': <String, dynamic>{'credits': 10},
      'costScaling': 1.1,
      'produces': <String, dynamic>{'ore': 1.0},
      'consumes': <String, dynamic>{},
      'productionMultiplierPerLevel': 1.0,
      'maxLevel': 999,
      'milestones': <Map<String, dynamic>>[
        <String, dynamic>{'count': 10, 'outputMultiplier': 1.2},
        <String, dynamic>{'count': 20, 'speedMultiplier': 1.3},
      ],
    });

    expect(cfg.milestones[0].speedMultiplier, 1.0);
    expect(cfg.milestones[1].outputMultiplier, 1.0);
  });
}

GameEngine _buildMilestoneEngine(List<BuildingMilestoneConfig> milestones) {
  final credits = ResourceConfig(
    id: 'credits',
    name: 'Credits',
    description: 'Currency',
    icon: 'monetization_on',
    color: '#FFD700',
    tier: 0,
    baseCapacity: 1000000,
    capacityGrowth: 1.5,
  );

  final ore = ResourceConfig(
    id: 'ore',
    name: 'Ore',
    description: 'Raw ore',
    icon: 'landscape',
    color: '#B87333',
    tier: 1,
    baseCapacity: 1000000,
    capacityGrowth: 1.5,
  );

  final mine = BuildingConfig(
    id: 'mine',
    name: 'Mine',
    description: 'Extracts ore',
    category: 'extraction',
    tier: 1,
    icon: 'hardware',
    baseCost: {'credits': 1},
    costScaling: 1.0,
    produces: {'ore': 1.0},
    consumes: const {},
    productionMultiplierPerLevel: 1.0,
    maxLevel: 1000000,
    milestones: milestones,
  );

  final config = GameConfig(
    resources: {'credits': credits, 'ore': ore},
    buildings: {'mine': mine},
    technologies: const {},
    achievements: const {},
    missions: const {},
    contracts: const {},
    resourceList: [credits, ore],
    buildingList: [mine],
    technologyList: const [],
    achievementList: const [],
    missionList: const [],
    contractList: const [],
  );

  final state = GameState.newGame(config);
  state.resources['credits'] = 1000000;

  return GameEngine(config: config, state: state);
}
