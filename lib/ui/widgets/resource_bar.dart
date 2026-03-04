import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../models/config/resource_config.dart';
import '../theme/app_theme.dart';
import '../theme/number_format.dart';

class ResourceBar extends StatelessWidget {
  const ResourceBar({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final visibleResources = engine.config.resourceList.where((r) {
      final amount = engine.state.resources[r.id] ?? 0.0;
      final rate = engine.productionSummary.netRates[r.id] ?? 0.0;
      return amount > 0 || rate != 0;
    }).toList();

    if (visibleResources.isEmpty) {
      return const SizedBox(height: 60);
    }

    return Container(
      height: 60,
      color: const Color(0xFF0D1117),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleResources.length,
        separatorBuilder: (context, index) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          return _ResourceChip(config: visibleResources[index]);
        },
      ),
    );
  }
}

class _ResourceChip extends StatelessWidget {
  final ResourceConfig config;
  const _ResourceChip({required this.config});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final amount = engine.state.resources[config.id] ?? 0.0;
    final rate = engine.productionSummary.netRates[config.id] ?? 0.0;
    final capacity = engine.productionSummary.capacities[config.id] ?? 0.0;
    final atCap = amount >= capacity && capacity > 0;
    final color = colorFromHex(config.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(8),
        border: atCap
            ? Border.all(color: Colors.orange.withValues(alpha: 0.6), width: 1)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconFromString(config.icon), size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                formatNumber(amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (rate != 0)
            Text(
              formatRate(rate),
              style: TextStyle(
                fontSize: 10,
                color: rate > 0 ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
        ],
      ),
    );
  }
}
