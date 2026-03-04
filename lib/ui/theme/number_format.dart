String formatNumber(double value) {
  if (value.isNaN || value.isInfinite) return '0';

  final abs = value.abs();
  if (abs < 1000) {
    if (abs == abs.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  const suffixes = ['', 'K', 'M', 'B', 'T', 'Qa', 'Qi', 'Sx', 'Sp', 'Oc'];
  int tier = 0;
  double scaled = abs;
  while (scaled >= 1000 && tier < suffixes.length - 1) {
    scaled /= 1000;
    tier++;
  }

  final sign = value < 0 ? '-' : '';
  return '$sign${scaled.toStringAsFixed(2)}${suffixes[tier]}';
}

String formatRate(double rate) {
  if (rate == 0) return '';
  final sign = rate > 0 ? '+' : '';
  return '$sign${formatNumber(rate)}/s';
}
