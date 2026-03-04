import '../models/building_def.dart';

double costForNext(BuildingDef def, int owned) {
  // geometric growth: baseCost * growth^owned
  return def.baseCost * _pow(def.costGrowth, owned);
}

double totalCostToBuy(BuildingDef def, int owned, int qty) {
  // sum of geometric series: base * g^owned * (g^qty - 1)/(g - 1)
  if (qty <= 0) return 0;
  final g = def.costGrowth;
  if ((g - 1.0).abs() < 1e-9) return def.baseCost * qty;
  return def.baseCost * _pow(g, owned) * ((_pow(g, qty) - 1.0) / (g - 1.0));
}

double milestoneMultiplier(BuildingDef def, int owned) {
  double mult = 1.0;
  for (final m in def.milestones) {
    if (owned >= m.count) mult *= m.multiplier;
  }
  return mult;
}

double creditsPerSecFor(BuildingDef def, int owned) {
  if (owned <= 0) return 0;
  return def.baseCreditsPerSec * owned * milestoneMultiplier(def, owned);
}

double paybackSecondsForPurchase(BuildingDef def, int owned, int qty) {
  final before = creditsPerSecFor(def, owned);
  final after = creditsPerSecFor(def, owned + qty);
  final delta = after - before;
  if (delta <= 0) return double.infinity;
  final cost = totalCostToBuy(def, owned, qty);
  return cost / delta;
}

double _pow(double a, int b) {
  double r = 1.0;
  for (int i = 0; i < b; i++) {
    r *= a;
  }
  return r;
}