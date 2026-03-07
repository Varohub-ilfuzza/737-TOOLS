import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _prefix = 'fav_';

  static Future<Set<String>> load(String screen) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('$_prefix$screen') ?? []).toSet();
  }

  static Future<void> toggle(String screen, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$screen';
    final list = prefs.getStringList(key) ?? [];
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    await prefs.setStringList(key, list);
  }
}
