import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/secrets.dart';

/// Envía cada contribución de usuario a:
///   · Telegram  — notificación instantánea al autor vía bot.
///   · Google Sheets — fila nueva en la hoja de registro del autor.
///
/// Ambos envíos son fire-and-forget: nunca bloquean la UI ni
/// lanzan excepciones al resto de la app aunque fallen.
///
/// Los tokens se inyectan en tiempo de compilación con --dart-define.
/// Ver lib/config/secrets.dart para instrucciones.
class RemoteSubmissionService {
  // ── Configuración (inyectada en build, no en código fuente) ───────────────
  static String get _tgUrl =>
      'https://api.telegram.org/bot${Secrets.tgToken}/sendMessage';

  // ── API pública ──────────────────────────────────────────────────────────

  /// Dispara los dos envíos en paralelo.
  /// No lanza excepción — cualquier fallo de red es silencioso.
  static Future<void> send({
    required String section,
    required String itemRef,
    required String type,
    required String description,
    required String date,
  }) async {
    final payload = _Payload(
      section: section,
      itemRef: itemRef,
      type: type,
      description: description,
      date: date,
      platform: _platform(),
    );

    await Future.wait([
      _sendTelegram(payload),
      _sendSheets(payload),
    ]);
  }

  // ── Telegram ─────────────────────────────────────────────────────────────

  static Future<void> _sendTelegram(_Payload p) async {
    try {
      final dateShort = p.date.length >= 16
          ? p.date.substring(0, 16).replaceAll('T', ' ')
          : p.date;

      final text =
          '📋 *Nueva Contribución — B737 Tools*\n\n'
          '📌 *Sección:* ${_esc(p.section)}\n'
          '🔗 *Referencia:* ${_esc(p.itemRef)}\n'
          '🔖 *Tipo:* ${_esc(p.type)}\n'
          '📝 *Descripción:*\n${_esc(p.description)}\n\n'
          '📱 ${p.platform}  ·  🕐 $dateShort';

      await _post(
        _tgUrl,
        json.encode({
          'chat_id': Secrets.tgChatId,
          'text': text,
          'parse_mode': 'Markdown',
        }),
      );
    } catch (e) {
      debugPrint('[RemoteSubmission] Telegram: $e');
    }
  }

  // ── Google Sheets ─────────────────────────────────────────────────────────

  static Future<void> _sendSheets(_Payload p) async {
    try {
      await _post(
        Secrets.sheetsUrl,
        json.encode({
          'type':        p.type,
          'ref':         p.itemRef,
          'description': p.description,
          'source':      p.section,
          'device':      p.platform,
        }),
      );
    } catch (e) {
      debugPrint('[RemoteSubmission] Sheets: $e');
    }
  }

  // ── HTTP helper ──────────────────────────────────────────────────────────

  static Future<void> _post(String url, String body) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);

    // Google Apps Script redirige a una URL final; seguimos el redirect
    client.autoUncompress = true;

    final req = await client.postUrl(Uri.parse(url));
    req.headers
      ..set(HttpHeaders.contentTypeHeader, 'application/json')
      ..set(HttpHeaders.contentLengthHeader, utf8.encode(body).length);
    req.write(body);
    final resp = await req.close();
    await resp.drain<void>(); // consume la respuesta para liberar el socket
    debugPrint('[RemoteSubmission] POST $url → ${resp.statusCode}');
  }

  // ── Utilities ────────────────────────────────────────────────────────────

  /// Escapa caracteres especiales de Markdown de Telegram.
  static String _esc(String s) =>
      s.replaceAll('_', '\\_').replaceAll('*', '\\*').replaceAll('`', '\\`');

  static String _platform() {
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return 'Unknown';
  }
}

class _Payload {
  final String section;
  final String itemRef;
  final String type;
  final String description;
  final String date;
  final String platform;

  const _Payload({
    required this.section,
    required this.itemRef,
    required this.type,
    required this.description,
    required this.date,
    required this.platform,
  });
}
