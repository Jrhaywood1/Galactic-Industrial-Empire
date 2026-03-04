class BuildingMilestone {
  final int count;
  final double multiplier;
  BuildingMilestone({required this.count, required this.multiplier});

  factory BuildingMilestone.fromJson(Map<String, dynamic> j) =>
      BuildingMilestone(count: j['count'], multiplier: (j['multiplier'] as num).toDouble());
}

class AutomationDef {
  final int unlockAtCount;
  final double managerCost;
  AutomationDef({required this.unlockAtCount, required this.managerCost});

  factory AutomationDef.fromJson(Map<String, dynamic> j) => AutomationDef(
        unlockAtCount: j['unlockAtCount'],
        managerCost: (j['managerCost'] as num).toDouble(),
      );
}

class BuildingDef {
  final String id;
  final String name;
  final double baseCost;
  final double costGrowth;
  final double baseCreditsPerSec;
  final List<BuildingMilestone> milestones;
  final AutomationDef? automation;

  BuildingDef({
    required this.id,
    required this.name,
    required this.baseCost,
    required this.costGrowth,
    required this.baseCreditsPerSec,
    required this.milestones,
    required this.automation,
  });

  factory BuildingDef.fromJson(Map<String, dynamic> j) => BuildingDef(
        id: j['id'],
        name: j['name'],
        baseCost: (j['baseCost'] as num).toDouble(),
        costGrowth: (j['costGrowth'] as num).toDouble(),
        baseCreditsPerSec: (j['baseCreditsPerSec'] as num).toDouble(),
        milestones: (j['milestones'] as List? ?? [])
            .map((e) => BuildingMilestone.fromJson(e))
            .toList(),
        automation: j['automation'] == null ? null : AutomationDef.fromJson(j['automation']),
      );
}