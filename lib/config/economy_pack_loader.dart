import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/config/achievement_config.dart';
import '../models/config/building_config.dart';
import '../models/config/contract_config.dart';
import '../models/config/game_config.dart';
import '../models/config/mission_config.dart';
import '../models/config/planet_config.dart';
import '../models/config/planet_unlock_config.dart';
import '../models/config/resource_config.dart';
import '../models/config/technology_config.dart';

class EconomyPackLoader {
  static const _newResourcesPath = 'assets/data/economy/resources.json';
  static const _newPlanetsPath = 'assets/data/economy/planets.json';
  static const _newUnlocksPath = 'assets/data/economy/unlocks.json';
  static const _newIndustriesPaths = <String>[
    'assets/data/economy/industries_planet_1.json',
    'assets/data/economy/industries_planet_2.json',
    'assets/data/economy/industries_planet_3.json',
    'assets/data/economy/industries_planet_4.json',
    'assets/data/economy/industries_planet_5.json',
  ];

  static const _legacyResourcesPath = 'assets/config/resources.json';
  static const _legacyBuildingsPath = 'assets/config/buildings.json';

  static Future<GameConfig?> tryLoad() async {
    final resourcesRaw = await _tryLoadString(_newResourcesPath);
    final planetsRaw = await _tryLoadString(_newPlanetsPath);
    final unlocksRaw = await _tryLoadString(_newUnlocksPath);

    final industriesRaw = <String>[];
    for (final path in _newIndustriesPaths) {
      final raw = await _tryLoadString(path);
      if (raw != null) industriesRaw.add(raw);
    }

    if (resourcesRaw == null || industriesRaw.isEmpty) {
      return null;
    }

    final legacyTech = await _requiredLoadString('assets/config/tech_tree.json');
    final legacyAchievements =
        await _requiredLoadString('assets/config/achievements.json');
    final legacyMissions = await _requiredLoadString('assets/config/missions.json');
    final legacyContracts = await _requiredLoadString('assets/config/contracts.json');

    final resourcesJson = jsonDecode(resourcesRaw) as Map<String, dynamic>;
    final techJson = jsonDecode(legacyTech) as Map<String, dynamic>;
    final achievementsJson = jsonDecode(legacyAchievements) as Map<String, dynamic>;
    final missionsJson = jsonDecode(legacyMissions) as Map<String, dynamic>;
    final contractsJson = jsonDecode(legacyContracts) as Map<String, dynamic>;

    final resourceList = _extractList(resourcesJson, const ['resources'])
        .map((e) => ResourceConfig.fromJson(e))
        .toList(growable: false);

    final buildingList = <BuildingConfig>[];
    for (var i = 0; i < industriesRaw.length; i++) {
      final raw = industriesRaw[i];
      final planetId = 'planet_${i + 1}';
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final entries = _extractList(json, const ['industries', 'buildings']);
      for (final entry in entries) {
        final map = Map<String, dynamic>.from(entry);
        map['planetId'] = (map['planetId'] ?? map['planet'] ?? planetId).toString();
        buildingList.add(BuildingConfig.fromJson(map));
      }
    }

    final technologyList = _extractList(techJson, const ['technologies'])
        .map((e) => TechnologyConfig.fromJson(e))
        .toList(growable: false);

    final achievementList = _extractList(achievementsJson, const ['achievements'])
        .map((e) => AchievementConfig.fromJson(e))
        .toList(growable: false);

    final missionList = _extractList(missionsJson, const ['missions'])
        .map((e) => MissionConfig.fromJson(e))
        .toList(growable: false);

    final contractList = _extractList(contractsJson, const ['contracts'])
        .map((e) => ContractConfig.fromJson(e))
        .toList(growable: false);

    final planetList = planetsRaw == null
        ? _derivePlanetsFromBuildings(buildingList)
        : _loadPlanets(planetsRaw);

    final planetUnlocks = unlocksRaw == null
        ? const <PlanetUnlockConfig>[]
        : _loadPlanetUnlocks(unlocksRaw);

    return GameConfig(
      resources: {for (final r in resourceList) r.id: r},
      buildings: {for (final b in buildingList) b.id: b},
      technologies: {for (final t in technologyList) t.id: t},
      achievements: {for (final a in achievementList) a.id: a},
      missions: {for (final m in missionList) m.id: m},
      contracts: {for (final c in contractList) c.id: c},
      resourceList: resourceList,
      buildingList: buildingList,
      technologyList: technologyList,
      achievementList: achievementList,
      missionList: missionList,
      contractList: contractList,
      planetList: planetList,
      planetUnlocks: planetUnlocks,
    );
  }

