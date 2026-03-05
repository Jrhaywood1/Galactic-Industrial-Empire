import 'package:flutter/material.dart';

import '../../engine/game_engine.dart';

class BulkBuySelector extends StatelessWidget {
  final BuyAmountSetting value;
  final ValueChanged<BuyAmountSetting> onChanged;

  const BulkBuySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<BuyAmountSetting>(
      showSelectedIcon: false,
      segments: BuyAmountSetting.values
          .map(
            (setting) => ButtonSegment<BuyAmountSetting>(
              value: setting,
              label: Text(setting.label),
            ),
          )
          .toList(growable: false),
      selected: <BuyAmountSetting>{value},
      onSelectionChanged: (selection) {
        final next = selection.isEmpty ? value : selection.first;
        onChanged(next);
      },
    );
  }
}
