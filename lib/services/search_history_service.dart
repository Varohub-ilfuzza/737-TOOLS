import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const _prefix = 'hist_';
  static const _max = 5;

  static Future<List<String>> load(String screen) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('$_prefix$screen') ?? [];
  }

  static Future<void> add(String screen, String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$screen';
    final list = prefs.getStringList(key) ?? [];
    list.remove(query); // avoid duplicates
    list.insert(0, query);
    if (list.length > _max) list.removeLast();
    await prefs.setStringList(key, list);
  }
}
