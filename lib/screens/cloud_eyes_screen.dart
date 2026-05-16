import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../ble_service.dart';
import '../cloud_eyes.dart';
import '../image_pipeline.dart';

class CloudEyesScreen extends StatefulWidget {
  final EyeBle ble;
  const CloudEyesScreen({super.key, required this.ble});
  @override
  State<CloudEyesScreen> createState() => _CloudEyesScreenState();
}

class _CloudEyesScreenState extends State<CloudEyesScreen> {
  final _api = GithubCloudEyes();
  List<CloudEye>? _eyes;
  String? _error;
  bool _loading = false;

  // Upload-Status
  bool   _uploading = false;
  int    _uploadDone = 0;
  int    _uploadTotal = 0;
  String _uploadName = '';

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

  Future<void> _uploadToSlot(CloudEye eye, int slot) async {
    if (_uploading) return;
    setState(() {
      _uploading = true;
      _uploadDone = 0;
      _uploadTotal = 0;
      _uploadName = '${eye.name} -> Slot ${slot + 1}';
    });
    try {
      final pngBytes = await _api.download(eye);
      final rgb565 = pngToRgb565(pngBytes);
      await widget.ble.uploadEye(slot, rgb565, onProgress: (sent, total) {
        if (!mounted) return;
        setState(() { _uploadDone = sent; _uploadTotal = total; });
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${eye.name}" auf Slot ${slot + 1} hochgeladen')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload-Fehler: $e')),
      );
    } finally {
      if (mounted) setState(() { _uploading = false; });
    }
  }

  Future<void> _pickSlotAndUpload(CloudEye eye) async {
    final slot = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('"${eye.name}" auf welchen Slot?'),
        children: [
          for (int s = 0; s < kCloudSlotCount; s++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, s),
              child: Row(children: [
                const Icon(Icons.cloud_upload),
                const SizedBox(width: 8),
                Text('Slot ${s + 1}'),
              ]),
            ),
        ],
      ),
    );
    if (slot != null) await _uploadToSlot(eye, slot);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_uploading)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upload: $_uploadName',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _uploadTotal > 0 ? _uploadDone / _uploadTotal : null,
                    ),
                    const SizedBox(height: 4),
                    Text('$_uploadDone / $_uploadTotal Chunks',
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
                                icon: const Icon(Icons.cloud_upload),
                                label: const Text('Upload'),
                                onPressed: _uploading ? null : () => _pickSlotAndUpload(e),
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
