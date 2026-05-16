import 'package:flutter/material.dart';
import '../ble_service.dart';

class DiagnosticsScreen extends StatelessWidget {
  final EyeBle ble;
  const DiagnosticsScreen({super.key, required this.ble});

  Color _stateColor(int s) {
    switch (s) {
      case 4: return Colors.green;       // LINKED
      case 5: return Colors.orange;      // DEGRADED
      case 1: return Colors.blue;        // QUICK_RECONNECT
      case 2: return Colors.amber;       // DISCOVERY
      case 3: return Colors.purple;      // PAIRING
      case 6: return Colors.red;         // LOST
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateName = kPairStateNames[ble.linkState] ?? '?';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _bigCard(
          icon: Icons.link,
          color: _stateColor(ble.linkState),
          title: 'Verbindungs-Status',
          value: stateName,
          sub: 'Master ↔ Slave State-Machine',
        ),
        _row(Icons.timer, 'Silence',
             '${ble.silenceMs} ms', _silenceColor(ble.silenceMs)),
        _row(Icons.signal_cellular_alt, 'Loss-Rate',
             '${ble.lossRate} %', _lossColor(ble.lossRate)),
        const SizedBox(height: 12),
        _row(Icons.devices, 'Master MAC', ble.masterMac, null),
        _row(Icons.devices_other, 'Slave MAC', ble.slaveMac, null),
        _row(Icons.image, 'Aktuelles Eye',
             ble.eyeId < kEyeLabels.length ? kEyeLabels[ble.eyeId] : '?', null),
        _row(Icons.animation, 'Animation',
             ble.animEnabled == 1 ? 'an' : 'aus', null),
        _row(Icons.tag, 'PAIR_ID', '${ble.pairId}', null),
      ],
    );
  }

  Color _silenceColor(int ms) {
    if (ms < 1000) return Colors.green;
    if (ms < 4000) return Colors.orange;
    return Colors.red;
  }

  Color _lossColor(int loss) {
    if (loss < 30) return Colors.green;
    if (loss < 60) return Colors.orange;
    return Colors.red;
  }

  Widget _bigCard({required IconData icon, required Color color,
                    required String title, required String value, String? sub}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                  if (sub != null)
                    Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, Color? c) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: c),
        title: Text(label),
        trailing: Text(value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c)),
      ),
    );
  }
}
