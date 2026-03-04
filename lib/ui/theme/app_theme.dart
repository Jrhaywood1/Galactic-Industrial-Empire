import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A73E8),
        brightness: Brightness.dark,
        surface: const Color(0xFF121212),
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E1E2E),
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D1117),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A73E8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      useMaterial3: true,
    );
  }
}

IconData iconFromString(String name) {
  const iconMap = <String, IconData>{
    'monetization_on': Icons.monetization_on,
    'diamond': Icons.diamond,
    'landscape': Icons.landscape,
    'ac_unit': Icons.ac_unit,
    'grain': Icons.grain,
    'bolt': Icons.bolt,
    'settings': Icons.settings,
    'view_in_ar': Icons.view_in_ar,
    'bubble_chart': Icons.bubble_chart,
    'memory': Icons.memory,
    'local_gas_station': Icons.local_gas_station,
    'science': Icons.science,
    'local_shipping': Icons.local_shipping,
    'storage': Icons.storage,
    'flare': Icons.flare,
    'blur_on': Icons.blur_on,
    'nights_stay': Icons.nights_stay,
    'waves': Icons.waves,
    'psychology': Icons.psychology,
    'auto_awesome': Icons.auto_awesome,
    'all_inclusive': Icons.all_inclusive,
    'thermostat': Icons.thermostat,
    'hardware': Icons.hardware,
    'wb_sunny': Icons.wb_sunny,
    'precision_manufacturing': Icons.precision_manufacturing,
    'account_balance': Icons.account_balance,
    'factory': Icons.factory,
    'biotech': Icons.biotech,
    'blur_circular': Icons.blur_circular,
    'brightness_high': Icons.brightness_high,
    'engineering': Icons.engineering,
    'smart_toy': Icons.smart_toy,
  };
  return iconMap[name] ?? Icons.help_outline;
}

Color colorFromHex(String hex) {
  final buffer = StringBuffer();
  final cleaned = hex.replaceFirst('#', '');
  if (cleaned.length == 6) buffer.write('FF');
  buffer.write(cleaned);
  return Color(int.parse(buffer.toString(), radix: 16));
}
