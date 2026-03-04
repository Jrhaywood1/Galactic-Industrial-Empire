import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';

class DebugPanel extends StatelessWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();

    return Positioned(
      right: 8,
      bottom: 8,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text("Runtime: ${engine.runtime.inMinutes}m"),
            Text("Speed: ${engine.gameSpeed}x"),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              _speedBtn(context, 1.0),
              _speedBtn(context, 2.0),
              _speedBtn(context, 5.0),
              _speedBtn(context, 10.0),
            ])
          ]),
        ),
      ),
    );
  }

  Widget _speedBtn(BuildContext context, double v) {
    final engine = context.read<GameEngine>();
    return ElevatedButton(
      onPressed: () => engine.gameSpeed = v,
      child: Text("${v.toStringAsFixed(0)}x"),
    );
  }
}