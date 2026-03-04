import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine/game_engine.dart';

/// Modern production breakdown panel.
///
/// Uses [GameEngine.productionSummary] computed from the config-driven buildings.
class ProductionBreakdownPanel extends StatelessWidget {
  const ProductionBreakdownPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final summary = engine.productionSummary;

    // Show a small, readable subset: positive net rates first.
    final entries = summary.netRates.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Net Production (per sec)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Text('No active production yet.'),
          ...entries.take(8).map((e) {
            final v = e.value;
            final sign = v >= 0 ? '+' : '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${e.key}: $sign${v.toStringAsFixed(2)}/s'),
            );
          }),
          const SizedBox(height: 10),
          const Divider(),
          const Text('Buildings', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...engine.config.buildingList.take(10).map((b) {
            final lvl = engine.state.buildingLevels[b.id] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${b.name}: Lv $lvl'),
            );
          }),
        ]),
      ),
    );
  }
}
