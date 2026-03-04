import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/config/game_config.dart';
import '../models/state/game_state.dart';
import '../models/production_summary.dart';

class GameEngine extends ChangeNotifier {
  final GameConfig config;
  GameState state;
  ProductionSummary _cachedSummary;

  static const double maxOfflineSeconds = 14400.0; // 4 hours

  GameEngine({required this.config, required this.state})
      : _cachedSummary = const ProductionSummary.empty() {
    _cachedSummary = _computeSummary();
  }

  ProductionSummary get productionSummary => _cachedSummary;

  // ---------------------------------------------------------------------------
  // Game loop
  // ---------------------------------------------------------------------------

  void tick(double deltaSeconds) {
    _cachedSummary = _computeSummary();
    _applyProduction(deltaSeconds);
    state.lastTickTimestamp = DateTime.now().millisecondsSinceEpoch;
    state.totalPlaytimeSeconds += deltaSeconds.floor();
    notifyListeners();
  }

  void processOfflineEarnings() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedMs = now - state.lastTickTimestamp;
    final elapsedSeconds = elapsedMs / 1000.0;

    if (elapsedSeconds < 2.0) return;

    final cappedSeconds = elapsedSeconds.clamp(0.0, maxOfflineSeconds);

    _cachedSummary = _computeSummary();
    _applyProduction(cappedSeconds);
    state.lastTickTimestamp = now;
    state.totalPlaytimeSeconds += cappedSeconds.floor();

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Production calculation
  // ---------------------------------------------------------------------------

  ProductionSummary _computeSummary() {
    final grossProd = <String, double>{};
    final grossCons = <String, double>{};

    // Pre-compute tech multipliers
    final techProdMultipliers = <String, double>{};
    double globalProdMultiplier = 1.0;
    double globalConsReduction = 1.0;

    for (final techId in state.unlockedTechs) {
      final tech = config.technologies[techId];
      if (tech == null) continue;
      for (final effect in tech.effects) {
        switch (effect.type) {
          case 'production_multiplier':
            if (effect.target != null) {
              techProdMultipliers[effect.target!] =
                  (techProdMultipliers[effect.target!] ?? 1.0) *
                      (effect.value ?? 1.0);
            }
          case 'global_production_multiplier':
            globalProdMultiplier *= (effect.value ?? 1.0);
          case 'global_consumption_reduction':
            globalConsReduction *= (effect.value ?? 1.0);
          default:
            break;
        }
      }
    }

    for (final building in config.buildingList) {
      final level = state.buildingLevels[building.id] ?? 0;
      if (level <= 0) continue;

      final levelMult =
          _levelMultiplier(level, building.productionMultiplierPerLevel);
      final techMult = techProdMultipliers[building.id] ?? 1.0;
      final totalProdMult = levelMult * techMult * globalProdMultiplier;
      final totalConsMult = levelMult * globalConsReduction;

      for (final entry in building.produces.entries) {
        grossProd[entry.key] =
            (grossProd[entry.key] ?? 0.0) + entry.value * totalProdMult;
      }
      for (final entry in building.consumes.entries) {
        grossCons[entry.key] =
            (grossCons[entry.key] ?? 0.0) + entry.value * totalConsMult;
      }
    }

    final allResourceIds = <String>{...grossProd.keys, ...grossCons.keys};
    final netRates = <String, double>{};
    for (final id in allResourceIds) {
      netRates[id] = (grossProd[id] ?? 0.0) - (grossCons[id] ?? 0.0);
    }

    final capacities = <String, double>{};
    for (final r in config.resourceList) {
      capacities[r.id] = r.baseCapacity;
    }

    return ProductionSummary(
      netRates: netRates,
      grossProduction: grossProd,
      grossConsumption: grossCons,
      capacities: capacities,
    );
  }

