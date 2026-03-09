import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Carga datos JSON con la siguiente prioridad:
///   1. Archivo descargado vía OTA en el directorio de documentos del dispositivo.
///   2. Asset bundled en el APK/IPA (fallback offline siempre disponible).
///
/// [assetPath] debe ser la ruta del asset bundled, p.ej. 'assets/cb_data.json'.
class DataService {
  static Future<List<Map<String, dynamic>>> loadJson(String assetPath) async {
    // 1 · Intenta el archivo OTA en disco
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filename = assetPath.split('/').last; // 'cb_data.json'
      final file = File('${dir.path}/$filename');
      if (await file.exists()) {
        final content = await file.readAsString();
        final list = json.decode(content) as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {
      // Si hay cualquier error leyendo el archivo OTA, caemos al bundled
    }

    // 2 · Fallback: asset bundled en el paquete
    final data = await rootBundle.loadString(assetPath);
    final list = json.decode(data) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }
}
