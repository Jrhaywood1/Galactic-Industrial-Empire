import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../models/config/technology_config.dart';
import '../theme/app_theme.dart';
import '../theme/number_format.dart';

class ResearchScreen extends StatelessWidget {
  const ResearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final techs = engine.config.technologyList;

    final tiers = <int, List<TechnologyConfig>>{};
    for (final t in techs) {
      tiers.putIfAbsent(t.tier, () => []).add(t);
    }
    final sortedTiers = tiers.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _totalItems(sortedTiers, tiers),
      itemBuilder: (context, index) {
        int current = 0;
        for (final tier in sortedTiers) {
          final tierTechs = tiers[tier]!;
          if (index == current) {
            return _TierHeader(tier: tier);
          }
          current++;
          if (index < current + tierTechs.length) {
            return _TechCard(tech: tierTechs[index - current]);
          }
          current += tierTechs.length;
        }
        return const SizedBox.shrink();
      },
    );
  }

  int _totalItems(
      List<int> sortedTiers, Map<int, List<TechnologyConfig>> tiers) {
    int count = 0;
    for (final tier in sortedTiers) {
      count += 1 + tiers[tier]!.length;
    }
    return count;
  }
}

class _TierHeader extends StatelessWidget {
  final int tier;
  const _TierHeader({required this.tier});

  static const _tierNames = {
    1: 'Foundational Research',
    2: 'Applied Sciences',
    3: 'Advanced Theory',
    4: 'Interstellar Engineering',
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

class _TechCard extends StatelessWidget {
  final TechnologyConfig tech;
  const _TechCard({required this.tech});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final isResearched = engine.state.unlockedTechs.contains(tech.id);
    final canResearch = engine.canResearchTech(tech.id);
    final prereqsMet = tech.prerequisites
        .every((p) => engine.state.unlockedTechs.contains(p));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Opacity(
        opacity: prereqsMet || isResearched ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isResearched
                      ? Colors.greenAccent.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: isResearched
                      ? Border.all(
                          color: Colors.greenAccent.withValues(alpha: 0.4))
                      : null,
                ),
                child: Icon(
                  iconFromString(tech.icon),
                  size: 24,
                  color: isResearched ? Colors.greenAccent : Colors.grey,
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
                        Flexible(
                          child: Text(
                            tech.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isResearched) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.check_circle,
                              size: 16, color: Colors.greenAccent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tech.description,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Effects
                    _buildEffects(engine),
                    // Cost
                    if (!isResearched) _buildCost(engine),
                    // Prerequisites
                    if (!prereqsMet && !isResearched) _buildPrereqs(engine),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Research button
              if (!isResearched)
                SizedBox(
                  width: 80,
                  child: ElevatedButton(
                    onPressed: canResearch
                        ? () =>
                            context.read<GameEngine>().researchTech(tech.id)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canResearch
                          ? const Color(0xFF9370DB)
                          : null,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Research', style: TextStyle(fontSize: 11)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEffects(GameEngine engine) {
    return Wrap(
      spacing: 6,
      children: tech.effects.map((e) {
        String label;
        Color color = Colors.cyanAccent;
        switch (e.type) {
          case 'production_multiplier':
            final name = engine.config.buildings[e.target]?.name ?? e.target ?? '';
            label = '$name x${e.value}';
          case 'cost_reduction':
            final name = engine.config.buildings[e.target]?.name ?? e.target ?? '';
            final pct = ((1.0 - (e.value ?? 1.0)) * 100).round();
            label = '$name -$pct% cost';
            color = Colors.greenAccent;
          case 'global_production_multiplier':
            label = 'All production x${e.value}';
            color = Colors.amberAccent;
          case 'global_consumption_reduction':
            final pct = ((1.0 - (e.value ?? 1.0)) * 100).round();
            label = 'All consumption -$pct%';
            color = Colors.greenAccent;
          case 'unlock_resource':
            final name =
                engine.config.resources[e.target]?.name ?? e.target ?? '';
            label = 'Unlock $name';
            color = Colors.purpleAccent;
          default:
            label = e.type;
        }
        return Text(label, style: TextStyle(fontSize: 10, color: color));
      }).toList(),
    );
  }

  Widget _buildCost(GameEngine engine) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: 8,
        children: tech.cost.entries.map((e) {
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
      ),
    );
  }

  Widget _buildPrereqs(GameEngine engine) {
    final missing = tech.prerequisites
        .where((p) => !engine.state.unlockedTechs.contains(p))
        .map((p) => engine.config.technologies[p]?.name ?? p)
        .join(', ');
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        'Requires: $missing',
        style: const TextStyle(fontSize: 10, color: Colors.orangeAccent),
      ),
    );
  }
}
