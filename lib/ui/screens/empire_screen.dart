import 'package:flutter/material.dart';
import '../widgets/resource_bar.dart';
import '../widgets/building_list.dart';

class EmpireScreen extends StatelessWidget {
  const EmpireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ResourceBar(),
        Divider(height: 1, color: Colors.white10),
        Expanded(child: BuildingList()),
      ],
    );
  }
}
