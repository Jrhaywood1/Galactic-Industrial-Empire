class BuildingState {
  final String id;
  int count;
  bool managerOwned;

  BuildingState({required this.id, this.count = 0, this.managerOwned = false});

  Map<String, dynamic> toJson() => {"id": id, "count": count, "managerOwned": managerOwned};

  factory BuildingState.fromJson(Map<String, dynamic> j) => BuildingState(
        id: j["id"],
        count: j["count"] ?? 0,
        managerOwned: j["managerOwned"] ?? false,
      );
}