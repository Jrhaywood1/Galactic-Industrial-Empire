import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine/game_engine.dart';
import '../../models/config/building_config.dart';
import '../theme/number_format.dart';
import '../widgets/bulk_buy.dart';
import '../widgets/industry_tile.dart';
import 'settings_screen.dart';

class EmpireScreen extends StatefulWidget {
  const EmpireScreen({super.key});

  @override
  State<EmpireScreen> createState() => _EmpireScreenState();
}

class _EmpireScreenState extends State<EmpireScreen> {
  final Map<int, bool> _tierExpanded = <int, bool>{
    1: true,
    2: true,
    3: true,
    4: false,
  };

  String? _expandedBuildingId;
  bool _offlineDialogShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_offlineDialogShown) return;

    final hasOffline = context.read<GameEngine>().hasPendingOfflineEarnings;
    if (!hasOffline) return;

    _offlineDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showOfflineDialog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.read<GameEngine>();
    final _ = context.select<GameEngine, int>((e) => e.state.unlockedBuildings.length);

    final tiers = _groupByTier(
      engine.config.buildingList
          .where((b) => engine.state.unlockedBuildings.contains(b.id))
          .toList(growable: false),
    );

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: _EmpireTopBar()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: _EmpireStatusStrip(onClaimOffline: _showOfflineDialog),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: _ContractRibbon()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: _BuyAmountBar()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ..._buildTierSlivers(tiers),
        const SliverToBoxAdapter(child: SizedBox(height: 86)),
      ],
    );
  }

  Map<int, List<BuildingConfig>> _groupByTier(List<BuildingConfig> buildings) {
    final grouped = <int, List<BuildingConfig>>{};
    for (final b in buildings) {
      grouped.putIfAbsent(b.tier, () => <BuildingConfig>[]).add(b);
    }

    for (final tier in const [1, 2, 3, 4]) {
      grouped.putIfAbsent(tier, () => <BuildingConfig>[]);
      grouped[tier]!.sort((a, b) => a.id.compareTo(b.id));
    }

    return grouped;
  }

  List<Widget> _buildTierSlivers(Map<int, List<BuildingConfig>> tiers) {
    final slivers = <Widget>[];

    for (final tier in const [1, 2, 3, 4]) {
      final expanded = _tierExpanded[tier] ?? true;
      final buildings = tiers[tier] ?? const <BuildingConfig>[];

      slivers.add(
        SliverToBoxAdapter(
          child: _TierHeader(
            tier: tier,
            expanded: expanded,
            count: buildings.length,
            onTap: () {
              setState(() {
                _tierExpanded[tier] = !expanded;
              });
            },
          ),
        ),
      );

      if (!expanded) continue;

      if (buildings.isEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tier == 4
                      ? 'Expansion tier locked. Keep upgrading core industry.'
                      : 'No unlocked industries in this tier yet.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            ),
          ),
        );
        continue;
      }

      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final building = buildings[index];
              return IndustryTile(
                key: ValueKey<String>('industry_${building.id}'),
                building: building,
                expanded: _expandedBuildingId == building.id,
                onToggle: () {
                  setState(() {
                    _expandedBuildingId =
                        _expandedBuildingId == building.id ? null : building.id;
                  });
                },
              );
            },
            childCount: buildings.length,
          ),
        ),
      );
    }

    return slivers;
  }

  Future<void> _showOfflineDialog() async {
    final engine = context.read<GameEngine>();
    if (!engine.hasPendingOfflineEarnings) return;

    final rewards = engine.pendingOfflineEarnings.entries
        .where((e) => e.value > 0)
        .toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Offline Earnings'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Away for ${_formatDuration(engine.pendingOfflineSeconds)}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 10),
                ...rewards.take(8).map((e) {
                  final name = engine.config.resources[e.key]?.name ?? e.key;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('$name +${formatNumber(e.value)}'),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                engine.claimOfflineEarnings(doubled: true);
                Navigator.of(context).pop();
              },
              child: const Text('x2 (Ad Stub)'),
            ),
            FilledButton(
              onPressed: () {
                engine.claimOfflineEarnings();
                Navigator.of(context).pop();
              },
              child: const Text('Claim'),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${max(1, m)}m';
  }
}

class _EmpireTopBar extends StatelessWidget {
  const _EmpireTopBar();

