import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _storageKey = 'my_cabinet';

  // 1. Save or Update medicine
  static Future<void> saveMedicine(Map<String, String> medicine) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cabinetJson = prefs.getStringList(_storageKey) ?? [];

    // Check if medicine with this code already exists
    int existingIndex = -1;
    for (int i = 0; i < cabinetJson.length; i++) {
      Map<String, dynamic> item = jsonDecode(cabinetJson[i]);
      if (item['code'] == medicine['code']) {
        existingIndex = i;
        break;
      }
    }

    if (existingIndex != -1) {
      // UPDATE: Replace existing entry
      cabinetJson[existingIndex] = jsonEncode(medicine);
    } else {
      // ADD: Create new entry
      cabinetJson.add(jsonEncode(medicine));
    }

    await prefs.setStringList(_storageKey, cabinetJson);
  }

  // 2. Read full cabinet
  static Future<List<Map<String, dynamic>>> getCabinet() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cabinetJson = prefs.getStringList(_storageKey) ?? [];

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

  // 4. Clear all data
  static Future<void> clearCabinet() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}