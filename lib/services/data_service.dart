import 'dart:convert';
import 'package:flutter/services.dart';

class DataService {
  static Future<List<Map<String, dynamic>>> loadJson(String assetPath) async {
    final data = await rootBundle.loadString(assetPath);
    final list = json.decode(data) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }
}
