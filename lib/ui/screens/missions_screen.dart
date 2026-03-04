import 'package:flutter/material.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions'),
      ),
      body: const Center(
        child: Text(
          'Contracts system coming soon',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}