// PNG -> 160x160 RGB565 Konvertierung fuer Cloud-Eye-Upload via BLE.
// LVGL auf dem ESP32-C3 erwartet little-endian RGB565: low-byte zuerst.
//
// Zusaetzlich: Transparente und sehr dunkle Pixel werden zu Weiss konvertiert,
// damit der Auge-Hintergrund mit dem weissen Display-Background konsistent ist.

import 'dart:typed_data';
import 'package:image/image.dart' as img;

const int kEyeWidth  = 160;
const int kEyeHeight = 160;
const int kRgb565ByteCount = kEyeWidth * kEyeHeight * 2;  // 51200 Bytes

// Schwellwert: Pixel mit Summe R+G+B unter diesem Wert gelten als "fast schwarz"
// und werden zu Weiss konvertiert. 24 = (8+8+8) = sehr dunkles dunkles Schwarz.
// Hoehere Werte = aggressiver, koennte auch dunkelgraue Pupillen treffen.
const int kBlackThreshold = 24;
// Alpha-Schwellwert fuer Transparenz: Pixel mit alpha < diesem Wert -> weiss
const int kAlphaThreshold = 128;

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
      int r = p.r.toInt();
      int g = p.g.toInt();
      int b = p.b.toInt();
      final a = p.a.toInt();

      // Transparent oder sehr dunkel? -> Weiss als Hintergrund
      if (a < kAlphaThreshold || (r + g + b) < kBlackThreshold) {
        r = 255; g = 255; b = 255;
      }

      final r5 = (r >> 3) & 0x1F;
      final g6 = (g >> 2) & 0x3F;
      final b5 = (b >> 3) & 0x1F;
      final v = (r5 << 11) | (g6 << 5) | b5;
      // little-endian
      out[o++] = v & 0xFF;
      out[o++] = (v >> 8) & 0xFF;
    }
  }
  return out;
}
