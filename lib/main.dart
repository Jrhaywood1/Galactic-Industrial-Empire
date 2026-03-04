import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/config_loader.dart';
import 'engine/game_engine.dart';
import 'models/state/game_state.dart';
import 'services/save_service.dart';
import 'ui/home_shell.dart';
import 'ui/screens/game_loop_widget.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await ConfigLoader.loadAll();
  final savedState = await SaveService.loadState();
  final state = savedState ?? GameState.newGame(config);
  final engine = GameEngine(config: config, state: state);

  runApp(
    ChangeNotifierProvider<GameEngine>.value(
      value: engine,
      child: const GalacticIndustrialEmpireApp(),
    ),
  );
}

class GalacticIndustrialEmpireApp extends StatelessWidget {
  const GalacticIndustrialEmpireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galactic Industrial Empire',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const GameLoopWidget(
        child: HomeShell(),
      ),
    );
  }
}