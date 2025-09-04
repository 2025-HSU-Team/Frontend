import 'package:flutter/material.dart';
import 'components/home_screen.dart';

void main() {
  runApp(const SoSawApp());
}

class SoSawApp extends StatelessWidget {
  const SoSawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoSaw',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
