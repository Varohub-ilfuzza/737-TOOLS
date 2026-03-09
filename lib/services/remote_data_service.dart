import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_cache.dart';

/// Servicio de actualización OTA (Over-The-Air) de datos.
///
/// Flujo al arrancar la app:
///   1. Descarga [_versionUrl] y compara con la versión guardada localmente.
///   2. Si la versión remota es mayor → descarga los tres JSON de datos.
///   3. Los guarda en el directorio de documentos del dispositivo.
///   4. Invalida DataCache para que la próxima consulta use los datos frescos.
///
/// La app nunca se bloquea: cualquier error de red se captura silenciosamente
/// y el usuario sigue viendo los datos en caché o los assets bundled.
class RemoteDataService {
  // ── URLs base (GitHub raw – rama main) ───────────────────────────────────
  static const _base =
      'https://raw.githubusercontent.com/Varohub-ilfuzza/737-TOOLS/main';

  static const _versionUrl = '$_base/assets/data_version.json';

  static const _remoteFiles = {
    'cb_data.json':  '$_base/assets/cb_data.json',
    'fim_data.json': '$_base/assets/fim_data.json',
    'pn_data.json':  '$_base/assets/pn_data.json',
  };

  static const _versionKey = 'ota_data_version';

  // ── Resultado del chequeo ─────────────────────────────────────────────────
  static bool _updateAvailable = false;
  static bool get lastCheckFoundUpdate => _updateAvailable;

  // ── API pública ───────────────────────────────────────────────────────────

  /// Comprueba si hay una versión nueva y descarga los datos si es necesario.
  /// Devuelve `true` si los datos fueron actualizados en esta llamada.
  /// Se llama desde main() sin await para no bloquear el arranque.
  static Future<bool> checkAndUpdate() async {
    try {
      final remoteVersion = await _fetchRemoteVersion();
      if (remoteVersion == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final localVersion = prefs.getInt(_versionKey) ?? 0;

      if (remoteVersion <= localVersion) {
        debugPrint('[OTA] Datos al día (v$localVersion).');
        return false;
      }

      debugPrint('[OTA] Nueva versión detectada: $remoteVersion > $localVersion. Descargando...');

      final updated = await _downloadAll();
      if (updated) {
        await prefs.setInt(_versionKey, remoteVersion);
        DataCache.instance.invalidateAll();
        _updateAvailable = true;
        debugPrint('[OTA] Datos actualizados a v$remoteVersion.');
      }
      return updated;
    } catch (e) {
      debugPrint('[OTA] Error (no crítico): $e');
      return false;
    }
  }

  /// Versión de datos actualmente almacenada en el dispositivo.
  static Future<int> localDataVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_versionKey) ?? 0;
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  static Future<int?> _fetchRemoteVersion() async {
    final body = await _get(_versionUrl);
    if (body == null) return null;
    final map = json.decode(body) as Map<String, dynamic>;
    return (map['version'] as num).toInt();
  }

  static Future<bool> _downloadAll() async {
    final dir = await getApplicationDocumentsDirectory();
    bool anyOk = false;

    for (final entry in _remoteFiles.entries) {
      final body = await _get(entry.value);
      if (body == null) continue;

      // Validar que es JSON antes de guardar
      try {
        json.decode(body);
      } catch (_) {
        debugPrint('[OTA] JSON inválido para ${entry.key}, ignorado.');
        continue;
      }

      final file = File('${dir.path}/${entry.key}');
      await file.writeAsString(body, flush: true);
      anyOk = true;
      debugPrint('[OTA] ${entry.key} guardado (${body.length} bytes).');
    }
    return anyOk;
  }

  /// GET con timeout de 10 s. Devuelve el body o null si falla.
  static Future<String?> _get(String url) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse(url));
      final resp = await req.close();
      if (resp.statusCode != 200) return null;
      return await resp.transform(const Utf8Decoder()).join();
    } catch (_) {
      return null;
    }
  }
}
