import 'package:flutter/material.dart';
import 'ble_service.dart';
import 'screens/discovery.dart';

void main() {
  runApp(const EyePairApp());
}

class EyePairApp extends StatefulWidget {
  const EyePairApp({super.key});
  @override
  State<EyePairApp> createState() => _EyePairAppState();
}

class _EyePairAppState extends State<EyePairApp> {
  final ble = EyeBle();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EyePair',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
      ),
      home: DiscoveryScreen(ble: ble),
    );
  }
}
