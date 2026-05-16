import 'package:flutter/material.dart';
import '../ble_service.dart';

class SettingsScreen extends StatefulWidget {
  final EyeBle ble;
  const SettingsScreen({super.key, required this.ble});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _brightness;
  late bool _anim;

  @override
  void initState() {
    super.initState();
    _brightness = widget.ble.brightness.toDouble();
    _anim = widget.ble.animEnabled == 1;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.brightness_6),
                    const SizedBox(width: 8),
                    const Text('Helligkeit', style: TextStyle(fontSize: 16)),
                    const Spacer(),
                    Text('${_brightness.round()}'),
                  ],
                ),
                Slider(
                  min: 0, max: 255, divisions: 51,
                  value: _brightness,
                  onChanged: (v) => setState(() => _brightness = v),
                  onChangeEnd: (v) => widget.ble.setBrightness(v.round()),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
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
      ],
    );
  }
}
