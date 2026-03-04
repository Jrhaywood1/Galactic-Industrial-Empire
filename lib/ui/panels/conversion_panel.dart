import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine/game_engine.dart';

/// Legacy panel kept for compatibility.
///
/// In the current v1 economy, "conversions" are performed by buildings
/// (Refinery, Fuel Plant, Polymer Lab, etc.) rather than manual swap buttons.
/// This panel simply surfaces the current tier-1/2 resource amounts.
class ConversionPanel extends StatelessWidget {
  const ConversionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final r = engine.state.resources;

    String fmt(String id) => (r[id] ?? 0.0).toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Industrial Chain', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Ore: ${fmt('ore')}  →  Metal: ${fmt('metal')}'),
          Text('Gas: ${fmt('gas')}  →  Fuel: ${fmt('fuel')}'),
          Text('Ice: ${fmt('ice')}  →  Polymer: ${fmt('polymer')}'),
          const SizedBox(height: 8),
          const Text(
            'Tip: Build Refineries / Fuel Plants / Polymer Labs to perform conversions automatically.',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ]),
      ),
    );
  }
}
