import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/config/building_config.dart';
import '../models/config/contract_config.dart';
import '../models/config/game_config.dart';
import '../models/config/technology_config.dart';
import '../models/production_summary.dart';
import '../models/state/game_state.dart';

/// Core simulation engine.
///
/// - Config-driven (JSON)
/// - Deterministic tick loop (1s ticks from GameLoopWidget)
/// - Saves via [GameState]
class GameEngine extends ChangeNotifier {
  final GameConfig config;
  GameState state;

  ProductionSummary productionSummary = const ProductionSummary.empty();

  // Debug / simulation controls
  double gameSpeed = 1.0;
  final DateTime startedAt = DateTime.now();

  Duration get runtime => DateTime.now().difference(startedAt);

  // Derived tech effects
  final Map<String, double> _buildingProductionMult = {}; // buildingId -> mult
  final Map<String, double> _buildingCostMult = {}; // buildingId -> mult
  double _globalProductionMult = 1.0;
  double _globalConsumptionMult = 1.0;
  double _storageMultiplier = 1.0;

  GameEngine({required this.config, required this.state}) {
    _recomputeTechEffects();
    _recomputeProductionSummary();
  }

  // -----------------------------
  // Tick + offline
  // -----------------------------

  void tick(double dtSeconds) {
    final scaledDt = dtSeconds * gameSpeed;

    // Update playtime
    state.totalPlaytimeSeconds += scaledDt.round();

    // Update economy
    _recomputeTechEffects();
    final next = _simulate(scaledDt);
    state.resources = next;
    state.lastTickTimestamp = DateTime.now().millisecondsSinceEpoch;

    // UI data
    _recomputeProductionSummary();
    notifyListeners();
  }

  void processOfflineEarnings({int maxHours = 12}) {
    final now = DateTime.now();
    final last = DateTime.fromMillisecondsSinceEpoch(state.lastTickTimestamp);
    final seconds = now.difference(last).inSeconds;
    if (seconds <= 1) return;
    final capped = seconds.clamp(0, maxHours * 3600);

    // Simulate in chunks so consumption gating works.
    int remaining = capped;
    while (remaining > 0) {
      final step = min(60, remaining).toDouble();
      final next = _simulate(step);
      state.resources = next;
      remaining -= step.toInt();
    }

    state.lastTickTimestamp = now.millisecondsSinceEpoch;
    _recomputeProductionSummary();
    notifyListeners();
  }

  // -----------------------------
  // Buildings
  // -----------------------------

  bool isUnlocked(String buildingId) {
    final b = config.buildings[buildingId];
    if (b == null) return false;
    final u = b.unlockCondition;
    if (u == null) return true;

    switch (u.type) {
      case 'building_level':
        final lvl = state.buildingLevels[u.buildingId] ?? 0;
        return lvl >= (u.level ?? 0);
      case 'resource_amount':
        final amt = state.resources[u.resourceId] ?? 0.0;
        return amt >= (u.amount ?? 0.0);
      case 'tech_unlocked':
        // (Reusing field for simplicity)
        return u.buildingId != null && state.unlockedTechs.contains(u.buildingId);
      default:
        return true;
    }
  }

  Map<String, double> getUpgradeCost(String buildingId) {
    final b = config.buildings[buildingId];
    if (b == null) return const {};
    final level = state.buildingLevels[buildingId] ?? 0;
    final mult = pow(b.costScaling, level).toDouble();
    final costMult = _buildingCostMult[buildingId] ?? 1.0;
    return {
      for (final e in b.baseCost.entries) e.key: e.value * mult * costMult,
    };
  }

  bool canUpgradeBuilding(String buildingId) {
    final b = config.buildings[buildingId];
    if (b == null) return false;
    if (!isUnlocked(buildingId)) return false;
    final level = state.buildingLevels[buildingId] ?? 0;
    if (level >= b.maxLevel) return false;
    final cost = getUpgradeCost(buildingId);
    for (final e in cost.entries) {
      if ((state.resources[e.key] ?? 0.0) < e.value) return false;
    }
    return true;
  }

