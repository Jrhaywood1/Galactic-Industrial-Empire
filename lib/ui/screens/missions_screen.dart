import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine/game_engine.dart';
import '../../models/config/contract_config.dart';
import '../../models/config/mission_config.dart';
import '../theme/app_theme.dart';
import '../theme/number_format.dart';

class ContractsScreen extends StatelessWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.read<GameEngine>();
    final contracts = engine.config.contractList;

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      children: [
        const _GoalsModule(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Contracts',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        ...contracts.map((contract) => _ContractCard(contract: contract)),
      ],
    );
  }
}

class MissionsScreen extends ContractsScreen {
  const MissionsScreen({super.key});
}

class _GoalsModule extends StatelessWidget {
  const _GoalsModule();

  @override
  Widget build(BuildContext context) {
    return Selector<GameEngine, List<MissionConfig>>(
      selector: (_, engine) => engine.getGoalMissions(limit: 3),
      builder: (context, goals, _) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flag, size: 16, color: Colors.amberAccent),
                    SizedBox(width: 6),
                    Text(
                      'Optional Goals',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (goals.isEmpty)
                  Text(
                    'No goals unlocked yet.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ...goals.map((goal) => _GoalItem(goal: goal)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GoalItem extends StatelessWidget {
  final MissionConfig goal;

  const _GoalItem({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Selector<GameEngine, _GoalViewData>(
      selector: (_, engine) => _GoalViewData(
        progress01: engine.missionProgress01(goal.id),
        cooldownSec: engine.missionCooldownRemainingSeconds(goal.id),
        canClaim: engine.canClaimMission(goal.id),
      ),
      builder: (context, view, _) {
        final titleColor = view.canClaim ? Colors.greenAccent : Colors.white;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(iconFromString(goal.icon), size: 14, color: Colors.cyanAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        goal.name,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: titleColor),
                      ),
                    ),
                    if (view.cooldownSec > 0)
                      Text(
                        '${view.cooldownSec}s',
                        style: const TextStyle(fontSize: 11, color: Colors.orangeAccent),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: view.progress01,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.07),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      view.canClaim ? Colors.greenAccent : Colors.lightBlueAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: view.canClaim
                          ? () => context.read<GameEngine>().claimMission(goal.id)
                          : null,
                      child: const Text('Claim'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContractCard extends StatelessWidget {
  final ContractConfig contract;
  const _ContractCard({required this.contract});

  @override
  Widget build(BuildContext context) {
    return Selector<GameEngine, _ContractViewData>(
      selector: (_, engine) => _ContractViewData(
        completed: engine.isContractCompleted(contract.id),
        canComplete: engine.canCompleteContract(contract.id),
        progress01: engine.contractProgress01(contract.id),
      ),
      builder: (context, view, _) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: view.completed
                        ? Colors.greenAccent.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: view.completed
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
                        color: view.completed ? Colors.greenAccent : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                          if (view.completed && !contract.repeatable)
                            const Icon(Icons.check_circle,
                                size: 16, color: Colors.greenAccent),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: view.progress01,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.07),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                        ),
                      ),
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
                    onPressed: view.canComplete
                        ? () => context.read<GameEngine>().completeContract(contract.id)
                        : null,
                    child: Text(
                      view.completed && !contract.repeatable ? 'Done' : 'Complete',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Requirements extends StatelessWidget {
  final ContractConfig contract;
  const _Requirements({required this.contract});

  @override
  Widget build(BuildContext context) {
    final engine = context.read<GameEngine>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Requirements', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        const SizedBox(height: 2),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: contract.requirements.map((r) {
            if (r.resourceId != null) {
              final have = engine.state.resources[r.resourceId!] ?? 0.0;
              final enough = have >= r.amount;
              final name = engine.config.resources[r.resourceId!]?.name ?? r.resourceId!;
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
              final name = engine.config.buildings[r.buildingId!]?.name ?? r.buildingId!;
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
    final engine = context.read<GameEngine>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rewards', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
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

@immutable
class _GoalViewData {
  final double progress01;
  final int cooldownSec;
  final bool canClaim;

  const _GoalViewData({
    required this.progress01,
    required this.cooldownSec,
    required this.canClaim,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _GoalViewData &&
        other.progress01 == progress01 &&
        other.cooldownSec == cooldownSec &&
        other.canClaim == canClaim;
  }

  @override
  int get hashCode => Object.hash(progress01, cooldownSec, canClaim);
}

@immutable
class _ContractViewData {
  final bool completed;
  final bool canComplete;
  final double progress01;

  const _ContractViewData({
    required this.completed,
    required this.canComplete,
    required this.progress01,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ContractViewData &&
        other.completed == completed &&
        other.canComplete == canComplete &&
        other.progress01 == progress01;
  }

  @override
  int get hashCode => Object.hash(completed, canComplete, progress01);
}
