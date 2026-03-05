import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/config/building_config.dart';
import '../models/config/contract_config.dart';
import '../models/config/game_config.dart';
import '../models/config/mission_config.dart';
import '../models/config/technology_config.dart';
import '../models/production_summary.dart';
import '../models/state/game_state.dart';

enum BuyAmountSetting { x1, x10, x25, max }

extension BuyAmountSettingX on BuyAmountSetting {
  String get storageValue {
    switch (this) {
      case BuyAmountSetting.x1:
        return 'x1';
      case BuyAmountSetting.x10:
        return 'x10';
      case BuyAmountSetting.x25:
        return 'x25';
      case BuyAmountSetting.max:
        return 'max';
    }
  }

  String get label {
    switch (this) {
      case BuyAmountSetting.x1:
        return 'x1';
      case BuyAmountSetting.x10:
        return 'x10';
      case BuyAmountSetting.x25:
        return 'x25';
      case BuyAmountSetting.max:
        return 'Max';
    }
  }

  int get count {
    switch (this) {
      case BuyAmountSetting.x1:
        return 1;
      case BuyAmountSetting.x10:
        return 10;
      case BuyAmountSetting.x25:
        return 25;
      case BuyAmountSetting.max:
        return -1;
    }
  }

  static BuyAmountSetting fromStorage(String raw) {
    switch (raw) {
      case 'x10':
        return BuyAmountSetting.x10;
      case 'x25':
        return BuyAmountSetting.x25;
      case 'max':
        return BuyAmountSetting.max;
      case 'x1':
      default:
        return BuyAmountSetting.x1;
    }
  }
}

enum BuildingFlowState { idle, running, starved, capped }

class BuildingRuntimeInfo {
  final BuildingFlowState flowState;
  final double progress01;
  final double effectiveOutputPerSecond;
  final double storagePercent;
  final bool boosted;
  final double cycleSeconds;
  final int level;

  const BuildingRuntimeInfo({
    required this.flowState,
    required this.progress01,
    required this.effectiveOutputPerSecond,
    required this.storagePercent,
    required this.boosted,
    required this.cycleSeconds,
    required this.level,
  });

