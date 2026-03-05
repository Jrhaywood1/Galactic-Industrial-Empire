import 'dart:collection';
import 'dart:math';

import '../models/config/contract_template_config.dart';
import '../models/config/game_config.dart';
import '../models/contracts/contract_instance.dart';
import '../models/state/game_state.dart';

/// Deterministic, JSON-driven contract system.
///
/// Refactor note:
/// - Runtime state is kept as in-memory [ContractInstance] objects on [GameState].
/// - Serialization happens only in [GameState.toJson] / [GameState.fromJson].
class ContractSystem {
  static const int maxActiveContracts = 3;
  static const int maxOffers = 5;
  static const int refreshMinutes = 30;

  final GameConfig config;
  final GameState state;

  /// Injected by GameEngine to determine which resources are currently unlocked.
  final Set<String> Function() getUnlockedResourceIds;

  ContractSystem({
    required this.config,
    required this.state,
    required this.getUnlockedResourceIds,
  });

  int get _nowMs => DateTime.now().millisecondsSinceEpoch;

  // -----------------------------
  // Public API
  // -----------------------------

  /// Generate contract offers into the offer pool.
  ///
  /// Determinism:
  /// - Seed is derived from a persisted base seed + refresh counter.
  /// - Selection is weighted without replacement.
  void generateContracts() {
    final nowMs = _nowMs;
    _ensureInit(nowMs);

    final unlocked = getUnlockedResourceIds();
    final templates = config.contractTemplateList;
    if (templates.isEmpty) {
      state.contractOffers = <ContractInstance>[];
      _scheduleNextRefresh(nowMs);
      return;
    }

    final candidates = <ContractTemplateConfig>[];
    for (final t in templates) {
      // Keep only templates whose requirements are all unlocked.
      final ok = t.requirements.keys.every(unlocked.contains);
      if (!ok) continue;
      candidates.add(t);
    }

    final rng = _rngForCurrentRefresh();

    final offers = <ContractInstance>[];
    final usedTemplateIds = <String>{};

    // Weighted selection without replacement (simple + deterministic).
    for (var i = 0; i < maxOffers; i++) {
      final pick = _weightedPick(rng, candidates, usedTemplateIds);
      if (pick == null) break;
      usedTemplateIds.add(pick.id);
      offers.add(_instantiateOffer(pick));
    }

    state.contractOffers = offers;
    _scheduleNextRefresh(nowMs);
  }

  bool acceptContract(String instanceId) {
    final nowMs = _nowMs;
    _ensureInit(nowMs);

    if (state.activeContracts.length >= maxActiveContracts) return false;

    final idx = state.contractOffers.indexWhere((c) => c.instanceId == instanceId);
    if (idx < 0) return false;

    final offer = state.contractOffers.removeAt(idx);

    // Rush timer starts on accept (not on offer generation).
    final accepted = offer.type == 'rush'
        ? _withRushExpiryOnAccept(offer, nowMs)
        : offer.copyWith(acceptedAtMs: nowMs);

    state.activeContracts.add(accepted);
    return true;
  }

  /// Consume from player storage and apply to contract progress.
  /// Returns the amount actually consumed and delivered.
  double deliverResources(String instanceId, String resourceId, double amount) {
    if (amount <= 0) return 0.0;

    final nowMs = _nowMs;
    _ensureInit(nowMs);

    final idx = state.activeContracts.indexWhere((c) => c.instanceId == instanceId);
    if (idx < 0) return 0.0;

    final c = state.activeContracts[idx];
    if (c.isExpired(nowMs)) return 0.0;

    final need = c.requirements[resourceId];
    if (need == null) return 0.0;

    final already = c.delivered[resourceId] ?? 0.0;
    final remaining = max(0.0, need - already);
    if (remaining <= 0) return 0.0;

    final have = state.resources[resourceId] ?? 0.0;
    final spend = min(min(have, amount), remaining);
    if (spend <= 0) return 0.0;

    // Map mutation safety: ensure resources map is mutable.
    // (Older deserialization bugs can occasionally return an unmodifiable map.)
    if (state.resources is UnmodifiableMapView) {
      state.resources = Map<String, double>.from(state.resources);
    }

    state.resources[resourceId] = have - spend;
    state.activeContracts[idx] = c.deliver(resourceId, spend);

    return spend;
  }

  bool checkCompletion(String instanceId) {
    final nowMs = _nowMs;
    final c = state.activeContracts.where((x) => x.instanceId == instanceId).firstOrNull;
    if (c == null) return false;
    if (c.isExpired(nowMs)) return false;
    return c.isComplete();
  }

