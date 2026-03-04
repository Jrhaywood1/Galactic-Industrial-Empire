import 'package:flutter/material.dart';

/// Bulk-buy selector used across building cards.
enum BuyQty { one, ten, twentyFive, max }

extension BuyQtyX on BuyQty {
  String get label {
    switch (this) {
      case BuyQty.one:
        return 'x1';
      case BuyQty.ten:
        return 'x10';
      case BuyQty.twentyFive:
        return 'x25';
      case BuyQty.max:
        return 'MAX';
    }
  }
}

class BulkBuyChips extends StatelessWidget {
  final BuyQty value;
  final ValueChanged<BuyQty> onChanged;

  const BulkBuyChips({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: BuyQty.values.map((q) {
        return ChoiceChip(
          label: Text(q.label),
          selected: q == value,
          onSelected: (_) => onChanged(q),
        );
      }).toList(),
    );
  }
}