  static double _levelMultiplier(int level, double multiplierPerLevel) {
    if (multiplierPerLevel == 1.0) {
      return level.toDouble();
    }
    // Geometric series: (m^level - 1) / (m - 1)
    return (pow(multiplierPerLevel, level) - 1) / (multiplierPerLevel - 1);
  }

  void _applyProduction(double deltaSeconds) {
    for (final resourceConfig in config.resourceList) {
      final id = resourceConfig.id;
      final netRate = _cachedSummary.netRates[id] ?? 0.0;
      if (netRate == 0.0) continue;

      final capacity = _cachedSummary.capacities[id] ?? double.infinity;
      final current = state.resources[id] ?? 0.0;
      state.resources[id] = (current + netRate * deltaSeconds).clamp(0.0, capacity);
    }
  }

  // ---------------------------------------------------------------------------
  // Building actions
  // ---------------------------------------------------------------------------

  Map<String, double> getUpgradeCost(String buildingId) {
    final building = config.buildings[buildingId]!;
    final currentLevel = state.buildingLevels[buildingId] ?? 0;

    double costReduction = 1.0;
    for (final techId in state.unlockedTechs) {
      final tech = config.technologies[techId];
      if (tech == null) continue;
      for (final effect in tech.effects) {
        if (effect.type == 'cost_reduction' && effect.target == buildingId) {
          costReduction *= (effect.value ?? 1.0);
        }
      }
    }

    return building.baseCost.map((resourceId, baseCost) => MapEntry(
        resourceId,
        baseCost * pow(building.costScaling, currentLevel) * costReduction));
  }

  bool canUpgradeBuilding(String buildingId) {
    final building = config.buildings[buildingId]!;
    final currentLevel = state.buildingLevels[buildingId] ?? 0;

    if (currentLevel >= building.maxLevel) return false;
    if (!isUnlocked(buildingId)) return false;

    final cost = getUpgradeCost(buildingId);
    return cost.entries.every((e) => (state.resources[e.key] ?? 0.0) >= e.value);
  }

  bool upgradeBuilding(String buildingId) {
    if (!canUpgradeBuilding(buildingId)) return false;

    final cost = getUpgradeCost(buildingId);
    for (final entry in cost.entries) {
      state.resources[entry.key] = (state.resources[entry.key] ?? 0.0) - entry.value;
    }
    state.buildingLevels[buildingId] =
        (state.buildingLevels[buildingId] ?? 0) + 1;

    _cachedSummary = _computeSummary();
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Technology actions
  // ---------------------------------------------------------------------------

  bool canResearchTech(String techId) {
    final tech = config.technologies[techId];
    if (tech == null) return false;
    if (state.unlockedTechs.contains(techId)) return false;

    // Check prerequisites
    for (final prereq in tech.prerequisites) {
      if (!state.unlockedTechs.contains(prereq)) return false;
    }

    // Check cost
    return tech.cost.entries
        .every((e) => (state.resources[e.key] ?? 0.0) >= e.value);
  }

  bool researchTech(String techId) {
    if (!canResearchTech(techId)) return false;

    final tech = config.technologies[techId]!;
    for (final entry in tech.cost.entries) {
      state.resources[entry.key] =
          (state.resources[entry.key] ?? 0.0) - entry.value;
    }
    state.unlockedTechs.add(techId);

    _cachedSummary = _computeSummary();
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Unlock checks
  // ---------------------------------------------------------------------------

  bool isUnlocked(String buildingId) {
    final condition = config.buildings[buildingId]?.unlockCondition;
    if (condition == null) return true;

    switch (condition.type) {
      case 'building_level':
        return (state.buildingLevels[condition.buildingId] ?? 0) >=
            (condition.level ?? 0);
      case 'resource_amount':
        return (state.resources[condition.resourceId] ?? 0.0) >=
            (condition.amount ?? 0.0);
      case 'prestige_level':
        return false; // Not implemented in Phase 1
      default:
        return false;
    }
  }
}
