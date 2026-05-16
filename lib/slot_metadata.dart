// Persistiert pro PAIR_ID welche Cloud-Bilder in welchem Slot drauf sind.
// Layout im SharedPreferences:
//   slot_<pair_id>_<slot>_url   -> String (download_url)
//   slot_<pair_id>_<slot>_name  -> String (Anzeigename)

import 'package:shared_preferences/shared_preferences.dart';

class SlotMeta {
  final String name;
  final String url;
  SlotMeta(this.name, this.url);
}

class SlotMetadataStore {
  static String _keyUrl(int pid, int slot)  => 'slot_${pid}_${slot}_url';
  static String _keyName(int pid, int slot) => 'slot_${pid}_${slot}_name';

  static Future<SlotMeta?> get(int pairId, int slot) async {
    final sp = await SharedPreferences.getInstance();
    final url = sp.getString(_keyUrl(pairId, slot));
    if (url == null || url.isEmpty) return null;
    final name = sp.getString(_keyName(pairId, slot)) ?? '?';
    return SlotMeta(name, url);
  }

  static Future<void> set(int pairId, int slot, String name, String url) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_keyUrl(pairId, slot), url);
    await sp.setString(_keyName(pairId, slot), name);
  }

  static Future<void> clear(int pairId, int slot) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_keyUrl(pairId, slot));
    await sp.remove(_keyName(pairId, slot));
  }
}
