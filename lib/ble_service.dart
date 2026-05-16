import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// UUIDs MUESSEN identisch zu denen im Master.ino sein!
class EyeUuids {
  static final Guid svcEyeCtrl   = Guid("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  static final Guid chrEyeId     = Guid("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");
  static final Guid chrBrightness= Guid("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");
  static final Guid chrAnimEn    = Guid("6E400004-B5A3-F393-E0A9-E50E24DCCA9E");
  static final Guid chrPairIdBle = Guid("6E400005-B5A3-F393-E0A9-E50E24DCCA9E");
  static final Guid chrEyeCount  = Guid("6E400006-B5A3-F393-E0A9-E50E24DCCA9E");

  static final Guid svcDiag      = Guid("6E400010-B5A3-F393-E0A9-E50E24DCCA9E");
  static final Guid chrState     = Guid("6E400011-B5A3-F393-E0A9-E50E24DCCA9E");
  static final Guid chrLossRate  = Guid("6E400012-B5A3-F393-E0A9-E50E24DCCA9E");
  static final Guid chrSilenceMs = Guid("6E400013-B5A3-F393-E0A9-E50E24DCCA9E");
  static final Guid chrSlaveMac  = Guid("6E400014-B5A3-F393-E0A9-E50E24DCCA9E");
  static final Guid chrMasterMac = Guid("6E400015-B5A3-F393-E0A9-E50E24DCCA9E");
}

const Map<int, String> kPairStateNames = {
  0: 'BOOT',
  1: 'QUICK_RECONNECT',
  2: 'DISCOVERY',
  3: 'PAIRING',
  4: 'LINKED',
  5: 'DEGRADED',
  6: 'LOST',
};

// Asset-Namen zu Eye-Index. MUSS in der Reihenfolge identisch zu EYE_IMAGES[]
// im Master.ino + Slave.ino sein!
const List<String> kEyeAssets = [
  'assets/eyes/A1.jpg',
  'assets/eyes/A2.jpg',
  'assets/eyes/A3.jpg',
  'assets/eyes/A5.png',
  'assets/eyes/A7.png',
  'assets/eyes/A8.png',
  'assets/eyes/A9.png',
  'assets/eyes/A10.png',
  'assets/eyes/A11.png',
  'assets/eyes/A12.png',
  'assets/eyes/A13.png',
  'assets/eyes/A14.png',
];
const List<String> kEyeLabels = [
  'A1','A2','A3','A5','A7','A8','A9','A10','A11','A12','A13','A14'
];

class EyeBle extends ChangeNotifier {
  BluetoothDevice? device;
  final Map<Guid, BluetoothCharacteristic> _chars = {};

  // State exposed to UI
  int eyeId = 0;
  int brightness = 255;
  int animEnabled = 1;
  int pairId = 10;
  int eyeCount = 0;
  int linkState = 0;
  int lossRate = 0;
  int silenceMs = 0;
  String slaveMac = "--";
  String masterMac = "--";
  bool connected = false;

  StreamSubscription<List<int>>? _subEyeId;
  StreamSubscription<List<int>>? _subState;
  StreamSubscription<List<int>>? _subLoss;
  StreamSubscription<List<int>>? _subSilence;
  StreamSubscription<BluetoothConnectionState>? _subConn;

  Future<void> connectAndDiscover(BluetoothDevice d) async {
    device = d;
    await d.connect(timeout: const Duration(seconds: 10), autoConnect: false);

    _subConn = d.connectionState.listen((s) {
      connected = (s == BluetoothConnectionState.connected);
      notifyListeners();
    });

    final services = await d.discoverServices();
    for (final s in services) {
      for (final c in s.characteristics) {
        _chars[c.uuid] = c;
      }
    }

    await _readAll();
    await _subscribeNotifies();

    connected = true;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _subEyeId?.cancel();
    await _subState?.cancel();
    await _subLoss?.cancel();
    await _subSilence?.cancel();
    await _subConn?.cancel();
    _chars.clear();
    try { await device?.disconnect(); } catch (_) {}
    connected = false;
    notifyListeners();
  }

