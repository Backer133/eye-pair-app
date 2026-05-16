import 'package:flutter/material.dart';
import '../ble_service.dart';
import 'settings.dart';
import 'diagnostics.dart';
import 'cloud_eyes_screen.dart';

class HomeScreen extends StatefulWidget {
  final EyeBle ble;
  const HomeScreen({super.key, required this.ble});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    widget.ble.addListener(_onBleUpdate);
  }

  @override
  void dispose() {
    widget.ble.removeListener(_onBleUpdate);
    super.dispose();
  }

  void _onBleUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final ble = widget.ble;
    final screens = [
      _EyeGrid(ble: ble),
      CloudEyesScreen(ble: ble),
      SettingsScreen(ble: ble),
      DiagnosticsScreen(ble: ble),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(ble.device?.platformName ?? 'EyePair'),
        actions: [
          if (ble.connected)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.bluetooth_connected, color: Colors.lightGreen),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.bluetooth_disabled, color: Colors.red),
            ),
          IconButton(
            icon: const Icon(Icons.link_off),
            onPressed: () async {
              await ble.disconnect();
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: screens[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Augen'),
          NavigationDestination(icon: Icon(Icons.cloud_download), label: 'Cloud'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Einstellungen'),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Diagnose'),
        ],
      ),
    );
  }
}

/// Augen-Grid: hardcoded Augen (Asset-Vorschau) + Cloud-Slots (Slot-Nummer).
/// Total Eyes auf ESP = kHardcodedEyeCount + kCloudSlotCount.
class _EyeGrid extends StatelessWidget {
  final EyeBle ble;
  const _EyeGrid({required this.ble});

  int get _totalCount => kHardcodedEyeCount + kCloudSlotCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _totalCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, i) {
        final isCloud  = i >= kHardcodedEyeCount;
        final cloudSlot = isCloud ? (i - kHardcodedEyeCount) : -1;
        final selected = i == ble.eyeId;
        return Material(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => ble.setEyeId(i),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Expanded(
                    child: isCloud
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud,
                                    size: 32,
                                    color: Theme.of(context).colorScheme.outline),
                                const SizedBox(height: 4),
                                Text('Slot ${cloudSlot + 1}',
                                    style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(kEyeAssets[i], fit: BoxFit.cover),
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCloud ? 'Cloud ${cloudSlot + 1}' : kEyeLabels[i],
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
