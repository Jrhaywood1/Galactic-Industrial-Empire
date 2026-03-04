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
      resourceList: [credits, ore],
      buildingList: [mine],
      technologyList: [],
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
}