  void upgradeBuilding(String buildingId) {
    if (!canUpgradeBuilding(buildingId)) return;
    final cost = getUpgradeCost(buildingId);
    for (final e in cost.entries) {
      state.resources[e.key] = (state.resources[e.key] ?? 0.0) - e.value;
    }
    state.buildingLevels[buildingId] = (state.buildingLevels[buildingId] ?? 0) + 1;
    _recomputeProductionSummary();
    notifyListeners();
  }

  // -----------------------------
  // Tech
  // -----------------------------

  bool canResearchTech(String techId) {
    final t = config.technologies[techId];
    if (t == null) return false;
    if (state.unlockedTechs.contains(techId)) return false;
    if (!t.prerequisites.every(state.unlockedTechs.contains)) return false;
    for (final e in t.cost.entries) {
      if ((state.resources[e.key] ?? 0.0) < e.value) return false;
    }
    return true;
  }

  void researchTech(String techId) {
    if (!canResearchTech(techId)) return;
    final t = config.technologies[techId]!;
    for (final e in t.cost.entries) {
      state.resources[e.key] = (state.resources[e.key] ?? 0.0) - e.value;
    }
    state.unlockedTechs.add(techId);
    _recomputeTechEffects();
    _recomputeProductionSummary();
    notifyListeners();
  }

  void _recomputeTechEffects() {
    _buildingProductionMult.clear();
    _buildingCostMult.clear();
    _globalProductionMult = 1.0;
    _globalConsumptionMult = 1.0;

    for (final techId in state.unlockedTechs) {
      final tech = config.technologies[techId];
      if (tech == null) continue;
      for (final e in tech.effects) {
        _applyEffect(e);
      }
    }
  }

  void _applyEffect(TechEffect e) {
    switch (e.type) {
      case 'production_multiplier':
        if (e.target == null || e.value == null) return;
        _buildingProductionMult[e.target!] =
            (_buildingProductionMult[e.target!] ?? 1.0) * e.value!;
        return;
      case 'cost_reduction':
        if (e.target == null || e.value == null) return;
        _buildingCostMult[e.target!] =
            (_buildingCostMult[e.target!] ?? 1.0) * e.value!;
        return;
      case 'global_production_multiplier':
        if (e.value == null) return;
        _globalProductionMult *= e.value!;
        return;
      case 'global_consumption_reduction':
        if (e.value == null) return;
        _globalConsumptionMult *= e.value!;
        return;
      case 'storage_multiplier':
        if (e.value == null) return;
        // Treat as "set at least" so higher tiers override lower tiers cleanly.
        _storageMultiplier = max(_storageMultiplier, e.value!);
        return;
      default:
        // Unknown effects ignored for now.
        return;
    }
  }

  // -----------------------------
  // Contracts
  // -----------------------------

  bool isContractCompleted(String contractId) =>
      state.completedContracts.contains(contractId);

  bool canCompleteContract(String contractId) {
    final c = config.contracts[contractId];
    if (c == null) return false;
    if (isContractCompleted(contractId) && !c.repeatable) return false;

    for (final r in c.requirements) {
      if (r.resourceId != null) {
        final have = state.resources[r.resourceId!] ?? 0.0;
        if (have < r.amount) return false;
      }
      if (r.buildingId != null) {
        final lvl = state.buildingLevels[r.buildingId!] ?? 0;
        if (lvl < r.amount) return false;
      }
    }
    return true;
  }

  void completeContract(String contractId) {
    if (!canCompleteContract(contractId)) return;
    final c = config.contracts[contractId]!;

    // Spend resource requirements (building requirements are checks only)
    for (final r in c.requirements) {
      if (r.resourceId != null) {
        state.resources[r.resourceId!] =
            (state.resources[r.resourceId!] ?? 0.0) - r.amount;
      }
    }

    // Apply rewards
    for (final e in c.rewards.entries) {
      state.resources[e.key] = (state.resources[e.key] ?? 0.0) + e.value;
    }

    if (!c.repeatable) {
      state.completedContracts.add(contractId);
    }

    _recomputeProductionSummary();
    notifyListeners();
  }

