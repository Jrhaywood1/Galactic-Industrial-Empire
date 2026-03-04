import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../services/save_service.dart';

class GameLoopWidget extends StatefulWidget {
  final Widget child;
  const GameLoopWidget({required this.child, super.key});

  @override
  State<GameLoopWidget> createState() => _GameLoopWidgetState();
}

class _GameLoopWidgetState extends State<GameLoopWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  Duration _lastTickTime = Duration.zero;
  Duration _lastSaveTime = Duration.zero;

  static const _tickInterval = Duration(seconds: 1);
  static const _saveInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick);
    _ticker.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameEngine>().processOfflineEarnings();
    });
  }

  void _onTick(Duration elapsed) {
    if (elapsed - _lastTickTime >= _tickInterval) {
      _lastTickTime = elapsed;
      context.read<GameEngine>().tick(1.0);
    }
    if (elapsed - _lastSaveTime >= _saveInterval) {
      _lastSaveTime = elapsed;
      SaveService.saveState(context.read<GameEngine>().state);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final engine = context.read<GameEngine>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      SaveService.saveState(engine.state);
    } else if (state == AppLifecycleState.resumed) {
      engine.processOfflineEarnings();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
