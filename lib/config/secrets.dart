/// Valores sensibles inyectados en tiempo de compilación.
///
/// Nunca codifiques tokens directamente en el código fuente.
/// Pásalos al compilar con --dart-define o un archivo .env:
///
///   flutter run \
///     --dart-define=TG_TOKEN=<tu_token> \
///     --dart-define=TG_CHAT_ID=<tu_chat_id> \
///     --dart-define=SHEETS_URL=<tu_url>
///
/// Para Android Studio / VS Code, añade los dart-define en la
/// configuración de ejecución (Run > Edit Configurations).
abstract final class Secrets {
  static const tgToken = String.fromEnvironment('TG_TOKEN');
  static const tgChatId = String.fromEnvironment('TG_CHAT_ID');
  static const sheetsUrl = String.fromEnvironment('SHEETS_URL');
}
