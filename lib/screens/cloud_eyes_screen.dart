import 'package:flutter/material.dart';
import '../ble_service.dart';
import '../cloud_eyes.dart';
import '../image_pipeline.dart';
import '../slot_metadata.dart';

class CloudEyesScreen extends StatefulWidget {
  final EyeBle ble;
  final Future<void> Function()? onSlotMetaChanged;
  const CloudEyesScreen({super.key, required this.ble, this.onSlotMetaChanged});
  @override
  State<CloudEyesScreen> createState() => _CloudEyesScreenState();
}

class _CloudEyesScreenState extends State<CloudEyesScreen> {
  final _api = GithubCloudEyes();
  List<CloudEye>? _eyes;
  String? _error;
  bool _loading = false;

  // Download-Status
  bool   _downloading = false;
  int    _downloadDone = 0;
  int    _downloadTotal = 0;
  String _downloadName = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _api.list();
      if (!mounted) return;
      setState(() { _eyes = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _downloadToSlot(CloudEye eye, int slot) async {
    if (_downloading) return;
    setState(() {
      _downloading = true;
      _downloadDone = 0;
      _downloadTotal = 0;
      _downloadName = '${eye.name} -> Slot ${slot + 1}';
    });
    try {
      final pngBytes = await _api.download(eye);
      final rgb565 = pngToRgb565(pngBytes);
      await widget.ble.uploadEye(slot, rgb565, onProgress: (sent, total) {
        if (!mounted) return;
        setState(() { _downloadDone = sent; _downloadTotal = total; });
      });
      // Slot-Metadata persistieren
      await SlotMetadataStore.set(widget.ble.pairId, slot, eye.name, eye.downloadUrl);
      await widget.onSlotMetaChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${eye.name}" auf Slot ${slot + 1} geladen.\n'
              'App trennt sich kurz, damit Master ungestoert an Slave senden kann.'),
          duration: const Duration(seconds: 4),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 700));
      try { await widget.ble.disconnect(); } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download-Fehler: $e')),
      );
    } finally {
      if (mounted) setState(() { _downloading = false; });
    }
  }

  Future<void> _pickSlotAndDownload(CloudEye eye) async {
    final slot = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('"${eye.name}" auf welchen Slot herunterladen?'),
        children: [
          for (int s = 0; s < kCloudSlotCount; s++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, s),
              child: Row(children: [
                const Icon(Icons.cloud_download),
                const SizedBox(width: 8),
                Text('Slot ${s + 1}'),
              ]),
            ),
        ],
      ),
    );
    if (slot != null) await _downloadToSlot(eye, slot);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_downloading)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lade auf Augen: $_downloadName',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _downloadTotal > 0 ? _downloadDone / _downloadTotal : null,
                    ),
                    const SizedBox(height: 4),
                    Text('$_downloadDone / $_downloadTotal Chunks',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        if (_error != null)
          Container(
            width: double.infinity,
            color: Colors.red.withOpacity(0.2),
            padding: const EdgeInsets.all(12),
            child: Text(_error!),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _eyes == null || _eyes!.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 200),
                          Center(child: Text('Keine Augen in der Cloud gefunden.\n'
                              'Der Admin hat noch keine Augen bereit gestellt.',
                              textAlign: TextAlign.center)),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _eyes!.length,
                        itemBuilder: (_, i) {
                          final e = _eyes![i];
                          return Card(
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  e.downloadUrl,
                                  width: 56, height: 56, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                ),
                              ),
                              title: Text(e.name),
                              subtitle: Text('${(e.sizeBytes / 1024).toStringAsFixed(1)} KB'),
                              trailing: ElevatedButton.icon(
                                icon: const Icon(Icons.cloud_download),
                                label: const Text('Download'),
                                onPressed: _downloading ? null : () => _pickSlotAndDownload(e),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }
}