  static Future<GameConfig> loadLegacyCompatible() async {
    final resourcesRaw = await _requiredLoadString(_legacyResourcesPath);
    final buildingsRaw = await _requiredLoadString(_legacyBuildingsPath);
    final techRaw = await _requiredLoadString('assets/config/tech_tree.json');
    final achievementsRaw =
        await _requiredLoadString('assets/config/achievements.json');
    final missionsRaw = await _requiredLoadString('assets/config/missions.json');
    final contractsRaw = await _requiredLoadString('assets/config/contracts.json');

    final resourcesJson = jsonDecode(resourcesRaw) as Map<String, dynamic>;
    final buildingsJson = jsonDecode(buildingsRaw) as Map<String, dynamic>;
    final techJson = jsonDecode(techRaw) as Map<String, dynamic>;
    final achievementsJson = jsonDecode(achievementsRaw) as Map<String, dynamic>;
    final missionsJson = jsonDecode(missionsRaw) as Map<String, dynamic>;
    final contractsJson = jsonDecode(contractsRaw) as Map<String, dynamic>;

    final resourceList = _extractList(resourcesJson, const ['resources'])
        .map((e) => ResourceConfig.fromJson(e))
        .toList(growable: false);

    final buildingList = _extractList(buildingsJson, const ['buildings'])
        .map((e) {
          final map = Map<String, dynamic>.from(e);
          map['planetId'] = (map['planetId'] ?? map['planet'] ?? 'planet_1').toString();
          return BuildingConfig.fromJson(map);
        })
        .toList(growable: false);

    final technologyList = _extractList(techJson, const ['technologies'])
        .map((e) => TechnologyConfig.fromJson(e))
        .toList(growable: false);

    final achievementList = _extractList(achievementsJson, const ['achievements'])
        .map((e) => AchievementConfig.fromJson(e))
        .toList(growable: false);

    final missionList = _extractList(missionsJson, const ['missions'])
        .map((e) => MissionConfig.fromJson(e))
        .toList(growable: false);

    final contractList = _extractList(contractsJson, const ['contracts'])
        .map((e) => ContractConfig.fromJson(e))
        .toList(growable: false);

    return GameConfig(
      resources: {for (final r in resourceList) r.id: r},
      buildings: {for (final b in buildingList) b.id: b},
      technologies: {for (final t in technologyList) t.id: t},
      achievements: {for (final a in achievementList) a.id: a},
      missions: {for (final m in missionList) m.id: m},
      contracts: {for (final c in contractList) c.id: c},
      resourceList: resourceList,
      buildingList: buildingList,
      technologyList: technologyList,
      achievementList: achievementList,
      missionList: missionList,
      contractList: contractList,
      planetList: _derivePlanetsFromBuildings(buildingList),
      planetUnlocks: const <PlanetUnlockConfig>[],
    );
  }

  static List<PlanetConfig> _loadPlanets(String raw) {
    final json = jsonDecode(raw);
    if (json is List) {
      return json
          .whereType<Map>()
          .map((e) => PlanetConfig.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false)
        ..sort((a, b) => a.order.compareTo(b.order));
    }

    if (json is Map<String, dynamic>) {
      return _extractList(json, const ['planets'])
          .map((e) => PlanetConfig.fromJson(e))
          .toList(growable: false)
        ..sort((a, b) => a.order.compareTo(b.order));
    }

    return const <PlanetConfig>[];
  }

  static List<PlanetUnlockConfig> _loadPlanetUnlocks(String raw) {
    final json = jsonDecode(raw);
    if (json is List) {
      return json
          .whereType<Map>()
          .map((e) => PlanetUnlockConfig.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    }

    if (json is Map<String, dynamic>) {
      return _extractList(json, const ['unlocks', 'planetUnlocks'])
          .map((e) => PlanetUnlockConfig.fromJson(e))
          .toList(growable: false);
    }

    return const <PlanetUnlockConfig>[];
  }

  static List<PlanetConfig> _derivePlanetsFromBuildings(
    List<BuildingConfig> buildings,
  ) {
    final ids = buildings.map((b) => b.planetId).toSet().toList()..sort();
    if (ids.isEmpty) {
      return const <PlanetConfig>[
        PlanetConfig(id: 'planet_1', name: 'Planet 1', order: 1, unlockedByDefault: true),
      ];
    }

    return ids
        .asMap()
        .entries
        .map(
          (e) => PlanetConfig(
            id: e.value,
            name: 'Planet ${e.key + 1}',
            order: e.key + 1,
            unlockedByDefault: e.key == 0,
          ),
        )
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false);
      }
    }
    return const <Map<String, dynamic>>[];
  }

  static Future<String?> _tryLoadString(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (_) {
      return null;
    }
  }

  static Future<String> _requiredLoadString(String path) {
    return rootBundle.loadString(path);
  }
}
