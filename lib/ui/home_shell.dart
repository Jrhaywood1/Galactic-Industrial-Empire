import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_engine.dart';
import 'screens/empire_screen.dart';
import 'screens/research_screen.dart';
import 'screens/missions_screen.dart';
import 'screens/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Keep engine alive; this also guarantees rebuilds on state changes when needed
    context.watch<GameEngine>();

    final screens = <Widget>[
      const EmpireScreen(),
      const ResearchScreen(),
      const MissionsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_index]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.factory_outlined),
            activeIcon: Icon(Icons.factory),
            label: 'Empire',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.science_outlined),
            activeIcon: Icon(Icons.science),
            label: 'Research',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Missions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}