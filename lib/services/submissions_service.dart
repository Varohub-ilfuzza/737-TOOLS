import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tipos de reporte que un usuario puede enviar.
enum ReportType {
  correction('Corrección de dato'),
  additionalInfo('Información adicional'),
  newSuggestion('Nueva sugerencia'),
  possibleError('Posible error');

  const ReportType(this.label);
  final String label;
}

class SubmissionsService {
  static const _key = 'user_submissions';

  // ── CRUD ──────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (json.decode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> add({
    required String itemId,
    required String itemRef, // e.g. "CB: APU ECU" | "FIM: PSEU LIGHT" | "PN: J221P014"
    required String section, // 'CB', 'FIM', 'PN'
    required ReportType type,
    required String description,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAll();
    list.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'itemId': itemId,
      'itemRef': itemRef,
      'section': section,
      'type': type.label,
      'description': description,
      'date': DateTime.now().toIso8601String(),
      'status': 'pending',
    });
    await prefs.setString(_key, json.encode(list));
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAll();
    list.removeWhere((s) => s['id'] == id);
    await prefs.setString(_key, json.encode(list));
  }

  // ── Export ────────────────────────────────────────────────────────────────

  /// Prepends a single-quote to neutralise CSV formula triggers (=, +, -, @).
  static String _csvSafe(String v) {
    final s = v.replaceAll('"', "'");
    if (s.isNotEmpty && '=+-@'.contains(s[0])) return "'$s";
    return s;
  }

  /// Generates a UTF-8 CSV file in the temp directory and returns its path.
  static Future<String> exportToCsvFile() async {
    final list = await getAll();
    final sb = StringBuffer();
    sb.writeln('Fecha,Sección,Referencia,Tipo,Descripción,Estado');
    for (final s in list) {
      final date = (s['date'] ?? '').toString().replaceAll(',', '-');
      final section = s['section'] ?? '';
      final ref = _csvSafe((s['itemRef'] ?? '').toString().replaceAll('\n', ' '));
      final type = _csvSafe((s['type'] ?? '').toString());
      final desc = _csvSafe((s['description'] ?? '').toString().replaceAll('\n', ' '));
      final status = s['status'] ?? 'pending';
      sb.writeln('$date,$section,"$ref","$type","$desc",$status');
    }

    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/b737_contribuciones_$ts.csv');
    // BOM for Excel UTF-8 compatibility
    await file.writeAsBytes([0xEF, 0xBB, 0xBF]);
    await file.writeAsString(sb.toString(), mode: FileMode.append);
    return file.path;
  }

  static int pending(List<Map<String, dynamic>> list) =>
      list.where((s) => s['status'] == 'pending').length;
}
