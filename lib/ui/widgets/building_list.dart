import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../models/config/building_config.dart';
import 'building_card.dart';

class BuildingList extends StatelessWidget {
  const BuildingList({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final visibleBuildings = engine.config.buildingList
        .where((b) => engine.isUnlocked(b.id))
        .toList();

    if (visibleBuildings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No buildings available yet.\nKeep producing resources to unlock more!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Group by tier
    final tiers = <int, List<BuildingConfig>>{};
    for (final b in visibleBuildings) {
      tiers.putIfAbsent(b.tier, () => []).add(b);
    }
    final sortedTiers = tiers.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      itemCount: _totalItems(sortedTiers, tiers),
      itemBuilder: (context, index) {
        int current = 0;
        for (final tier in sortedTiers) {
          final buildings = tiers[tier]!;
          // Header
          if (index == current) {
            return _TierHeader(tier: tier);
          }
          current++;
          // Buildings in this tier
          if (index < current + buildings.length) {
            return BuildingCard(
              buildingConfig: buildings[index - current],
            );
          }
          current += buildings.length;
        }
        return const SizedBox.shrink();
      },
    );
  }

  int _totalItems(List<int> sortedTiers, Map<int, List<BuildingConfig>> tiers) {
    int count = 0;
    for (final tier in sortedTiers) {
      count += 1 + tiers[tier]!.length; // header + buildings
    }
    return count;
  }
}

class _TierHeader extends StatelessWidget {
  final int tier;
  const _TierHeader({required this.tier});

  static const _tierNames = {
    1: 'Basic Infrastructure',
    2: 'Advanced Industry',
    3: 'Stellar Engineering',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        'Tier $tier - ${_tierNames[tier] ?? "Tier $tier"}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[400],
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
