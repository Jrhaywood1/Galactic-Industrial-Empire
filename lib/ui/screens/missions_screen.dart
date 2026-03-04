import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine/game_engine.dart';
import '../../models/config/contract_config.dart';
import '../theme/number_format.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final contracts = engine.config.contractList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contracts'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: contracts.length,
        itemBuilder: (context, index) {
          return _ContractCard(contract: contracts[index]);
        },
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final ContractConfig contract;
  const _ContractCard({required this.contract});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();

    final completed = engine.isContractCompleted(contract.id);
    final canComplete = engine.canCompleteContract(contract.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: completed
                    ? Colors.greenAccent.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: completed
                    ? Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.4),
                        width: 1,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  contract.type.toUpperCase().substring(0, 1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: completed ? Colors.greenAccent : Colors.grey,
                  ),
                ),
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
                      Expanded(
                        child: Text(
                          contract.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (completed && !contract.repeatable) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle,
                            size: 16, color: Colors.greenAccent),
                      ],
                    ],
                  ),
                  if (contract.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      contract.description,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                  const SizedBox(height: 6),

                  _Requirements(contract: contract),
                  const SizedBox(height: 6),
                  _Rewards(contract: contract),
                ],
              ),
            ),

            const SizedBox(width: 8),
            SizedBox(
              width: 92,
              child: ElevatedButton(
                onPressed: (canComplete)
                    ? () => context
                        .read<GameEngine>()
                        .completeContract(contract.id)
                    : null,
                child: Text(
                  completed && !contract.repeatable ? 'Done' : 'Complete',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Requirements extends StatelessWidget {
  final ContractConfig contract;
  const _Requirements({required this.contract});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Requirements',
            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        const SizedBox(height: 2),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: contract.requirements.map((r) {
            if (r.resourceId != null) {
              final have = engine.state.resources[r.resourceId!] ?? 0.0;
              final enough = have >= r.amount;
              final name = engine.config.resources[r.resourceId!]?.name ??
                  r.resourceId!;
              return Text(
                '$name: ${formatNumber(r.amount)}',
                style: TextStyle(
                  fontSize: 11,
                  color: enough ? Colors.greenAccent : Colors.redAccent,
                ),
              );
            }
            if (r.buildingId != null) {
              final have = engine.state.buildingLevels[r.buildingId!] ?? 0;
              final enough = have >= r.amount;
              final name = engine.config.buildings[r.buildingId!]?.name ??
                  r.buildingId!;
              return Text(
                '$name Lv ${r.amount.toInt()}',
                style: TextStyle(
                  fontSize: 11,
                  color: enough ? Colors.greenAccent : Colors.redAccent,
                ),
              );
            }
            return const SizedBox.shrink();
          }).toList(),
        ),
      ],
    );
  }
}

class _Rewards extends StatelessWidget {
  final ContractConfig contract;
  const _Rewards({required this.contract});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rewards',
            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        const SizedBox(height: 2),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: contract.rewards.entries.map((e) {
            final name = engine.config.resources[e.key]?.name ?? e.key;
            return Text(
              '$name: +${formatNumber(e.value)}',
              style: const TextStyle(fontSize: 11, color: Colors.amberAccent),
            );
          }).toList(),
        ),
      ],
    );
  }
}
