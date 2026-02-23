import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _storageKey = 'my_cabinet';

  // 1. Save medicine (Now handles batch, expiry, etc. automatically via Map)
  static Future<void> saveMedicine(Map<String, String> medicine) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get existing list
    List<String> cabinetJson = prefs.getStringList(_storageKey) ?? [];

    // Add new medicine (JSON format preserves all your new fields)
    cabinetJson.add(jsonEncode(medicine));

    // Save back to disk
    await prefs.setStringList(_storageKey, cabinetJson);
  }

  // 2. Read full cabinet
  static Future<List<Map<String, dynamic>>> getCabinet() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cabinetJson = prefs.getStringList(_storageKey) ?? [];

    // Decoding preserves the Batch and Expiry you added in the Details screen
    return cabinetJson
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();
  }

  // 3. Delete specific medicine by index
  static Future<void> deleteMedicine(int index) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cabinetJson = prefs.getStringList(_storageKey) ?? [];

    if (index >= 0 && index < cabinetJson.length) {
      cabinetJson.removeAt(index);
      await prefs.setStringList(_storageKey, cabinetJson);
    }
  }

  // 4. NEW: Clear all data (Useful for testing QR codes)
  static Future<void> clearCabinet() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}