  // -----------------------------
  // Economy simulation
  // -----------------------------

  Map<String, double> _simulate(double dtSeconds) {
    final next = Map<String, double>.from(state.resources);

    // Capacities: currently driven by resource config baseCapacity.
    final capacities = <String, double>{
      for (final r in config.resourceList) r.id: r.baseCapacity * _storageMultiplier,
    };

    final delta = <String, double>{};

    for (final b in config.buildingList) {
      final level = state.buildingLevels[b.id] ?? 0;
      if (level <= 0) continue;
      if (!isUnlocked(b.id)) continue;

      final prodMult = _buildingProductionMult[b.id] ?? 1.0;
      final baseMult = pow(b.productionMultiplierPerLevel, max(0, level - 1)).toDouble();

      final producesPerSec = {
        for (final e in b.produces.entries)
          e.key: e.value * level * baseMult * prodMult * _globalProductionMult,
      };
      final consumesPerSec = {
        for (final e in b.consumes.entries)
          e.key: e.value * level * baseMult * _globalConsumptionMult,
      };

      double factor = 1.0;

      // Input gating
      for (final e in consumesPerSec.entries) {
        final need = e.value * dtSeconds;
        if (need <= 0) continue;
        final have = next[e.key] ?? 0.0;
        if (have <= 0) {
          factor = 0.0;
          break;
        }
        factor = min(factor, have / need);
      }
      if (factor <= 0) continue;

      // Output gating (caps)
      for (final e in producesPerSec.entries) {
        final out = e.value * dtSeconds;
        if (out <= 0) continue;
        final cap = capacities[e.key] ?? double.infinity;
        if (cap.isFinite) {
          final have = next[e.key] ?? 0.0;
          final remaining = max(0.0, cap - have);
          if (remaining <= 0) {
            factor = 0.0;
            break;
          }
          factor = min(factor, remaining / out);
        }
      }
      if (factor <= 0) continue;

      for (final e in consumesPerSec.entries) {
        final amt = e.value * dtSeconds * factor;
        delta[e.key] = (delta[e.key] ?? 0.0) - amt;
      }
      for (final e in producesPerSec.entries) {
        final amt = e.value * dtSeconds * factor;
        delta[e.key] = (delta[e.key] ?? 0.0) + amt;
      }
    }

    for (final e in delta.entries) {
      final cap = capacities[e.key] ?? double.infinity;
      final cur = next[e.key] ?? 0.0;
      final v = cur + e.value;
      next[e.key] = v.clamp(0.0, cap.isFinite ? cap : double.infinity);
    }

    return next;
  }

  void _recomputeProductionSummary() {
    final net = <String, double>{};
    final grossProd = <String, double>{};
    final grossCons = <String, double>{};
    final caps = <String, double>{
      for (final r in config.resourceList) r.id: r.baseCapacity * _storageMultiplier,
    };

    for (final b in config.buildingList) {
      final level = state.buildingLevels[b.id] ?? 0;
      if (level <= 0) continue;
      if (!isUnlocked(b.id)) continue;

      final prodMult = _buildingProductionMult[b.id] ?? 1.0;
      final baseMult = pow(b.productionMultiplierPerLevel, max(0, level - 1)).toDouble();

      for (final e in b.produces.entries) {
        final v = e.value * level * baseMult * prodMult * _globalProductionMult;
        net[e.key] = (net[e.key] ?? 0.0) + v;
        grossProd[e.key] = (grossProd[e.key] ?? 0.0) + v;
      }
      for (final e in b.consumes.entries) {
        final v = e.value * level * baseMult * _globalConsumptionMult;
        net[e.key] = (net[e.key] ?? 0.0) - v;
        grossCons[e.key] = (grossCons[e.key] ?? 0.0) + v;
      }
    }

    productionSummary = ProductionSummary(
      netRates: net,
      grossProduction: grossProd,
      grossConsumption: grossCons,
      capacities: caps,
    );
  }
}
