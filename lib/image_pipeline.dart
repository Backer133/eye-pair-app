// PNG -> 160x160 RGB565 Konvertierung fuer Cloud-Eye-Upload via BLE.
// LVGL auf dem ESP32-C3 erwartet little-endian RGB565: low-byte zuerst.

import 'dart:typed_data';
import 'package:image/image.dart' as img;

const int kEyeWidth  = 160;
const int kEyeHeight = 160;
const int kRgb565ByteCount = kEyeWidth * kEyeHeight * 2;  // 51200 Bytes

/// Decodiert PNG (oder JPG), resized auf 160x160, konvertiert zu RGB565 LE.
/// Wirft Exception wenn PNG nicht dekodierbar ist.
Uint8List pngToRgb565(Uint8List pngBytes) {
  final src = img.decodeImage(pngBytes);
  if (src == null) {
    throw Exception('PNG/JPG konnte nicht dekodiert werden');
  }
  final resized = (src.width != kEyeWidth || src.height != kEyeHeight)
      ? img.copyResize(src, width: kEyeWidth, height: kEyeHeight, interpolation: img.Interpolation.linear)
      : src;

  final out = Uint8List(kRgb565ByteCount);
  int o = 0;
  for (int y = 0; y < kEyeHeight; y++) {
    for (int x = 0; x < kEyeWidth; x++) {
      final p = resized.getPixel(x, y);
      final r5 = (p.r.toInt() >> 3) & 0x1F;
      final g6 = (p.g.toInt() >> 2) & 0x3F;
      final b5 = (p.b.toInt() >> 3) & 0x1F;
      final v = (r5 << 11) | (g6 << 5) | b5;
      // little-endian
      out[o++] = v & 0xFF;
      out[o++] = (v >> 8) & 0xFF;
    }
  }
  return out;
}