  @override
  Widget build(BuildContext context) {
    return Selector<GameEngine, _TopBarData>(
      selector: (_, engine) => _TopBarData(
        credits: engine.state.resources['credits'] ?? 0.0,
        research: engine.state.resources['research_data'] ?? 0.0,
        hasShips: (engine.state.resources['ships'] ?? 0.0) > 0.0,
        ships: engine.state.resources['ships'] ?? 0.0,
      ),
      builder: (context, data, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ResourceBadge(
                      icon: Icons.monetization_on,
                      label: 'Credits',
                      value: formatNumber(data.credits),
                      color: const Color(0xFFFFD700),
                    ),
                    _ResourceBadge(
                      icon: Icons.science,
                      label: 'Research',
                      value: formatNumber(data.research),
                      color: const Color(0xFFB49BFF),
                    ),
                    if (data.hasShips)
                      _ResourceBadge(
                        icon: Icons.rocket_launch,
                        label: 'Ships',
                        value: formatNumber(data.ships),
                        color: const Color(0xFF9BD3FF),
                      ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmpireStatusStrip extends StatelessWidget {
  final VoidCallback onClaimOffline;

  const _EmpireStatusStrip({required this.onClaimOffline});

  @override
  Widget build(BuildContext context) {
    return Selector<GameEngine, _StatusStripData>(
      selector: (_, engine) {
        final net = engine.getNetProductionValuePerSecond();
        final warningId = engine.storageWarningResourceId;
        final warningName = warningId == null
            ? null
            : (engine.config.resources[warningId]?.name ?? warningId);

        return _StatusStripData(
          netFlowPerSec: net,
          hasOfflineClaim: engine.hasPendingOfflineEarnings,
          hasStorageWarning: warningName != null,
          warningName: warningName,
        );
      },
      builder: (context, data, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF141924),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.show_chart,
                  size: 16,
                  color: data.netFlowPerSec >= 0 ? Colors.greenAccent : Colors.redAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  'Net Value ${formatRate(data.netFlowPerSec)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                if (data.hasStorageWarning)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Storage near cap: ${data.warningName}',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                _PulseWrap(
                  enabled: data.hasOfflineClaim,
                  child: TextButton(
                    onPressed: data.hasOfflineClaim ? onClaimOffline : null,
                    child: const Text('Claim Offline'),
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

class _ContractRibbon extends StatelessWidget {
  const _ContractRibbon();

  @override
  Widget build(BuildContext context) {
    return Selector<GameEngine, _ContractRibbonData>(
      selector: (_, engine) {
        final contract = engine.getPrimaryContract();
        if (contract == null) {
          return const _ContractRibbonData.empty();
        }

        return _ContractRibbonData(
          id: contract.id,
          title: contract.title,
          progress01: engine.contractProgress01(contract.id),
          claimable: engine.canCompleteContract(contract.id),
        );
      },
      builder: (context, data, _) {
        if (data.id == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF181D2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment, color: Colors.cyanAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: data.progress01,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _PulseWrap(
                  enabled: data.claimable,
                  child: FilledButton(
                    onPressed: data.claimable
                        ? () => context.read<GameEngine>().completeContract(data.id!)
                        : null,
                    child: Text(data.claimable ? 'Claim' : 'Track'),
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

class _BuyAmountBar extends StatelessWidget {
  const _BuyAmountBar();

  @override
  Widget build(BuildContext context) {
    return Selector<GameEngine, BuyAmountSetting>(
      selector: (_, engine) => engine.buyAmountSetting,
      builder: (context, setting, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(
                'Buy Amount',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: BulkBuySelector(
                    value: setting,
                    onChanged: (next) {
                      context.read<GameEngine>().setBuyAmountSetting(next);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TierHeader extends StatelessWidget {
  final int tier;
  final bool expanded;
  final int count;
  final VoidCallback onTap;

  const _TierHeader({
    required this.tier,
    required this.expanded,
    required this.count,
    required this.onTap,
  });

  static const _tierNames = <int, String>{
    1: 'Basic Infrastructure',
    2: 'Advanced Industry',
    3: 'Stellar Engineering',
    4: 'Expansion Command',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey[300],
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tier $tier - ${_tierNames[tier] ?? 'Tier $tier'}',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Text(
                  '$count',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseWrap extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const _PulseWrap({required this.child, required this.enabled});

  @override
  State<_PulseWrap> createState() => _PulseWrapState();
}

class _PulseWrapState extends State<_PulseWrap> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.97,
      upperBound: 1.04,
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _PulseWrap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.enabled) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: widget.child,
    );
  }
}

class _ResourceBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ResourceBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF151A24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

@immutable
class _TopBarData {
  final double credits;
  final double research;
  final bool hasShips;
  final double ships;

  const _TopBarData({
    required this.credits,
    required this.research,
    required this.hasShips,
    required this.ships,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _TopBarData &&
        other.credits == credits &&
        other.research == research &&
        other.hasShips == hasShips &&
        other.ships == ships;
  }

  @override
  int get hashCode => Object.hash(credits, research, hasShips, ships);
}

@immutable
class _StatusStripData {
  final double netFlowPerSec;
  final bool hasOfflineClaim;
  final bool hasStorageWarning;
  final String? warningName;

  const _StatusStripData({
    required this.netFlowPerSec,
    required this.hasOfflineClaim,
    required this.hasStorageWarning,
    required this.warningName,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _StatusStripData &&
        other.netFlowPerSec == netFlowPerSec &&
        other.hasOfflineClaim == hasOfflineClaim &&
        other.hasStorageWarning == hasStorageWarning &&
        other.warningName == warningName;
  }

  @override
  int get hashCode =>
      Object.hash(netFlowPerSec, hasOfflineClaim, hasStorageWarning, warningName);
}

@immutable
class _ContractRibbonData {
  final String? id;
  final String? title;
  final double progress01;
  final bool claimable;

  const _ContractRibbonData({
    required this.id,
    required this.title,
    required this.progress01,
    required this.claimable,
  });

  const _ContractRibbonData.empty()
      : id = null,
        title = null,
        progress01 = 0,
        claimable = false;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ContractRibbonData &&
        other.id == id &&
        other.title == title &&
        other.progress01 == progress01 &&
        other.claimable == claimable;
  }

  @override
  int get hashCode => Object.hash(id, title, progress01, claimable);
}
