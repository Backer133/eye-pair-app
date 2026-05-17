import 'package:flutter/material.dart';
import '../ble_service.dart';

class SettingsScreen extends StatefulWidget {
  final EyeBle ble;
  const SettingsScreen({super.key, required this.ble});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _anim;

  @override
  void initState() {
    super.initState();
    _anim = widget.ble.animEnabled == 1;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.movie_filter),
            title: const Text('Animation'),
            subtitle: Text(_anim ? 'Augen-Animation laeuft' : 'Augen zentriert (pausiert)'),
            value: _anim,
            onChanged: (v) {
              setState(() => _anim = v);
              widget.ble.setAnimEnabled(v);
            },
          ),
        ),
        const SizedBox(height: 32),
        const Center(
          child: Text(
            'Created by Thomas Paul for Schafberg-Pass Sankt Gilgen',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
