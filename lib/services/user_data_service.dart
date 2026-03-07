import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists user-generated content:
///  - Per-item extras (notes, imagePath) keyed by item ID
///  - User-created PN items
class UserDataService {
  // ── Per-item extras ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getExtras(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('extras_$itemId');
    if (raw == null) return {};
    return Map<String, dynamic>.from(json.decode(raw) as Map);
  }

  static Future<void> saveExtras(
      String itemId, Map<String, dynamic> extras) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('extras_$itemId', json.encode(extras));
  }

  static Future<void> setExtra(String itemId, String key, dynamic value) async {
    final extras = await getExtras(itemId);
    extras[key] = value;
    await saveExtras(itemId, extras);
  }

  // ── User-created PN items ───────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getUserPnItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_pn_items');
    if (raw == null) return [];
    return (json.decode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> saveUserPnItems(
      List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pn_items', json.encode(items));
  }

  static Future<void> addUserPnItem(Map<String, dynamic> item) async {
    final list = await getUserPnItems();
    list.add(item);
    await saveUserPnItems(list);
  }

  static Future<void> deleteUserPnItem(String id) async {
    final list = await getUserPnItems();
    list.removeWhere((i) => i['id'] == id);
    await saveUserPnItems(list);
  }

  static Future<void> updateUserPnItem(Map<String, dynamic> updated) async {
    final list = await getUserPnItems();
    final idx = list.indexWhere((i) => i['id'] == updated['id']);
    if (idx != -1) list[idx] = updated;
    await saveUserPnItems(list);
  }
}