  static const empty = BuildingRuntimeInfo(
    flowState: BuildingFlowState.idle,
    progress01: 0,
    effectiveOutputPerSecond: 0,
    storagePercent: 0,
    boosted: false,
    cycleSeconds: 4,
    level: 0,
  );
}

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

  // Runtime building telemetry for UI.
  final Map<String, BuildingFlowState> _buildingFlowStates = {};
  final Map<String, double> _buildingEffectiveOutputRates = {};
  final Map<String, bool> _buildingBoostedStates = {};

  GameEngine({required this.config, required this.state}) {
    _ensureStateMaps();
    _updateDiscoveredBuildings();
    _recomputeTechEffects();
    _recomputeProductionSummary();
  }

  // -----------------------------
  // Tick + offline
  // -----------------------------

  void tick(double dtSeconds) {
    final scaledDt = dtSeconds * gameSpeed;

    _ensureStateMaps();
    _updateDiscoveredBuildings();

    // Update playtime
    state.totalPlaytimeSeconds += scaledDt.round();

    // Update economy
    _recomputeTechEffects();
    final simulation = _simulateDetailed(scaledDt, state.resources);
    state.resources = simulation.resources;
    state.lastTickTimestamp = DateTime.now().millisecondsSinceEpoch;

    _updateCycleProgress(scaledDt, simulation.stepsByBuilding);
    _captureRuntimeBuildingState(simulation.stepsByBuilding);

    // UI data
    _recomputeProductionSummary();
    notifyListeners();
  }

  void processOfflineEarnings({int maxHours = 12}) {
    final now = DateTime.now();
    final last = DateTime.fromMillisecondsSinceEpoch(state.lastTickTimestamp);
    final seconds = now.difference(last).inSeconds;
    if (seconds <= 1) return;

    _ensureStateMaps();
    _updateDiscoveredBuildings();
    _recomputeTechEffects();

    final capped = seconds.clamp(0, maxHours * 3600);
    final before = Map<String, double>.from(state.resources);
    var simulated = Map<String, double>.from(before);

    // Simulate in chunks so consumption gating works.
    var remaining = capped;
    while (remaining > 0) {
      final step = min(60, remaining).toDouble();
      simulated = _simulateDetailed(step, simulated).resources;
      remaining -= step.toInt();
    }

    for (final r in config.resourceList) {
      final prev = before[r.id] ?? 0.0;
      final next = simulated[r.id] ?? 0.0;
      final gain = max(0.0, next - prev);
      if (gain > 0) {
        state.pendingOfflineEarnings[r.id] =
            (state.pendingOfflineEarnings[r.id] ?? 0.0) + gain;
      }
    }

    state.pendingOfflineSeconds += capped;
    state.lastTickTimestamp = now.millisecondsSinceEpoch;
    _recomputeProductionSummary();
    notifyListeners();
  }

  bool get hasPendingOfflineEarnings =>
      state.pendingOfflineEarnings.values.any((v) => v > 0);

  int get pendingOfflineSeconds => state.pendingOfflineSeconds;

  Map<String, double> get pendingOfflineEarnings =>
      Map<String, double>.unmodifiable(state.pendingOfflineEarnings);

  void claimOfflineEarnings({bool doubled = false}) {
    if (!hasPendingOfflineEarnings) return;

    _recomputeTechEffects();
    final mult = doubled ? 2.0 : 1.0;
    final caps = _resourceCapacities();

    for (final e in state.pendingOfflineEarnings.entries) {
      final current = state.resources[e.key] ?? 0.0;
      final cap = caps[e.key] ?? double.infinity;
      state.resources[e.key] = (current + (e.value * mult)).clamp(0.0, cap);
    }

    state.pendingOfflineEarnings.clear();
    state.pendingOfflineSeconds = 0;

    _recomputeProductionSummary();
    notifyListeners();
  }

  // -----------------------------
  // Buildings
  // -----------------------------

  bool isUnlocked(String buildingId) {
    if (state.unlockedBuildings.contains(buildingId)) return true;

    final b = config.buildings[buildingId];
    if (b == null) return false;

    if (_meetsUnlockCondition(b.unlockCondition)) {
      state.unlockedBuildings.add(buildingId);
      return true;
    }

    return false;
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

  Map<String, double> getUpgradeCostForQuantity(
    String buildingId,
    BuyAmountSetting setting,
  ) {
    final preview = _previewBulkPurchase(
      buildingId,
      setting,
      maxIterations: setting == BuyAmountSetting.max ? 200 : 2000,
    );
    return preview.totalCost;
  }

  int getAffordableUpgradeCount(String buildingId, {int maxIterations = 2000}) {
    final preview = _previewBulkPurchase(
      buildingId,
      BuyAmountSetting.max,
      maxIterations: maxIterations,
    );
    return preview.quantity;
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

  bool canUpgradeForSetting(String buildingId, BuyAmountSetting setting) {
    final preview = _previewBulkPurchase(
      buildingId,
      setting,
      maxIterations: setting == BuyAmountSetting.max ? 200 : 2000,
    );
    return preview.quantity > 0;
  }

  void upgradeBuilding(String buildingId) {
    _upgradeBuildingInternal(buildingId, BuyAmountSetting.x1);
  }

  int upgradeBuildingForSetting(String buildingId, BuyAmountSetting setting) {
    return _upgradeBuildingInternal(buildingId, setting);
  }

  int upgradeBuildingForCurrentSetting(String buildingId) {
    return _upgradeBuildingInternal(buildingId, buyAmountSetting);
  }

  BuyAmountSetting get buyAmountSetting =>
      BuyAmountSettingX.fromStorage(state.buyAmountSetting);

  void setBuyAmountSetting(BuyAmountSetting setting) {
    if (buyAmountSetting == setting) return;
    state.buyAmountSetting = setting.storageValue;
    notifyListeners();
  }

  BuildingRuntimeInfo getBuildingRuntimeInfo(String buildingId) {
    final b = config.buildings[buildingId];
    if (b == null) return BuildingRuntimeInfo.empty;

    final level = state.buildingLevels[buildingId] ?? 0;
    final cycle = max(0.25, b.cycleSeconds);
    final elapsed = state.cycleProgressSeconds[buildingId] ?? 0.0;
    final primaryOutputId = b.produces.keys.isNotEmpty ? b.produces.keys.first : null;

    final storagePercent = primaryOutputId == null
        ? 0.0
        : _resourceStoragePercent(primaryOutputId);

    return BuildingRuntimeInfo(
      flowState: _buildingFlowStates[buildingId] ?? BuildingFlowState.idle,
      progress01: (elapsed / cycle).clamp(0.0, 1.0),
      effectiveOutputPerSecond: _buildingEffectiveOutputRates[buildingId] ?? 0.0,
      storagePercent: storagePercent,
      boosted: _buildingBoostedStates[buildingId] ?? false,
      cycleSeconds: cycle,
      level: level,
    );
  }

  bool triggerManualCycle(String buildingId) {
    final b = config.buildings[buildingId];
    if (b == null) return false;

    final level = state.buildingLevels[buildingId] ?? 0;
    if (level <= 0 || !isUnlocked(buildingId)) return false;

    _recomputeTechEffects();
    final step = _evaluateBuildingStep(
      b,
      level,
      b.cycleSeconds,
      state.resources,
      _resourceCapacities(),
    );

    if (step.factor <= 0) {
      _buildingFlowStates[buildingId] =
          step.starved ? BuildingFlowState.starved : BuildingFlowState.capped;
      notifyListeners();
      return false;
    }

    final next = Map<String, double>.from(state.resources);
    for (final e in step.consumesPerSecond.entries) {
      final amt = e.value * b.cycleSeconds * step.factor;
      next[e.key] = max(0.0, (next[e.key] ?? 0.0) - amt);
    }
    final caps = _resourceCapacities();
    for (final e in step.producesPerSecond.entries) {
      final amt = e.value * b.cycleSeconds * step.factor;
      final cap = caps[e.key] ?? double.infinity;
      next[e.key] = ((next[e.key] ?? 0.0) + amt).clamp(0.0, cap);
    }

    state.resources = next;
    state.cycleProgressSeconds[buildingId] = 0.0;
    _buildingFlowStates[buildingId] = BuildingFlowState.running;
    _buildingEffectiveOutputRates[buildingId] = step.totalOutputPerSecond * step.factor;
    _buildingBoostedStates[buildingId] = step.boosted;

    _updateDiscoveredBuildings();
    _recomputeProductionSummary();
    notifyListeners();
    return true;
  }

  // -----------------------------
  // Missions (goals over existing missions.json)
  // -----------------------------

  List<MissionConfig> getGoalMissions({int limit = 3}) {
    final visible = config.missionList.where((m) => _meetsUnlockCondition(m.unlockCondition));
    final sorted = visible.toList()
      ..sort((a, b) {
        final cooldownDiff = missionCooldownRemainingSeconds(a.id)
            .compareTo(missionCooldownRemainingSeconds(b.id));
        if (cooldownDiff != 0) return cooldownDiff;
        return a.tier.compareTo(b.tier);
      });

    if (sorted.length <= limit) return sorted;
    return sorted.take(limit).toList();
  }

  double missionProgress01(String missionId) {
    final mission = config.missions[missionId];
    if (mission == null) return 0.0;
    if (!_meetsUnlockCondition(mission.unlockCondition)) return 0.0;

    if (mission.requirements.isEmpty) return 1.0;

    var progress = 1.0;
    for (final req in mission.requirements.entries) {
      final have = state.resources[req.key] ?? 0.0;
      final ratio = req.value <= 0 ? 1.0 : (have / req.value);
      progress = min(progress, ratio);
    }

    return progress.clamp(0.0, 1.0);
  }

  int missionCooldownRemainingSeconds(String missionId) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final nextMs = state.missionNextAvailableMs[missionId] ?? 0;
    if (nextMs <= nowMs) return 0;
    return ((nextMs - nowMs) / 1000).ceil();
  }

  bool canClaimMission(String missionId) {
    final mission = config.missions[missionId];
    if (mission == null) return false;
    if (!_meetsUnlockCondition(mission.unlockCondition)) return false;
    if (missionCooldownRemainingSeconds(missionId) > 0) return false;
    return missionProgress01(missionId) >= 1.0;
  }

  bool claimMission(String missionId) {
    if (!canClaimMission(missionId)) return false;

    final mission = config.missions[missionId]!;

    for (final req in mission.requirements.entries) {
      state.resources[req.key] = (state.resources[req.key] ?? 0.0) - req.value;
    }
    for (final reward in mission.rewards.entries) {
      state.resources[reward.key] = (state.resources[reward.key] ?? 0.0) + reward.value;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    state.missionNextAvailableMs[missionId] =
        nowMs + (mission.cooldownSeconds * 1000);

    _updateDiscoveredBuildings();
    _recomputeProductionSummary();
    notifyListeners();
    return true;
  }

  int getClaimableGoalCount() {
    var count = 0;
    for (final mission in getGoalMissions(limit: 99)) {
      if (canClaimMission(mission.id)) count += 1;
    }
    return count;
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
    _storageMultiplier = 1.0;

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
        _storageMultiplier = max(_storageMultiplier, e.value!);
        return;
      default:
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

    for (final r in c.requirements) {
      if (r.resourceId != null) {
        state.resources[r.resourceId!] =
            (state.resources[r.resourceId!] ?? 0.0) - r.amount;
      }
    }

    for (final e in c.rewards.entries) {
      state.resources[e.key] = (state.resources[e.key] ?? 0.0) + e.value;
    }

    if (!c.repeatable) {
      state.completedContracts.add(contractId);
    }

    _recomputeProductionSummary();
    notifyListeners();
  }

  ContractConfig? getPrimaryContract() {
    if (config.contractList.isEmpty) return null;

    for (final c in config.contractList) {
      if (canCompleteContract(c.id)) return c;
    }

    return config.contractList.first;
  }

  double contractProgress01(String contractId) {
    final c = config.contracts[contractId];
    if (c == null || c.requirements.isEmpty) return 0.0;

    var progress = 1.0;
    for (final req in c.requirements) {
      if (req.resourceId != null) {
        final have = state.resources[req.resourceId!] ?? 0.0;
        progress = min(progress, have / req.amount);
      } else if (req.buildingId != null) {
        final lvl = state.buildingLevels[req.buildingId!] ?? 0;
        progress = min(progress, lvl / req.amount);
      }
    }
    return progress.clamp(0.0, 1.0);
  }

  int getClaimableContractCount() {
    var count = 0;
    for (final c in config.contractList) {
      if (canCompleteContract(c.id)) count += 1;
    }
    return count;
  }

  // -----------------------------
  // Economy simulation
  // -----------------------------

  bool get hasStorageWarning => storageWarningResourceId != null;

  String? get storageWarningResourceId {
    String? selected;
    var highest = 0.0;

    for (final r in config.resourceList) {
      final ratio = _resourceStoragePercent(r.id);
      if (ratio >= 0.9 && ratio > highest) {
        highest = ratio;
        selected = r.id;
      }
    }

    return selected;
  }

  double _resourceStoragePercent(String resourceId) {
    final amount = state.resources[resourceId] ?? 0.0;
    final cap = productionSummary.capacities[resourceId] ?? 0.0;
    if (cap <= 0 || !cap.isFinite) return 0.0;
    return (amount / cap).clamp(0.0, 1.0);
  }

  _SimulationResult _simulateDetailed(
    double dtSeconds,
    Map<String, double> baseResources,
  ) {
    final next = Map<String, double>.from(baseResources);
    final capacities = _resourceCapacities();
    final delta = <String, double>{};
    final stepsByBuilding = <String, _BuildingStep>{};

    for (final b in config.buildingList) {
      final level = state.buildingLevels[b.id] ?? 0;
      final step = _evaluateBuildingStep(b, level, dtSeconds, next, capacities);
      stepsByBuilding[b.id] = step;

      if (step.factor <= 0) continue;

      for (final e in step.consumesPerSecond.entries) {
        final amt = e.value * dtSeconds * step.factor;
        delta[e.key] = (delta[e.key] ?? 0.0) - amt;
      }
      for (final e in step.producesPerSecond.entries) {
        final amt = e.value * dtSeconds * step.factor;
        delta[e.key] = (delta[e.key] ?? 0.0) + amt;
      }
    }

    for (final e in delta.entries) {
      final cap = capacities[e.key] ?? double.infinity;
      final cur = next[e.key] ?? 0.0;
      final v = cur + e.value;
      next[e.key] = v.clamp(0.0, cap.isFinite ? cap : double.infinity);
    }

    return _SimulationResult(
      resources: next,
      stepsByBuilding: stepsByBuilding,
    );
  }

  _BuildingStep _evaluateBuildingStep(
    BuildingConfig b,
    int level,
    double dtSeconds,
    Map<String, double> resources,
    Map<String, double> capacities,
  ) {
    if (level <= 0 || !isUnlocked(b.id)) {
      return const _BuildingStep.idle();
    }

    final baseMult =
        pow(b.productionMultiplierPerLevel, max(0, level - 1)).toDouble();
    final techMult = _buildingProductionMult[b.id] ?? 1.0;
    final milestoneMult = _milestoneMultiplier(level);
    final effectiveProdMult = techMult * milestoneMult;

    final producesPerSec = {
      for (final e in b.produces.entries)
        e.key: e.value * level * baseMult * effectiveProdMult * _globalProductionMult,
    };
    final consumesPerSec = {
      for (final e in b.consumes.entries)
        e.key: e.value * level * baseMult * _globalConsumptionMult,
    };

    var inputFactor = 1.0;
    var outputFactor = 1.0;

    for (final e in consumesPerSec.entries) {
      final need = e.value * dtSeconds;
      if (need <= 0) continue;
      final have = resources[e.key] ?? 0.0;
      if (have <= 0) {
        inputFactor = 0.0;
        break;
      }
      inputFactor = min(inputFactor, have / need);
    }

    if (inputFactor > 0) {
      for (final e in producesPerSec.entries) {
        final out = e.value * dtSeconds;
        if (out <= 0) continue;

        final cap = capacities[e.key] ?? double.infinity;
        if (!cap.isFinite) continue;

        final have = resources[e.key] ?? 0.0;
        final remaining = max(0.0, cap - have);
        if (remaining <= 0) {
          outputFactor = 0.0;
          break;
        }
        outputFactor = min(outputFactor, remaining / out);
      }
    }

    final factor = min(inputFactor, outputFactor).clamp(0.0, 1.0);

    final inputLimited = inputFactor < 1.0;
    final outputLimited = outputFactor < 1.0;

    final totalOutputPerSecond =
        producesPerSec.values.fold<double>(0.0, (a, b) => a + b);

    return _BuildingStep(
      factor: factor,
      starved: inputLimited,
      capped: outputLimited,
      producesPerSecond: producesPerSec,
      consumesPerSecond: consumesPerSec,
      totalOutputPerSecond: totalOutputPerSecond,
      boosted: effectiveProdMult > 1.0001 || _globalProductionMult > 1.0001,
    );
  }

  void _updateCycleProgress(
    double dtSeconds,
    Map<String, _BuildingStep> stepsByBuilding,
  ) {
    for (final b in config.buildingList) {
      final level = state.buildingLevels[b.id] ?? 0;
      final cycle = max(0.25, b.cycleSeconds);
      final step = stepsByBuilding[b.id] ?? const _BuildingStep.idle();

      if (level <= 0 || !isUnlocked(b.id)) {
        state.cycleProgressSeconds[b.id] = 0.0;
        continue;
      }

      if (step.factor <= 0) {
        continue;
      }

      final prev = state.cycleProgressSeconds[b.id] ?? 0.0;
      final updated = (prev + (dtSeconds * step.factor)) % cycle;
      state.cycleProgressSeconds[b.id] = updated;
    }
  }

  void _captureRuntimeBuildingState(Map<String, _BuildingStep> stepsByBuilding) {
    for (final b in config.buildingList) {
      final step = stepsByBuilding[b.id] ?? const _BuildingStep.idle();
      final level = state.buildingLevels[b.id] ?? 0;
      if (level <= 0 || !isUnlocked(b.id)) {
        _buildingFlowStates[b.id] = BuildingFlowState.idle;
        _buildingEffectiveOutputRates[b.id] = 0.0;
        _buildingBoostedStates[b.id] = false;
        continue;
      }

      if (step.factor <= 0) {
        if (step.starved) {
          _buildingFlowStates[b.id] = BuildingFlowState.starved;
        } else if (step.capped) {
          _buildingFlowStates[b.id] = BuildingFlowState.capped;
        } else {
          _buildingFlowStates[b.id] = BuildingFlowState.idle;
        }
      } else {
        if (step.starved) {
          _buildingFlowStates[b.id] = BuildingFlowState.starved;
        } else if (step.capped) {
          _buildingFlowStates[b.id] = BuildingFlowState.capped;
        } else {
          _buildingFlowStates[b.id] = BuildingFlowState.running;
        }
      }

      _buildingEffectiveOutputRates[b.id] = step.totalOutputPerSecond * step.factor;
      _buildingBoostedStates[b.id] = step.boosted;
    }
  }

  void _recomputeProductionSummary() {
    final net = <String, double>{};
    final grossProd = <String, double>{};
    final grossCons = <String, double>{};
    final caps = _resourceCapacities();

    for (final b in config.buildingList) {
      final level = state.buildingLevels[b.id] ?? 0;
      if (level <= 0) continue;
      if (!isUnlocked(b.id)) continue;

      final baseMult =
          pow(b.productionMultiplierPerLevel, max(0, level - 1)).toDouble();
      final prodMult = (_buildingProductionMult[b.id] ?? 1.0) * _milestoneMultiplier(level);

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

  Map<String, double> _resourceCapacities() {
    return {
      for (final r in config.resourceList) r.id: r.baseCapacity * _storageMultiplier,
    };
  }

  double _milestoneMultiplier(int level) {
    var mult = 1.0;
    if (level >= 10) mult *= 1.25;
    if (level >= 25) mult *= 1.25;
    if (level >= 50) mult *= 1.25;
    if (level >= 100) mult *= 1.25;
    return mult;
  }

  int _upgradeBuildingInternal(String buildingId, BuyAmountSetting setting) {
    final preview = _previewBulkPurchase(
      buildingId,
      setting,
      maxIterations: setting == BuyAmountSetting.max ? 200 : 2000,
    );
    if (preview.quantity <= 0) return 0;

    for (final e in preview.totalCost.entries) {
      state.resources[e.key] = (state.resources[e.key] ?? 0.0) - e.value;
    }

    state.buildingLevels[buildingId] =
        (state.buildingLevels[buildingId] ?? 0) + preview.quantity;

    _updateDiscoveredBuildings();
    _recomputeProductionSummary();
    notifyListeners();

    return preview.quantity;
  }

  _BulkPurchasePreview _previewBulkPurchase(
    String buildingId,
    BuyAmountSetting setting, {
    int maxIterations = 500,
  }) {
    final b = config.buildings[buildingId];
    if (b == null) return const _BulkPurchasePreview.zero();
    if (!isUnlocked(buildingId)) return const _BulkPurchasePreview.zero();

    final levelStart = state.buildingLevels[buildingId] ?? 0;
    if (levelStart >= b.maxLevel) return const _BulkPurchasePreview.zero();

    final targetCount = setting.count;
    final maxByLevel = b.maxLevel - levelStart;

    var bought = 0;
    var level = levelStart;
    final wallet = Map<String, double>.from(state.resources);
    final totalCost = <String, double>{};

    while (bought < maxByLevel && bought < maxIterations) {
      if (targetCount != -1 && bought >= targetCount) break;

      final cost = _upgradeCostAtLevel(buildingId, level);
      if (cost.isEmpty) break;

      var affordable = true;
      for (final e in cost.entries) {
        if ((wallet[e.key] ?? 0.0) < e.value) {
          affordable = false;
          break;
        }
      }

      if (!affordable) break;

      for (final e in cost.entries) {
        wallet[e.key] = (wallet[e.key] ?? 0.0) - e.value;
        totalCost[e.key] = (totalCost[e.key] ?? 0.0) + e.value;
      }

      bought += 1;
      level += 1;
    }

    return _BulkPurchasePreview(quantity: bought, totalCost: totalCost);
  }

  Map<String, double> _upgradeCostAtLevel(String buildingId, int level) {
    final b = config.buildings[buildingId];
    if (b == null) return const {};

    final mult = pow(b.costScaling, level).toDouble();
    final costMult = _buildingCostMult[buildingId] ?? 1.0;

    return {
      for (final e in b.baseCost.entries) e.key: e.value * mult * costMult,
    };
  }

  bool _meetsUnlockCondition(UnlockCondition? u) {
    if (u == null) return true;

    switch (u.type) {
      case 'building_level':
        final lvl = state.buildingLevels[u.buildingId] ?? 0;
        return lvl >= (u.level ?? 0);
      case 'resource_amount':
        final amt = state.resources[u.resourceId] ?? 0.0;
        return amt >= (u.amount ?? 0.0);
      case 'tech_unlocked':
        return u.buildingId != null && state.unlockedTechs.contains(u.buildingId);
      default:
        return true;
    }
  }

  void _updateDiscoveredBuildings() {
    for (final b in config.buildingList) {
      if (state.unlockedBuildings.contains(b.id)) continue;
      if (_meetsUnlockCondition(b.unlockCondition)) {
        state.unlockedBuildings.add(b.id);
      }
    }
  }

  void _ensureStateMaps() {
    for (final b in config.buildingList) {
      state.cycleProgressSeconds.putIfAbsent(b.id, () => 0.0);
      state.buildingLevels.putIfAbsent(b.id, () => 0);
    }
    for (final r in config.resourceList) {
      state.resources.putIfAbsent(r.id, () => 0.0);
    }
  }
}

class _SimulationResult {
  final Map<String, double> resources;
  final Map<String, _BuildingStep> stepsByBuilding;

  const _SimulationResult({
    required this.resources,
    required this.stepsByBuilding,
  });
}

class _BuildingStep {
  final double factor;
  final bool starved;
  final bool capped;
  final Map<String, double> producesPerSecond;
  final Map<String, double> consumesPerSecond;
  final double totalOutputPerSecond;
  final bool boosted;

  const _BuildingStep({
    required this.factor,
    required this.starved,
    required this.capped,
    required this.producesPerSecond,
    required this.consumesPerSecond,
    required this.totalOutputPerSecond,
    required this.boosted,
  });

  const _BuildingStep.idle()
      : factor = 0,
        starved = false,
        capped = false,
        producesPerSecond = const {},
        consumesPerSecond = const {},
        totalOutputPerSecond = 0,
        boosted = false;
}

class _BulkPurchasePreview {
  final int quantity;
  final Map<String, double> totalCost;

  const _BulkPurchasePreview({required this.quantity, required this.totalCost});

  const _BulkPurchasePreview.zero()
      : quantity = 0,
        totalCost = const {};
}
