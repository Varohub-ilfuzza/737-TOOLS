import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DrawingTool { pen, arrow }

class AnnotationStroke {
  final DrawingTool tool;
  final int colorValue;
  final double strokeWidth;
  final List<Offset> points;

  const AnnotationStroke({
    required this.tool,
    required this.colorValue,
    required this.strokeWidth,
    required this.points,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'tool': tool.index,
        'color': colorValue,
        'sw': strokeWidth,
        'pts': points.map((p) => [p.dx, p.dy]).toList(),
      };

  factory AnnotationStroke.fromJson(Map<String, dynamic> j) {
    return AnnotationStroke(
      tool: DrawingTool.values[j['tool'] as int],
      colorValue: j['color'] as int,
      strokeWidth: (j['sw'] as num).toDouble(),
      points: (j['pts'] as List)
          .map((p) => Offset(
                (p[0] as num).toDouble(),
                (p[1] as num).toDouble(),
              ))
          .toList(),
    );
  }
}

class AnnotationsService {
  static const _prefix = 'annot_';

  static String _key(String schemaId, int page) =>
      '$_prefix${schemaId}_p$page';

  static Future<List<AnnotationStroke>> load(
      String schemaId, int page) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(schemaId, page));
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => AnnotationStroke.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(
      String schemaId, int page, List<AnnotationStroke> strokes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(schemaId, page),
      jsonEncode(strokes.map((s) => s.toJson()).toList()),
    );
  }

  static Future<void> clearPage(String schemaId, int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(schemaId, page));
  }

  static Future<void> clearAll(String schemaId, int totalPages) async {
    final prefs = await SharedPreferences.getInstance();
    for (int p = 1; p <= totalPages; p++) {
      await prefs.remove(_key(schemaId, p));
    }
  }
}
