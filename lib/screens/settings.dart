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
  late TextEditingController _pidCtl;

  @override
  void initState() {
    super.initState();
    _brightness = widget.ble.brightness.toDouble();
    _anim = widget.ble.animEnabled == 1;
    _pidCtl = TextEditingController(text: widget.ble.pairId.toString());
  }

  @override
  void dispose() {
    _pidCtl.dispose();
    super.dispose();
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
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.group_work),
                    SizedBox(width: 8),
                    Text('PAIR_ID', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'PAIR_ID trennt mehrere Augenpaare auf gleichem Channel. '
                  'Aenderung erst nach Reboot des Masters wirksam.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pidCtl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '1..255',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      child: const Text('Setzen'),
                      onPressed: () {
                        final v = int.tryParse(_pidCtl.text);
                        if (v == null || v < 1 || v > 255) return;
                        widget.ble.setPairId(v);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('PAIR_ID $v gespeichert. Master rebooten.')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
