import 'package:flutter/material.dart';

class PencairanPage extends StatelessWidget {
  static const route = '/pencairan';
  const PencairanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pencairan')),
      body: const Center(child: Text('Pencairan — replace me')),
    );
  }
}
