import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../models/config/building_config.dart';
import '../theme/app_theme.dart';
import '../theme/number_format.dart';

class BuildingCard extends StatelessWidget {
  final BuildingConfig buildingConfig;
  const BuildingCard({required this.buildingConfig, super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final level = engine.state.buildingLevels[buildingConfig.id] ?? 0;
    final cost = engine.getUpgradeCost(buildingConfig.id);
    final canAfford = engine.canUpgradeBuilding(buildingConfig.id);
    final atMaxLevel = level >= buildingConfig.maxLevel;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                iconFromString(buildingConfig.icon),
                size: 24,
                color: level > 0 ? Colors.blueAccent : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        buildingConfig.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: level > 0
                              ? Colors.blueAccent.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Lv $level',
                          style: TextStyle(
                            fontSize: 11,
                            color: level > 0 ? Colors.blueAccent : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    buildingConfig.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (level > 0) _buildProductionRow(engine),
                  if (!atMaxLevel) _buildCostRow(cost, engine),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Upgrade button
            SizedBox(
              width: 72,
              child: ElevatedButton(
                onPressed: atMaxLevel
                    ? null
                    : (canAfford
                        ? () => context
                            .read<GameEngine>()
                            .upgradeBuilding(buildingConfig.id)
                        : null),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  atMaxLevel
                      ? 'MAX'
                      : level == 0
                          ? 'Build'
                          : 'Upgrade',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductionRow(GameEngine engine) {
    final parts = <Widget>[];

    for (final entry in buildingConfig.produces.entries) {
      final name = engine.config.resources[entry.key]?.name ?? entry.key;
      final color = engine.config.resources[entry.key]?.color;
      parts.add(Text(
        '+$name ',
        style: TextStyle(
          fontSize: 10,
          color: color != null ? colorFromHex(color) : Colors.greenAccent,
        ),
      ));
    }
    for (final entry in buildingConfig.consumes.entries) {
      final name = engine.config.resources[entry.key]?.name ?? entry.key;
      parts.add(Text(
        '-$name ',
        style: const TextStyle(fontSize: 10, color: Colors.redAccent),
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Wrap(children: parts),
    );
  }

  Widget _buildCostRow(Map<String, double> cost, GameEngine engine) {
    return Wrap(
      spacing: 8,
      children: cost.entries.map((e) {
        final has = engine.state.resources[e.key] ?? 0.0;
        final enough = has >= e.value;
        final name = engine.config.resources[e.key]?.name ?? e.key;
        return Text(
          '$name: ${formatNumber(e.value)}',
          style: TextStyle(
            fontSize: 10,
            color: enough ? Colors.greenAccent : Colors.redAccent,
          ),
        );
      }).toList(),
    );
  }
}
