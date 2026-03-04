import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/config/resource_config.dart';
import '../models/config/building_config.dart';
import '../models/config/technology_config.dart';
import '../models/config/achievement_config.dart';
import '../models/config/mission_config.dart';
import '../models/config/game_config.dart';

class ConfigLoader {
  static Future<GameConfig> loadAll() async {
    final results = await Future.wait([
      rootBundle.loadString('assets/config/resources.json'),
      rootBundle.loadString('assets/config/buildings.json'),
      rootBundle.loadString('assets/config/tech_tree.json'),
      rootBundle.loadString('assets/config/achievements.json'),
      rootBundle.loadString('assets/config/missions.json'),
    ]);

    final resourcesJson = jsonDecode(results[0]) as Map<String, dynamic>;
    final buildingsJson = jsonDecode(results[1]) as Map<String, dynamic>;
    final techJson = jsonDecode(results[2]) as Map<String, dynamic>;
    final achievementsJson = jsonDecode(results[3]) as Map<String, dynamic>;
    final missionsJson = jsonDecode(results[4]) as Map<String, dynamic>;

    final resourceList = (resourcesJson['resources'] as List)
        .map((e) => ResourceConfig.fromJson(e as Map<String, dynamic>))
        .toList();

    final buildingList = (buildingsJson['buildings'] as List)
        .map((e) => BuildingConfig.fromJson(e as Map<String, dynamic>))
        .toList();

    final technologyList = (techJson['technologies'] as List)
        .map((e) => TechnologyConfig.fromJson(e as Map<String, dynamic>))
        .toList();

    final achievementList = (achievementsJson['achievements'] as List)
        .map((e) => AchievementConfig.fromJson(e as Map<String, dynamic>))
        .toList();

    final missionList = (missionsJson['missions'] as List)
        .map((e) => MissionConfig.fromJson(e as Map<String, dynamic>))
        .toList();

    return GameConfig(
      resources: {for (final r in resourceList) r.id: r},
      buildings: {for (final b in buildingList) b.id: b},
      technologies: {for (final t in technologyList) t.id: t},
      achievements: {for (final a in achievementList) a.id: a},
      missions: {for (final m in missionList) m.id: m},

      resourceList: resourceList,
      buildingList: buildingList,
      technologyList: technologyList,
      achievementList: achievementList,
      missionList: missionList,
    );
  }
}