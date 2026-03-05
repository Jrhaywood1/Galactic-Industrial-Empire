import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine/game_engine.dart';
import '../../models/config/building_config.dart';
import '../theme/app_theme.dart';
import '../theme/number_format.dart';

class IndustryTile extends StatefulWidget {
  final BuildingConfig building;
  final bool expanded;
  final VoidCallback onToggle;

  const IndustryTile({
    super.key,
    required this.building,
    required this.expanded,
    required this.onToggle,
  });

  @override
  State<IndustryTile> createState() => _IndustryTileState();
}

class _IndustryTileState extends State<IndustryTile> {
  bool _flashUpgrade = false;

  @override
  Widget build(BuildContext context) {
    return Selector<GameEngine, _IndustryTileViewData>(
      selector: (_, engine) {
        final runtime = engine.getBuildingRuntimeInfo(widget.building.id);
        final setting = engine.buyAmountSetting;
        final totalCost = engine.getUpgradeCostForQuantity(widget.building.id, setting);
        final canAfford = engine.canUpgradeForSetting(widget.building.id, setting);
        final atMax = (engine.state.buildingLevels[widget.building.id] ?? 0) >=
            widget.building.maxLevel;

        return _IndustryTileViewData(
          level: runtime.level,
          progress01: runtime.progress01,
          outputRate: runtime.effectiveOutputPerSecond,
          storagePercent: runtime.storagePercent,
          flowState: runtime.flowState,
          boosted: runtime.boosted,
          canAfford: canAfford,
          atMax: atMax,
          buyLabel: setting.label,
          totalCost: totalCost,
        );
      },
      shouldRebuild: (prev, next) => prev != next,
      builder: (context, view, _) {
        final primaryOutput = widget.building.produces.keys.isNotEmpty
            ? widget.building.produces.keys.first
            : null;
        final outputName = primaryOutput == null
            ? 'No output'
            : (context.read<GameEngine>().config.resources[primaryOutput]?.name ??
                primaryOutput);

        final borderColor = _flashUpgrade
            ? Colors.greenAccent.withValues(alpha: 0.8)
            : (view.canAfford
                ? Colors.blueAccent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.05));

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            color: const Color(0xFF161A24),
            boxShadow: _flashUpgrade
                ? [
                    BoxShadow(
                      color: Colors.greenAccent.withValues(alpha: 0.20),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onToggle,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IconBadge(iconName: widget.building.icon, active: view.level > 0),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.building.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                _LevelChip(level: view.level),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$outputName ${formatRate(view.outputRate)}',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: view.progress01,
                                minHeight: 6,
                                backgroundColor: Colors.white.withValues(alpha: 0.08),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _progressColor(view.flowState),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  'Storage ${(view.storagePercent * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: view.storagePercent > 0.9
                                        ? Colors.orangeAccent
                                        : Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ..._buildIndicators(view),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 92,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed: view.atMax
                                  ? null
                                  : (view.canAfford ? _onUpgradePressed : null),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                backgroundColor: view.canAfford
                                    ? const Color(0xFF2E7CF6)
                                    : null,
                              ),
                              child: Text(
                                view.atMax
                                    ? 'MAX'
                                    : (view.level == 0 ? 'Build ${view.buyLabel}' : 'Buy ${view.buyLabel}'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            const SizedBox(height: 6),
                            OutlinedButton(
                              onPressed: view.level > 0 ? _onTapCyclePressed : null,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text(
                                'Tap',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.expanded) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Colors.white10),
                    const SizedBox(height: 10),
                    _ExpandedIndustryInfo(
                      building: widget.building,
                      view: view,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onUpgradePressed() {
    final bought = context.read<GameEngine>().upgradeBuildingForCurrentSetting(widget.building.id);
    if (bought <= 0) return;
    setState(() => _flashUpgrade = true);
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _flashUpgrade = false);
    });
  }

  void _onTapCyclePressed() {
    context.read<GameEngine>().triggerManualCycle(widget.building.id);
  }

  List<Widget> _buildIndicators(_IndustryTileViewData view) {
    final chips = <Widget>[];
    if (view.flowState == BuildingFlowState.starved) {
      chips.add(_StatusTag(label: 'STARVED', color: Colors.redAccent));
    }
    if (view.flowState == BuildingFlowState.capped) {
      chips.add(_StatusTag(label: 'CAPPED', color: Colors.orangeAccent));
    }
    if (view.boosted) {
      chips.add(_StatusTag(label: 'BOOSTED', color: Colors.lightBlueAccent));
    }
    return chips;
  }

  Color _progressColor(BuildingFlowState state) {
    switch (state) {
      case BuildingFlowState.starved:
        return Colors.redAccent;
      case BuildingFlowState.capped:
        return Colors.orangeAccent;
      case BuildingFlowState.running:
        return Colors.greenAccent;
      case BuildingFlowState.idle:
        return Colors.blueGrey;
    }
  }
}

class _ExpandedIndustryInfo extends StatelessWidget {
  final BuildingConfig building;
  final _IndustryTileViewData view;

  const _ExpandedIndustryInfo({
    required this.building,
    required this.view,
  });

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          building.description,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ...building.produces.entries.map((e) {
              final name = engine.config.resources[e.key]?.name ?? e.key;
              return _MetaPill(
                label: '+$name ${formatNumber(e.value)}',
                color: Colors.greenAccent,
              );
            }),
            ...building.consumes.entries.map((e) {
              final name = engine.config.resources[e.key]?.name ?? e.key;
              return _MetaPill(
                label: '-$name ${formatNumber(e.value)}',
                color: Colors.redAccent,
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _MetaPill(
              label: 'Cycle ${building.cycleSeconds.toStringAsFixed(1)}s',
              color: Colors.cyanAccent,
            ),
            const SizedBox(width: 8),
            _MetaPill(
              label: 'Manager: Unassigned',
              color: Colors.grey,
            ),
          ],
        ),
        if (view.totalCost.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Next ${view.buyLabel} cost',
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: view.totalCost.entries.map((e) {
              final have = engine.state.resources[e.key] ?? 0.0;
              final enough = have >= e.value;
              final name = engine.config.resources[e.key]?.name ?? e.key;
              return Text(
                '$name ${formatNumber(e.value)}',
                style: TextStyle(
                  color: enough ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 11,
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final String iconName;
  final bool active;

  const _IconBadge({required this.iconName, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        iconFromString(iconName),
        size: 24,
        color: active ? Colors.lightBlueAccent : Colors.grey,
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final int level;
  const _LevelChip({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Lv $level',
        style: const TextStyle(fontSize: 11, color: Colors.lightBlueAccent),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

@immutable
class _IndustryTileViewData {
  final int level;
  final double progress01;
  final double outputRate;
  final double storagePercent;
  final BuildingFlowState flowState;
  final bool boosted;
  final bool canAfford;
  final bool atMax;
  final String buyLabel;
  final Map<String, double> totalCost;

  const _IndustryTileViewData({
    required this.level,
    required this.progress01,
    required this.outputRate,
    required this.storagePercent,
    required this.flowState,
    required this.boosted,
    required this.canAfford,
    required this.atMax,
    required this.buyLabel,
    required this.totalCost,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _IndustryTileViewData &&
        other.level == level &&
        other.progress01 == progress01 &&
        other.outputRate == outputRate &&
        other.storagePercent == storagePercent &&
        other.flowState == flowState &&
        other.boosted == boosted &&
        other.canAfford == canAfford &&
        other.atMax == atMax &&
        other.buyLabel == buyLabel &&
        mapEquals(other.totalCost, totalCost);
  }

  @override
  int get hashCode => Object.hash(
        level,
        progress01,
        outputRate,
        storagePercent,
        flowState,
        boosted,
        canAfford,
        atMax,
        buyLabel,
        totalCost.length,
      );
}