  Future<void> _readAll() async {
    final eid   = await _readByte(EyeUuids.chrEyeId);
    final br    = await _readByte(EyeUuids.chrBrightness);
    final anim  = await _readByte(EyeUuids.chrAnimEn);
    final pid   = await _readByte(EyeUuids.chrPairIdBle);
    final cnt   = await _readByte(EyeUuids.chrEyeCount);
    final st    = await _readByte(EyeUuids.chrState);
    final loss  = await _readByte(EyeUuids.chrLossRate);
    final smac  = await _readBytes(EyeUuids.chrSlaveMac);
    final mmac  = await _readBytes(EyeUuids.chrMasterMac);
    final sil   = await _readBytes(EyeUuids.chrSilenceMs);

    if (eid != null)  eyeId      = eid;
    if (br != null)   brightness = br;
    if (anim != null) animEnabled = anim;
    if (pid != null)  pairId     = pid;
    if (cnt != null)  eyeCount   = cnt;
    if (st != null)   linkState  = st;
    if (loss != null) lossRate   = loss;
    if (smac != null && smac.length == 6) slaveMac  = _fmtMac(smac);
    if (mmac != null && mmac.length == 6) masterMac = _fmtMac(mmac);
    if (sil != null && sil.length >= 4) {
      silenceMs = ByteData.sublistView(Uint8List.fromList(sil)).getUint32(0, Endian.little);
    }
  }

  Future<void> _subscribeNotifies() async {
    final ce = _chars[EyeUuids.chrEyeId];
    if (ce != null) {
      await ce.setNotifyValue(true);
      _subEyeId = ce.lastValueStream.listen((v) {
        if (v.isNotEmpty) { eyeId = v[0]; notifyListeners(); }
      });
    }
    final cs = _chars[EyeUuids.chrState];
    if (cs != null) {
      await cs.setNotifyValue(true);
      _subState = cs.lastValueStream.listen((v) {
        if (v.isNotEmpty) { linkState = v[0]; notifyListeners(); }
      });
    }
    final cl = _chars[EyeUuids.chrLossRate];
    if (cl != null) {
      await cl.setNotifyValue(true);
      _subLoss = cl.lastValueStream.listen((v) {
        if (v.isNotEmpty) { lossRate = v[0]; notifyListeners(); }
      });
    }
    final csi = _chars[EyeUuids.chrSilenceMs];
    if (csi != null) {
      await csi.setNotifyValue(true);
      _subSilence = csi.lastValueStream.listen((v) {
        if (v.length >= 4) {
          silenceMs = ByteData.sublistView(Uint8List.fromList(v)).getUint32(0, Endian.little);
          notifyListeners();
        }
      });
    }
  }

  Future<int?> _readByte(Guid uuid) async {
    final c = _chars[uuid];
    if (c == null) return null;
    try {
      final v = await c.read();
      return v.isNotEmpty ? v[0] : null;
    } catch (e) { return null; }
  }

  Future<List<int>?> _readBytes(Guid uuid) async {
    final c = _chars[uuid];
    if (c == null) return null;
    try { return await c.read(); } catch (e) { return null; }
  }

  Future<void> setEyeId(int id) async {
    final c = _chars[EyeUuids.chrEyeId]; if (c == null) return;
    await c.write([id], withoutResponse: false);
    eyeId = id; notifyListeners();
  }

  Future<void> setBrightness(int b) async {
    final c = _chars[EyeUuids.chrBrightness]; if (c == null) return;
    await c.write([b.clamp(0, 255)], withoutResponse: false);
    brightness = b; notifyListeners();
  }

  Future<void> setAnimEnabled(bool en) async {
    final c = _chars[EyeUuids.chrAnimEn]; if (c == null) return;
    await c.write([en ? 1 : 0], withoutResponse: false);
    animEnabled = en ? 1 : 0; notifyListeners();
  }

  Future<void> setPairId(int pid) async {
    final c = _chars[EyeUuids.chrPairIdBle]; if (c == null) return;
    await c.write([pid.clamp(1, 255)], withoutResponse: false);
    pairId = pid; notifyListeners();
  }

  static String _fmtMac(List<int> b) {
    return b.map((x) => x.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
  }
}
