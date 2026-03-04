import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine/game_engine.dart';

/// Legacy panel kept for compatibility with older layouts.
///
/// The main Contracts experience lives in the Contracts screen.
/// This panel shows a quick "featured" contract and lets the player complete it.
class ContractsPanel extends StatelessWidget {
  const ContractsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final contracts = engine.config.contractList;

    if (contracts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Contracts: none loaded'),
        ),
      );
    }

    // Simple: show the first contract as the featured one.
    final c = contracts.first;
    final canComplete = engine.canCompleteContract(c.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Contracts', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(c.title),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: canComplete ? () => engine.completeContract(c.id) : null,
            child: Text(canComplete ? 'Complete' : 'Requirements not met'),
          ),
        ]),
      ),
    );
  }
}
