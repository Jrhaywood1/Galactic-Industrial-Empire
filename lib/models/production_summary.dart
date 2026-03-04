class ProductionSummary {
  final Map<String, double> netRates;
  final Map<String, double> grossProduction;
  final Map<String, double> grossConsumption;
  final Map<String, double> capacities;

  const ProductionSummary({
    required this.netRates,
    required this.grossProduction,
    required this.grossConsumption,
    required this.capacities,
  });

  const ProductionSummary.empty()
      : netRates = const {},
        grossProduction = const {},
        grossConsumption = const {},
        capacities = const {};
}
