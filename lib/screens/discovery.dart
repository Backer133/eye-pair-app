import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ble_service.dart';
import 'home.dart';

class DiscoveryScreen extends StatefulWidget {
  final EyeBle ble;
  const DiscoveryScreen({super.key, required this.ble});
  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final List<ScanResult> _results = [];
  StreamSubscription<List<ScanResult>>? _subScan;
  bool _scanning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _ensurePermissions();
    if (!await FlutterBluePlus.isSupported) {
      setState(() => _error = "BLE wird auf diesem Geraet nicht unterstuetzt");
      return;
    }
    _scan();
  }

  Future<void> _ensurePermissions() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
    }
  }

  Future<void> _scan() async {
    setState(() {
      _results.clear();
      _scanning = true;
      _error = null;
    });
    await _subScan?.cancel();
    _subScan = FlutterBluePlus.onScanResults.listen((rs) {
      for (final r in rs) {
        final name = r.advertisementData.advName;
        if (!name.startsWith('EyePair')) continue;
        final idx = _results.indexWhere((x) => x.device.remoteId == r.device.remoteId);
        if (idx >= 0) {
          _results[idx] = r;
        } else {
          _results.add(r);
        }
      }
      setState(() {});
    });
    try {
      await FlutterBluePlus.startScan(
        withServices: [EyeUuids.svcEyeCtrl],
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: false,
      );
    } catch (e) {
      setState(() => _error = "Scan-Fehler: $e");
    }
    setState(() => _scanning = false);
  }

  Future<void> _connect(ScanResult r) async {
    try {
      await FlutterBluePlus.stopScan();
      await widget.ble.connectAndDiscover(r.device);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => HomeScreen(ble: widget.ble),
      ));
    } catch (e) {
      setState(() => _error = "Verbindungs-Fehler: $e");
    }
  }

  @override
  void dispose() {
    _subScan?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EyePair finden'),
        actions: [
          IconButton(
            icon: Icon(_scanning ? Icons.refresh : Icons.search),
            onPressed: _scanning ? null : _scan,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.withOpacity(.2),
              width: double.infinity,
              child: Text(_error!),
            ),
          if (_scanning) const LinearProgressIndicator(),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(_scanning
                        ? 'Suche EyePair-Geraete...'
                        : 'Keine Geraete gefunden.\nButton oben rechts erneut scannen.'),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final r = _results[i];
                      return ListTile(
                        leading: const Icon(Icons.remove_red_eye, size: 32),
                        title: Text(r.advertisementData.advName),
                        subtitle: Text('${r.device.remoteId}  •  RSSI ${r.rssi} dBm'),
                        onTap: () => _connect(r),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