  bool claimRewards(String instanceId) {
    final nowMs = _nowMs;
    final idx = state.activeContracts.indexWhere((c) => c.instanceId == instanceId);
    if (idx < 0) return false;

    final c = state.activeContracts[idx];

    if (c.isExpired(nowMs)) {
      // Remove expired rush contracts.
      state.activeContracts.removeAt(idx);
      return false;
    }

    if (!c.isComplete()) return false;

    // Map mutation safety: iterate over a snapshot.
    final rewardEntries = c.rewards.entries.toList(growable: false);
    for (final e in rewardEntries) {
      state.resources[e.key] = (state.resources[e.key] ?? 0.0) + e.value;
    }

    state.activeContracts.removeAt(idx);
    return true;
  }

  /// Refresh offers when the timer elapses (or force).
  void refreshContracts({bool force = false}) {
    final nowMs = _nowMs;
    _ensureInit(nowMs);

    final shouldRefresh =
        force || state.contractOffers.isEmpty || nowMs >= state.nextContractRefreshMs;
    if (!shouldRefresh) return;

    state.contractRefreshCount += 1;
    generateContracts();
  }

  /// Called every tick by the GameEngine.
  void update() {
    final nowMs = _nowMs;
    _ensureInit(nowMs);

    // Auto-refresh offers.
    if (nowMs >= state.nextContractRefreshMs || state.contractOffers.isEmpty) {
      refreshContracts(force: true);
    }

    // Expire rush contracts.
    if (state.activeContracts.isEmpty) return;

    final remaining = <ContractInstance>[];
    for (final c in state.activeContracts) {
      if (c.isExpired(nowMs)) continue;
      remaining.add(c);
    }
    if (remaining.length != state.activeContracts.length) {
      state.activeContracts = remaining;
    }
  }

  // -----------------------------
  // Internals
  // -----------------------------

  void _ensureInit(int nowMs) {
    // Seed should be stable once set.
    if (state.contractRngSeed == 0) {
      // Prefer lastTickTimestamp to keep it stable across immediate boot cycles.
      final base = state.lastTickTimestamp != 0 ? state.lastTickTimestamp : nowMs;
      state.contractRngSeed = base;
    }

    // Older saves may have 0. Setting to now triggers an immediate refresh.
    if (state.nextContractRefreshMs == 0) {
      state.nextContractRefreshMs = nowMs;
    }

    // Ensure lists are mutable.
    state.activeContracts = List<ContractInstance>.from(state.activeContracts);
    state.contractOffers = List<ContractInstance>.from(state.contractOffers);
  }

  void _scheduleNextRefresh(int nowMs) {
    state.nextContractRefreshMs =
        nowMs + Duration(minutes: refreshMinutes).inMilliseconds;
  }

  Random _rngForCurrentRefresh() {
    // Mix seed + refreshCount to avoid low-entropy patterns.
    // Use a 32-bit golden ratio constant for hashing.
    final mixed =
        (state.contractRngSeed ^ (state.contractRefreshCount * 0x9E3779B9)) & 0x7fffffff;
    return Random(mixed);
  }

  ContractInstance _instantiateOffer(ContractTemplateConfig t) {
    final instanceId = '${t.id}_${state.contractRefreshCount}_${state.contractOfferCounter++}';

    // Wrap maps to prevent accidental mutation.
    final req = UnmodifiableMapView<String, double>(Map<String, double>.from(t.requirements));
    final del = UnmodifiableMapView<String, double>({
      for (final k in t.requirements.keys) k: 0.0,
    });
    final rew = UnmodifiableMapView<String, double>(Map<String, double>.from(t.rewards));

    return ContractInstance(
      instanceId: instanceId,
      templateId: t.id,
      type: t.type,
      requirements: req,
      delivered: del,
      rewards: rew,
      acceptedAtMs: 0,
      expiresAtMs: null,
    );
  }

  ContractTemplateConfig? _weightedPick(
    Random rng,
    List<ContractTemplateConfig> candidates,
    Set<String> usedTemplateIds,
  ) {
    final pool = candidates.where((t) => !usedTemplateIds.contains(t.id)).toList();
    if (pool.isEmpty) return null;

    var total = 0;
    for (final t in pool) {
      total += max(0, t.weight);
    }
    if (total <= 0) return pool.first;

    var roll = rng.nextInt(total);
    for (final t in pool) {
      final w = max(0, t.weight);
      if (roll < w) return t;
      roll -= w;
    }
    return pool.last;
  }

  ContractInstance _withRushExpiryOnAccept(ContractInstance offer, int nowMs) {
    final template = config.contractTemplates[offer.templateId];
    final secs = template?.rushSeconds ?? 300;
    return offer.copyWith(
      acceptedAtMs: nowMs,
      expiresAtMs: nowMs + Duration(seconds: secs).inMilliseconds,
    );
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
