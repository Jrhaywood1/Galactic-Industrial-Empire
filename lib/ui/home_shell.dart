import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_engine.dart';
import 'screens/empire_screen.dart';
import 'screens/missions_screen.dart';
import 'screens/research_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final contractBadgeCount = context.select<GameEngine, int>(
      (engine) => engine.getClaimableContractCount(),
    );

    final screens = <Widget>[
      const EmpireScreen(),
      const ContractsScreen(),
      const ResearchScreen(),
      const _MapLockedScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_index]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.factory_outlined),
            activeIcon: Icon(Icons.factory),
            label: 'Empire',
          ),
          BottomNavigationBarItem(
            icon: _BadgeIcon(
              showBadge: contractBadgeCount > 0,
              icon: Icons.assignment_outlined,
            ),
            activeIcon: _BadgeIcon(
              showBadge: contractBadgeCount > 0,
              icon: Icons.assignment,
            ),
            label: 'Contracts',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.science_outlined),
            activeIcon: Icon(Icons.science),
            label: 'Research',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.rocket_launch_outlined),
            activeIcon: Icon(Icons.rocket_launch),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final bool showBadge;
  final IconData icon;

  const _BadgeIcon({required this.showBadge, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: showBadge,
      smallSize: 8,
      child: Icon(icon),
    );
  }
}

class _MapLockedScreen extends StatelessWidget {
  const _MapLockedScreen();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.public, size: 52, color: Colors.grey[500]),
            const SizedBox(height: 10),
            const Text(
              'Map & Ships locked for MVP',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Unlock Shipyard progression to enable expansion systems.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
