import 'resource_config.dart';
import 'building_config.dart';
import 'technology_config.dart';
import 'achievement_config.dart';
import 'mission_config.dart';
import 'contract_config.dart';
import 'planet_config.dart';
import 'planet_unlock_config.dart';

class GameConfig {
  final Map<String, ResourceConfig> resources;
  final Map<String, BuildingConfig> buildings;
  final Map<String, TechnologyConfig> technologies;
  final Map<String, AchievementConfig> achievements;
  final Map<String, MissionConfig> missions;
  final Map<String, ContractConfig> contracts;

  final List<ResourceConfig> resourceList;
  final List<BuildingConfig> buildingList;
  final List<TechnologyConfig> technologyList;
  final List<AchievementConfig> achievementList;
  final List<MissionConfig> missionList;
  final List<ContractConfig> contractList;

  final List<PlanetConfig> planetList;
  final List<PlanetUnlockConfig> planetUnlocks;

  const GameConfig({
    required this.resources,
    required this.buildings,
    required this.technologies,
    required this.achievements,
    required this.missions,
    required this.contracts,
    required this.resourceList,
    required this.buildingList,
    required this.technologyList,
    required this.achievementList,
    required this.missionList,
    required this.contractList,
    this.planetList = const <PlanetConfig>[],
    this.planetUnlocks = const <PlanetUnlockConfig>[],
  });
}
