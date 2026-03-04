enum ResourceType { iron, steel, alloy }

class ResourceWallet {
  final Map<ResourceType, int> amounts;

  ResourceWallet({Map<ResourceType, int>? amounts}) : amounts = amounts ?? {for (var r in ResourceType.values) r: 0};

  int get(ResourceType r) => amounts[r] ?? 0;
  void add(ResourceType r, int v) => amounts[r] = (amounts[r] ?? 0) + v;
  bool has(ResourceType r, int v) => (amounts[r] ?? 0) >= v;
  void spend(ResourceType r, int v) => amounts[r] = (amounts[r] ?? 0) - v;

  Map<String, dynamic> toJson() => {for (var e in amounts.entries) e.key.name: e.value};
  factory ResourceWallet.fromJson(Map<String, dynamic> j) {
    final w = ResourceWallet();
    for (final r in ResourceType.values) {
      w.amounts[r] = (j[r.name] ?? 0) as int;
    }
    return w;
  }
}