# B737 Tools

> Aplicación de referencia técnica para Técnicos de Mantenimiento de Aeronaves (TMA) en la flota Boeing 737.

[![Version](https://img.shields.io/badge/version-0.5.0--beta-blue)](./pubspec.yaml)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey)](https://flutter.dev/multi-platform)
[![License](https://img.shields.io/badge/license-Proprietary-red)](#licencia)

---

## Índice

- [Descripción](#descripción)
- [Características](#características)
- [Arquitectura](#arquitectura)
- [Pantallas](#pantallas)
- [Requisitos](#requisitos)
- [Instalación y ejecución](#instalación-y-ejecución)
- [Configuración de secretos](#configuración-de-secretos)
- [Actualización de datos OTA](#actualización-de-datos-ota)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Dependencias](#dependencias)
- [Changelog](#changelog)
- [Licencia](#licencia)

---

## Descripción

**B737 Tools** es una aplicación móvil offline-first diseñada para técnicos de mantenimiento de aeronaves que operan la flota Boeing 737. Centraliza la información técnica de referencia más consultada en línea de vuelo: disyuntores, manuales de aislamiento de fallos, números de parte, listas de revisión y esquemas técnicos.

La app funciona **sin conexión a internet**. Las actualizaciones de base de datos se descargan silenciosamente en segundo plano cuando hay conectividad disponible.

> **Aviso:** Esta aplicación es únicamente una herramienta de referencia. No sustituye la documentación oficial aprobada ni los procedimientos reglamentarios vigentes.

---

## Características

| Módulo | Descripción |
|--------|-------------|
| **Circuit Breakers** | Búsqueda de disyuntores por sistema, panel, grid y referencia AMM |
| **FIM / Fallos** | Manual de aislamiento de fallos con acciones recomendadas |
| **Common PN** | Base de datos de números de parte + PNs personalizados del usuario |
| **Revisiones** | Listas Transit Check y Daily Check configurables |
| **Favoritos** | Marcadores persistentes cruzados entre todos los módulos |
| **Esquemas** | Visor PDF de esquemas técnicos con anotaciones persistentes |

**Funcionalidades transversales:**

- Búsqueda global cruzada entre módulos
- Anotaciones en PDF (lápiz + flechas) guardadas localmente
- Contribuciones de usuario enviadas a Telegram y Google Sheets
- OTA: actualización silenciosa de datos desde GitHub
- Modo oscuro siguiendo la preferencia del sistema

---

## Arquitectura

```
┌──────────────────────────────────────────────┐
│                  UI Layer                    │
│        screens/  ·  widgets/  ·  l10n/       │
└───────────────────┬──────────────────────────┘
                    │
┌───────────────────▼──────────────────────────┐
│               Services Layer                 │
│  DataService · DataCache · FavoritesService  │
│  SubmissionsService · SearchHistoryService   │
│  UserDataService · AnnotationsService        │
│  RemoteDataService · RemoteSubmissionService │
└───────────────────┬──────────────────────────┘
                    │
┌───────────────────▼──────────────────────────┐
│              Persistence Layer               │
│     SharedPreferences  ·  JSON assets        │
│     path_provider (caché OTA en disco)       │
└──────────────────────────────────────────────┘
```

**Principios clave:**

- **Offline-first:** funcionalidad completa sin red.
- **Singleton cache:** `DataCache` evita reparsear JSON en cada navegación.
- **OTA transparente:** `RemoteDataService` comprueba versiones al inicio sin bloquear UI.
- **Secretos externalizados:** tokens y URLs se inyectan en tiempo de compilación con `--dart-define`.

---

## Pantallas

```
DisclaimerScreen              → aceptación legal obligatoria al primer acceso
HomeScreen                    → hub principal (logo Boeing + 6 módulos)
  ├── CbSearchScreen          → buscador de circuit breakers
  ├── FimSearchScreen         → buscador de fallos FIM
  ├── CommonPnScreen          → números de parte comunes
  ├── RevisionsScreen         → listas de revisión (Transit / Daily)
  ├── FavoritesScreen         → favoritos unificados
  └── SchemasScreen           → índice de esquemas PDF por capítulo ATA
       └── SchemaViewerScreen → lector PDF con anotaciones
```

---

## Requisitos

| Requisito | Versión mínima |
|-----------|----------------|
| Flutter SDK | ≥ 3.0.0 |
| Dart SDK | ≥ 3.0.0 < 4.0.0 |
| iOS | ≥ 11.0 |
| Android | ≥ 5.0 (API 21) |

---

## Instalación y ejecución

```bash
# 1. Clonar el repositorio
git clone https://github.com/Varohub-ilfuzza/737-TOOLS.git
cd 737-TOOLS

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar en desarrollo (sin secretos — llamadas remotas fallan silenciosamente)
flutter run

# 4. Ejecutar con secretos completos
flutter run \
  --dart-define=TG_TOKEN=<telegram_bot_token> \
  --dart-define=TG_CHAT_ID=<telegram_chat_id> \
  --dart-define=SHEETS_URL=<google_apps_script_url>
```

### Build de producción

```bash
# Android
flutter build apk --release \
  --dart-define=TG_TOKEN=<token> \
  --dart-define=TG_CHAT_ID=<chat_id> \
  --dart-define=SHEETS_URL=<sheets_url>

# iOS
flutter build ipa --release \
  --dart-define=TG_TOKEN=<token> \
  --dart-define=TG_CHAT_ID=<chat_id> \
  --dart-define=SHEETS_URL=<sheets_url>
```

---

## Configuración de secretos

Los tokens y URLs sensibles no están en el código fuente. Se inyectan en tiempo de compilación a través de `lib/config/secrets.dart`:

```dart
abstract final class Secrets {
  static const tgToken   = String.fromEnvironment('TG_TOKEN');
  static const tgChatId  = String.fromEnvironment('TG_CHAT_ID');
  static const sheetsUrl = String.fromEnvironment('SHEETS_URL');
}
```

Crea un archivo `.env` (ignorado por `.gitignore`) basándote en `.env.example`:

```env
TG_TOKEN=<telegram_bot_token>
TG_CHAT_ID=<telegram_chat_id>
SHEETS_URL=<google_apps_script_url>
```

> **Nunca** subas el archivo `.env` ni valores reales de tokens al repositorio.

---

## Actualización de datos OTA

Los datos de referencia (CB, FIM, PN) se actualizan sin publicar una nueva versión de la app.

**Flujo:**

1. Al iniciar, `RemoteDataService` descarga `assets/data_version.json` desde GitHub.
2. Compara el campo `version` con el valor guardado en `SharedPreferences`.
3. Si la versión remota es mayor, descarga los JSON actualizados y los guarda en disco.
4. `DataService` prioriza los archivos del disco sobre los assets empaquetados.

**Para publicar una actualización de datos:**

1. Modifica los archivos JSON en `assets/`.
2. Incrementa `version` y actualiza `updated` en `assets/data_version.json`.
3. Haz push — los dispositivos se actualizan solos en la siguiente sesión con conectividad.

```json
{
  "version": 2,
  "updated": "2026-03-09",
  "files": {
    "cb":  "assets/cb_data.json",
    "fim": "assets/fim_data.json",
    "pn":  "assets/pn_data.json"
  }
}
```

---

## Estructura del proyecto

```
737-TOOLS/
├── lib/
│   ├── main.dart
│   ├── config/
│   │   └── secrets.dart             # Secretos vía --dart-define
│   ├── screens/
│   │   ├── disclaimer_screen.dart
│   │   ├── home_screen.dart
│   │   ├── cb_search_screen.dart
│   │   ├── fim_search_screen.dart
│   │   ├── common_pn_screen.dart
│   │   ├── revisions_screen.dart
│   │   ├── favorites_screen.dart
│   │   ├── schemas_screen.dart
│   │   ├── schema_viewer_screen.dart
│   │   ├── item_detail_screen.dart
│   │   ├── contributions_screen.dart
│   │   └── global_search_delegate.dart
│   ├── services/
│   │   ├── data_service.dart
│   │   ├── data_cache.dart
│   │   ├── remote_data_service.dart
│   │   ├── remote_submission_service.dart
│   │   ├── favorites_service.dart
│   │   ├── submissions_service.dart
│   │   ├── search_history_service.dart
│   │   ├── user_data_service.dart
│   │   └── annotations_service.dart
│   ├── widgets/
│   │   ├── cb_item_card.dart
│   │   ├── pn_item_card.dart
│   │   ├── searchable_list.dart
│   │   ├── report_sheet.dart
│   │   ├── drawing_canvas.dart
│   │   └── app_bar_actions.dart
│   ├── models/
│   │   └── schema_item.dart
│   ├── data/
│   │   └── schemas_registry.dart
│   └── l10n/
│       └── app_strings.dart         # Strings UI en español
├── assets/
│   ├── cb_data.json
│   ├── fim_data.json
│   ├── pn_data.json
│   ├── data_version.json
│   └── schemas/                     # PDFs técnicos (no versionados en git)
├── .env.example
├── .gitignore
└── pubspec.yaml
```

---

## Dependencias

| Paquete | Versión | Uso |
|---------|---------|-----|
| `shared_preferences` | ^2.2.2 | Persistencia local (favoritos, caché, anotaciones) |
| `path_provider` | ^2.1.2 | Acceso a directorios del dispositivo para caché OTA |
| `image_picker` | ^1.1.2 | Adjuntar fotos a entradas de Common PN |
| `share_plus` | ^7.2.2 | Exportación CSV nativa del SO |
| `pdfx` | ^2.6.0 | Renderizado y visualización de PDFs |

---

## Changelog

### v0.5.0 — 2026-03-09
- Nueva `HomeScreen`: logo Boeing en blanco sobre fondo azul, subtítulo `Tools / AMT`
- Footer en HomeScreen con versión de app, fecha de actualización de BD y créditos
- Tokens y URLs sensibles externalizados con `--dart-define` (eliminados del código fuente)
- Nuevo módulo `lib/config/secrets.dart` con `String.fromEnvironment`
- Navegación post-disclaimer redirige a `HomeScreen`

### v0.4.x
- Sistema OTA de actualización de datos desde GitHub
- Visor PDF con anotaciones persistentes (lápiz + flechas con undo/clear)
- Módulo de esquemas técnicos organizados por capítulo ATA

### v0.3.x
- Módulo de contribuciones: envío a Telegram y Google Sheets
- Favoritos cruzados entre módulos (CB, FIM, PN)
- Búsqueda global entre módulos

### v0.2.x
- Módulo de revisiones: Transit Check y Daily Check configurables
- Common PN con imágenes adjuntas y PNs personalizados de usuario

### v0.1.x
- Versión inicial: módulos Circuit Breakers y FIM

---

## Licencia

© 2026 **Varo · Varohub-ilfuzza** — Todos los derechos reservados.

Software de uso interno. Queda prohibida su reproducción, distribución o modificación total o parcial sin autorización expresa por escrito del titular de los derechos.
