import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: const [
          ListTile(
            title: Text('Sound'),
            subtitle: Text('Coming soon'),
          ),
          ListTile(
            title: Text('Graphics'),
            subtitle: Text('Coming soon'),
          ),
          ListTile(
            title: Text('Reset Game'),
            subtitle: Text('Coming soon'),
          ),
        ],
      ),
    );
  }
}