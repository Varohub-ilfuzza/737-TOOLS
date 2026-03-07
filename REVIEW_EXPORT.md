<!--
  ╔══════════════════════════════════════════════════════════════╗
  ║  B737 TOOLS — REVIEW EXPORT                                  ║
  ║  Paste this entire file as your first message in a new chat  ║
  ║  to give the assistant full context to continue development  ║
  ╚══════════════════════════════════════════════════════════════╝
-->

# B737 Tools — Flutter App · Context Document

## Purpose of this document
This file contains the **complete, reviewed, and corrected source code** for the
*B737 Tools* Flutter app, plus a security & bug audit report. Paste it into a new
chat session to bootstrap continued development.

---

## 1. App Overview

| Field | Value |
|-------|-------|
| **Name** | B737 Tools |
| **Target users** | Aircraft Maintenance Technicians (TMAs) working on Boeing 737 |
| **Platform** | Flutter (iOS + Android) |
| **Flutter SDK** | ≥ 3.0.0 |
| **Language** | Dart |
| **State management** | Plain `StatefulWidget` + `SharedPreferences` |
| **Data persistence** | `shared_preferences` (local only, no network) |
| **Network calls** | **Zero** — fully offline |

### Dependencies (`pubspec.yaml`)
```
shared_preferences: ^2.2.2   # key-value local storage
image_picker: ^1.1.2          # pick photos from gallery
share_plus: ^7.2.2            # export CSV via OS share sheet
path_provider: ^2.1.2         # temp directory for CSV export
```

### Modules / Screens
| Tab | Screen | Description |
|-----|--------|-------------|
| Breakers | `CbSearchScreen` | Searchable list of B737 circuit breakers with panel/grid/AMM reference |
| FIM / Fallos | `FimSearchScreen` | Fault Isolation Manual quick-lookup |
| Common PN | `CommonPnScreen` | Part number reference; user can add custom PNs |
| Revisiones | `RevisionsScreen` | Transit & Daily check checklists with undo-on-swipe |

### Supporting screens
- `DisclaimerScreen` — shown on every launch (safety notice)
- `ItemDetailScreen` — full-screen detail for CB / FIM / PN items
- `ContributionsScreen` — list & CSV-export of user-submitted reports
- `GlobalSearchDelegate` — cross-module search (CB + FIM + PN in one query)

---

## 2. File Tree

```
b737_tools/
├── pubspec.yaml
├── assets/
│   ├── cb_data.json
│   ├── fim_data.json
│   └── pn_data.json
└── lib/
    ├── main.dart
    ├── l10n/
    │   └── app_strings.dart
    ├── services/
    │   ├── data_service.dart
    │   ├── data_cache.dart
    │   ├── user_data_service.dart
    │   ├── favorites_service.dart
    │   ├── search_history_service.dart
    │   └── submissions_service.dart
    ├── widgets/
    │   ├── searchable_list.dart
    │   ├── cb_item_card.dart
    │   ├── pn_item_card.dart
    │   ├── report_sheet.dart
    │   └── app_bar_actions.dart
    └── screens/
        ├── disclaimer_screen.dart
        ├── main_navigation_screen.dart
        ├── cb_search_screen.dart
        ├── fim_search_screen.dart
        ├── common_pn_screen.dart
        ├── revisions_screen.dart
        ├── global_search_delegate.dart
        ├── item_detail_screen.dart
        └── contributions_screen.dart
```

---

## 3. Security Review

### SEC-1 — CSV Formula Injection · **Medium**
**File:** `lib/services/submissions_service.dart` · `exportToCsvFile()`

`description` and `itemRef` are double-quoted but not sanitised against spreadsheet
formula triggers (`=`, `+`, `-`, `@` at the start of a value). If a user enters
`=HYPERLINK("http://evil.com","Click")` as a contribution description, Excel / Google
Sheets will execute it when the CSV is opened.

**Status:** Not yet fixed. Recommended fix for next iteration:
```dart
/// Prepend a single-quote to neutralise formula triggers in CSV cells.
String _csvSafe(String v) {
  final s = v.replaceAll('"', "'");
  if (s.isNotEmpty && '=+-@'.contains(s[0])) return "'$s";
  return s;
}
```
Apply `_csvSafe()` to `ref`, `type`, and `desc` before writing each row.

---

### SEC-2 — No Input Length Limits · **Low**
**Files:** `lib/screens/common_pn_screen.dart`, `lib/widgets/report_sheet.dart`

User-created PN text fields and contribution description fields have no `maxLength`
constraint. A user can store arbitrarily long strings in SharedPreferences.

**Recommended fix:**
```dart
// In common_pn_screen.dart form fields:
TextFormField(controller: descCtrl, maxLength: 200, ...)
TextFormField(controller: pnCtrl,   maxLength: 30,  ...)
TextFormField(controller: ataCtrl,  maxLength: 10,  ...)

// In report_sheet.dart:
TextFormField(controller: descCtrl, maxLength: 1000, ...)
```

---

### SEC-3 — Unvalidated Image Path from SharedPreferences · **Informational**
**Files:** `cb_item_card.dart`, `pn_item_card.dart`, `item_detail_screen.dart`

`_imagePath` is stored in SharedPreferences and later passed to `Image.file()`.
On a rooted device another app could overwrite the preference file and redirect the
path to an arbitrary location. In practice the `errorBuilder` handles broken/missing
paths gracefully. No code change required; noted for awareness.

---

### SEC-4 — Zero Network Exposure · **Positive finding**
The app contains no HTTP clients, no remote endpoints, no API keys, and no
credentials. All data stays on-device. `share_plus` only acts on explicit user action.

---

## 4. Bug Log

| # | Severity | File | Description | Status |
|---|----------|------|-------------|--------|
| 1 | Medium | `widgets/report_sheet.dart` | `ScaffoldMessenger.of(context)` called after `await` using the **outer** context without a `mounted` guard — could throw if caller screen was popped during submission | **Fixed** |
| 2 | Minor | `screens/revisions_screen.dart` | Stale `index` captured in Dismissible undo closure — `tasks.insert(index, task)` could insert at wrong position if another task was dismissed first | **Fixed** |
| 3 | Minor | `screens/contributions_screen.dart` | `Color.withOpacity()` deprecated since Flutter 3.27 — produces lint warning | **Fixed** |
| 4 | Minor | `screens/cb_search_screen.dart` | Unused import `global_search_delegate.dart` — lint warning | **Fixed** |
| 5 | Minor | `screens/fim_search_screen.dart` | Same unused import | **Fixed** |
| 6 | Minor | `screens/common_pn_screen.dart` | Same unused import | **Fixed** |
| 7 | Minor | `screens/revisions_screen.dart` | Same unused import | **Fixed** |
| SEC-1 | Medium | `services/submissions_service.dart` | CSV formula injection via unescaped leading `=`/`+`/`-`/`@` in user text | **Open — recommended above** |
| SEC-2 | Low | `common_pn_screen.dart`, `report_sheet.dart` | No `maxLength` on text fields | **Open — recommended above** |

---

## 5. Complete Corrected Source Code

All files below reflect the state **after all bug fixes** listed in the table above.


---

### `pubspec.yaml`
```yaml
name: b737_tools
description: B737 Maintenance Tools Reference App for TMAs.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2
  image_picker: ^1.1.2
  share_plus: ^7.2.2
  path_provider: ^2.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/cb_data.json
    - assets/fim_data.json
    - assets/pn_data.json
```

---

### `assets/cb_data.json`
```json
[
  {"id": "cb_1", "system": "APU ECU", "panel": "P6-3", "grid": "C14", "amm": "AMM 28-22-00"},
  {"id": "cb_2", "system": "Standby Power", "panel": "P6-1", "grid": "D10", "amm": "AMM 24-20-00"},
  {"id": "cb_3", "system": "FMC Left", "panel": "P18-2", "grid": "E5", "amm": "AMM 34-61-00"},
  {"id": "cb_4", "system": "Fuel Pump L FWD", "panel": "P6-4", "grid": "B2", "amm": "AMM 28-21-00"}
]
```

### `assets/fim_data.json`
```json
[
  {"id": "fim_1", "fault": "21-21134", "desc": "Pack 1 Temp Control Fault", "fix": "Revisar sensor de ram air door"},
  {"id": "fim_2", "fault": "PSEU LIGHT", "desc": "Proximity Switch Electronic Unit", "fix": "Hacer BITE test en panel trasero"},
  {"id": "fim_3", "fault": "APU FAULT", "desc": "APU Auto Shutdown", "fix": "Revisar nivel de aceite antes de reset"}
]
```

### `assets/pn_data.json`
```json
[
  {"id": "pn_1", "desc": "Engine Oil O-Ring", "pn": "J221P014", "ata": "79", "qty": "2 (1 per engine)", "image": "assets/oring.jpg", "verified": true},
  {"id": "pn_2", "desc": "Nav Light Bulb (Wingtip)", "pn": "6832", "ata": "33", "qty": "2", "image": "assets/bulb.jpg", "verified": true},
  {"id": "pn_3", "desc": "MLG Tire", "pn": "200-247-XX", "ata": "32", "qty": "4", "image": "assets/tire.jpg", "verified": true}
]
```

---

### `lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'l10n/app_strings.dart';
import 'screens/disclaimer_screen.dart';

void main() {
  runApp(const B737ToolsApp());
}

class B737ToolsApp extends StatelessWidget {
  const B737ToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      // DARK MODE: follows the OS setting automatically
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0033A0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0033A0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DisclaimerScreen(),
    );
  }
}
```

---

### `lib/l10n/app_strings.dart`
```dart
class AppStrings {
  // App
  static const appTitle = 'B737 Tools';

  // Disclaimer
  static const disclaimerTitle = 'Aviso Importante';
  static const disclaimerBody =
      'Esta aplicación es una guía de referencia rápida no oficial diseñada por y para TMAs.\n\n'
      'Bajo ninguna circunstancia sustituye a los manuales aprobados (AMM, FIM, IPC, WDM, etc.). '
      'Consulte siempre la documentación oficial y actualizada de su aerolínea.';
  static const disclaimerButton = 'ACEPTO Y COMPRENDO';

  // Bottom nav
  static const navBreakers = 'Breakers';
  static const navFim = 'FIM / Fallos';
  static const navCommonPn = 'Common PN';
  static const navRevisiones = 'Revisiones';

  // CB screen
  static const cbTitle = 'Circuit Breakers';
  static const cbSearchHint = 'Buscar sistema (ej. APU)';

  // FIM screen
  static const fimTitle = 'Buscador FIM';
  static const fimSearchHint = 'Buscar fallo o código (ej. PSEU)';
  static const fimAccion = 'Acción TMA';

  // Common PN screen
  static const pnTitle = 'Common PNs';
  static const pnSearchHint = 'Buscar por Nombre, PN o ATA';
  static const pnQty = 'Cantidad en avión';
  static const pnImagePlaceholder = 'Espacio para fotografía';
  static const pnAddNew = 'Nuevo PN';
  static const pnAddTitle = 'Añadir Part Number';
  static const pnFieldDesc = 'Descripción *';
  static const pnFieldPn = 'Número de PN *';
  static const pnFieldAta = 'Código ATA *';
  static const pnFieldQty = 'Cantidad en avión';
  static const pnUserBadge = 'USER';
  static const pnDelete = 'Eliminar PN';
  static const pnDeleteConfirm = '¿Eliminar este PN añadido por ti?';

  // Revisions screen
  static const revisionsTitle = 'Revisiones B737';
  static const revisionsTransit = 'TRANSIT CHECK';
  static const revisionsDaily = 'DAILY CHECK';
  static const revisionsResetTooltip = 'Resetear Checklist';
  static const revisionsResetMsg = 'Checklist reseteada para el siguiente avión.';
  static const revisionsAddTask = 'Añadir nueva tarea';
  static const revisionsTaskHint = 'Ej. Revisar luces NAV';
  static const revisionsCancel = 'Cancelar';
  static const revisionsAdd = 'Añadir';
  static const revisionsDailyPlaceholder = 'Lista de Daily Check\n(Añade tus tareas aquí)';
  static const revisionsDeletedMsg = 'Tarea eliminada';
  static const revisionsSwipeHint = 'Desliza para eliminar';

  // Item detail (shared)
  static const detailNotes = 'Notas / Observaciones';
  static const detailAddPhoto = 'Toca para añadir foto';
  static const detailChangePhoto = 'Toca para cambiar foto';
  static const detailPhoto = 'Foto';
  static const detailSaved = 'Guardado';

  // Global search
  static const searchGlobal = 'Búsqueda global';
  static const searchHint = 'Buscar en CB, FIM y PN…';
  static const searchEmpty = 'Escribe para buscar en todos los módulos';
  static const searchNoResults = 'Sin resultados';

  // Search & favorites
  static const favoritesFilter = 'Solo favoritos';
  static const searchHistoryLabel = 'Búsquedas recientes';
  static const noResults = 'Sin resultados';
  static const noFavorites = 'No hay favoritos guardados';

  // Verification badges
  static const verifiedBadge = 'Verificado';
  static const verifiedTooltip = 'Información verificada por el equipo';
  static const unverifiedBadge = 'No verificado';
  static const unverifiedTooltip =
      'Aportado por un usuario — pendiente de verificación oficial';

  // Report / contribute
  static const reportTitle = 'Reportar / Contribuir';
  static const reportType = 'Tipo de aportación';
  static const reportDescription = 'Descripción *';
  static const reportHint = 'Describe la corrección, información adicional o error encontrado…';
  static const reportRequired = 'La descripción es obligatoria';
  static const reportSubmit = 'Enviar contribución';
  static const reportSent = 'Contribución guardada. ¡Gracias!';
  static const reportTooltip = 'Reportar / Contribuir';

  // Contributions screen
  static const contributionsTitle = 'Contribuciones';
  static const contributionsExport = 'Exportar CSV';
  static const contributionsEmpty = 'No hay contribuciones enviadas aún.';
  static const contributionsMenuLabel = 'Ver contribuciones';

  // General
  static const loading = 'Cargando...';
  static const cancel = 'Cancelar';
  static const save = 'Guardar';
  static const delete = 'Eliminar';
  static const confirm = 'Confirmar';
}
```

---

### `lib/services/data_service.dart`
```dart
import 'dart:convert';
import 'package:flutter/services.dart';

class DataService {
  static Future<List<Map<String, dynamic>>> loadJson(String assetPath) async {
    final data = await rootBundle.loadString(assetPath);
    final list = json.decode(data) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }
}
```

---

### `lib/services/user_data_service.dart`
```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists user-generated content:
///  - Per-item extras (notes, imagePath) keyed by item ID
///  - User-created PN items
class UserDataService {
  // ── Per-item extras ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getExtras(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('extras_$itemId');
    if (raw == null) return {};
    return Map<String, dynamic>.from(json.decode(raw) as Map);
  }

  static Future<void> saveExtras(
      String itemId, Map<String, dynamic> extras) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('extras_$itemId', json.encode(extras));
  }

  static Future<void> setExtra(String itemId, String key, dynamic value) async {
    final extras = await getExtras(itemId);
    extras[key] = value;
    await saveExtras(itemId, extras);
  }

  // ── User-created PN items ───────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getUserPnItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_pn_items');
    if (raw == null) return [];
    return (json.decode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> saveUserPnItems(
      List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pn_items', json.encode(items));
  }

  static Future<void> addUserPnItem(Map<String, dynamic> item) async {
    final list = await getUserPnItems();
    list.add(item);
    await saveUserPnItems(list);
  }

  static Future<void> deleteUserPnItem(String id) async {
    final list = await getUserPnItems();
    list.removeWhere((i) => i['id'] == id);
    await saveUserPnItems(list);
  }

  static Future<void> updateUserPnItem(Map<String, dynamic> updated) async {
    final list = await getUserPnItems();
    final idx = list.indexWhere((i) => i['id'] == updated['id']);
    if (idx != -1) list[idx] = updated;
    await saveUserPnItems(list);
  }
}
```

---

### `lib/services/data_cache.dart`
```dart
import 'data_service.dart';
import 'user_data_service.dart';

/// In-memory cache so JSON assets are only parsed once per session.
/// Call invalidate*() after user mutates data.
class DataCache {
  static final DataCache instance = DataCache._();
  DataCache._();

  List<Map<String, dynamic>>? _cbItems;
  List<Map<String, dynamic>>? _fimItems;
  List<Map<String, dynamic>>? _pnItems; // base + user

  Future<List<Map<String, dynamic>>> getCbItems() async {
    _cbItems ??= await DataService.loadJson('assets/cb_data.json');
    return _cbItems!;
  }

  Future<List<Map<String, dynamic>>> getFimItems() async {
    _fimItems ??= await DataService.loadJson('assets/fim_data.json');
    return _fimItems!;
  }

  Future<List<Map<String, dynamic>>> getAllPnItems() async {
    if (_pnItems == null) {
      final base = await DataService.loadJson('assets/pn_data.json');
      final user = await UserDataService.getUserPnItems();
      _pnItems = [...base, ...user];
    }
    return _pnItems!;
  }

  void invalidatePn() => _pnItems = null;
}
```

---

### `lib/services/favorites_service.dart`
```dart
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
```

---

### `lib/services/search_history_service.dart`
```dart
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
```

---

### `lib/services/submissions_service.dart`
```dart
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
    required String itemRef,
    required String section,
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

  /// Generates a UTF-8 CSV file in the temp directory and returns its path.
  /// TODO (SEC-1): Apply _csvSafe() to ref, type, desc to prevent formula injection.
  static Future<String> exportToCsvFile() async {
    final list = await getAll();
    final sb = StringBuffer();
    sb.writeln('Fecha,Sección,Referencia,Tipo,Descripción,Estado');
    for (final s in list) {
      final date = (s['date'] ?? '').toString().replaceAll(',', '-');
      final section = s['section'] ?? '';
      final ref = (s['itemRef'] ?? '').toString().replaceAll('"', "'");
      final type = s['type'] ?? '';
      final desc =
          (s['description'] ?? '').toString().replaceAll('"', "'").replaceAll('\n', ' ');
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
```

---

### `lib/widgets/searchable_list.dart`
```dart
import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../services/search_history_service.dart';
import '../l10n/app_strings.dart';

/// Generic search list with integrated favorites and search history.
/// Each item in [items] must have an 'id' String field.
class SearchableList extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  /// Map keys used for filtering (e.g. ['system'] or ['fault', 'desc'])
  final List<String> searchKeys;

  /// Builder for each list item. Receives the item, favorite state,
  /// and a callback to toggle the favorite.
  final Widget Function(
    BuildContext context,
    Map<String, dynamic> item,
    bool isFavorite,
    VoidCallback onToggleFavorite,
  ) itemBuilder;

  final String searchLabel;

  /// Unique identifier for this screen's favorites & history in SharedPreferences
  final String screenId;

  const SearchableList({
    super.key,
    required this.items,
    required this.searchKeys,
    required this.itemBuilder,
    required this.searchLabel,
    required this.screenId,
  });

  @override
  State<SearchableList> createState() => _SearchableListState();
}

class _SearchableListState extends State<SearchableList> {
  List<Map<String, dynamic>> _filtered = [];
  Set<String> _favorites = {};
  List<String> _history = [];
  bool _onlyFavorites = false;
  bool _showHistory = false;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _filtered = List.from(widget.items);
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    _init();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final favs = await FavoritesService.load(widget.screenId);
    final hist = await SearchHistoryService.load(widget.screenId);
    if (mounted) {
      setState(() {
        _favorites = favs;
        _history = hist;
      });
    }
  }

  void _onTextChanged() {
    _applyFilter(_controller.text);
    _updateHistoryVisibility();
  }

  void _onFocusChanged() {
    _updateHistoryVisibility();
  }

  void _updateHistoryVisibility() {
    if (mounted) {
      setState(() {
        _showHistory =
            _focusNode.hasFocus &&
            _controller.text.isEmpty &&
            _history.isNotEmpty;
      });
    }
  }

  void _applyFilter(String keyword) {
    if (!mounted) return;
    setState(() {
      if (keyword.isEmpty) {
        _filtered = _onlyFavorites
            ? widget.items
                .where((i) => _favorites.contains((i['id'] ?? '').toString()))
                .toList()
            : List.from(widget.items);
      } else {
        _filtered = widget.items.where((i) {
          final matchSearch = widget.searchKeys.any(
            (k) => (i[k] ?? '')
                .toString()
                .toLowerCase()
                .contains(keyword.toLowerCase()),
          );
          final matchFav =
              !_onlyFavorites ||
              _favorites.contains((i['id'] ?? '').toString());
          return matchSearch && matchFav;
        }).toList();
      }
    });

    if (keyword.isNotEmpty) {
      SearchHistoryService.add(widget.screenId, keyword).then((_) async {
        final hist = await SearchHistoryService.load(widget.screenId);
        if (mounted) setState(() => _history = hist);
      });
    }
  }

  void _selectFromHistory(String term) {
    _controller.text = term;
    _controller.selection =
        TextSelection.fromPosition(TextPosition(offset: term.length));
    _applyFilter(term);
    _focusNode.unfocus();
  }

  Future<void> _toggleFavorite(String id) async {
    await FavoritesService.toggle(widget.screenId, id);
    final favs = await FavoritesService.load(widget.screenId);
    if (mounted) {
      setState(() => _favorites = favs);
      if (_onlyFavorites) _applyFilter(_controller.text);
    }
  }

  void _toggleFavoritesFilter() {
    setState(() => _onlyFavorites = !_onlyFavorites);
    _applyFilter(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search field ──────────────────────────────────────────────
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.searchLabel,
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Borrar',
                    onPressed: () {
                      _controller.clear();
                      _applyFilter('');
                    },
                  ),
                IconButton(
                  icon: Icon(
                    _onlyFavorites ? Icons.star : Icons.star_outline,
                    color: _onlyFavorites ? Colors.amber : null,
                  ),
                  tooltip: AppStrings.favoritesFilter,
                  onPressed: _toggleFavoritesFilter,
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.search),
                ),
              ],
            ),
          ),
        ),

        // ── Search history ────────────────────────────────────────────
        if (_showHistory)
          Card(
            margin: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    AppStrings.searchHistoryLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ..._history.map(
                  (term) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.history, size: 18),
                    title: Text(term),
                    onTap: () => _selectFromHistory(term),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 10),

        // ── List ──────────────────────────────────────────────────────
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(
                    _onlyFavorites
                        ? AppStrings.noFavorites
                        : AppStrings.noResults,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (ctx, i) {
                    final item = _filtered[i];
                    final id = (item['id'] ?? '').toString();
                    final isFav = _favorites.contains(id);
                    return widget.itemBuilder(
                      ctx,
                      item,
                      isFav,
                      () => _toggleFavorite(id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
```

---

### `lib/widgets/cb_item_card.dart`
```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_strings.dart';
import '../services/user_data_service.dart';
import 'report_sheet.dart';

class CbItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const CbItemCard({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  State<CbItemCard> createState() => _CbItemCardState();
}

class _CbItemCardState extends State<CbItemCard> {
  String? _imagePath;
  late TextEditingController _notesCtrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController();
    _loadExtras();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExtras() async {
    final extras = await UserDataService.getExtras(widget.item['id'] as String);
    if (mounted) {
      setState(() {
        _imagePath = extras['imagePath'] as String?;
        _notesCtrl.text = extras['notes'] as String? ?? '';
      });
    }
  }

  void _onNotesChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      UserDataService.setExtra(widget.item['id'] as String, 'notes', value);
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      await UserDataService.setExtra(
          widget.item['id'] as String, 'imagePath', picked.path);
      if (mounted) setState(() => _imagePath = picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.bolt, color: Colors.blueGrey),
        title: Text(
          item['system'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Panel: ${item['panel']} | Grid: ${item['grid']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                widget.isFavorite ? Icons.star : Icons.star_outline,
                color: widget.isFavorite ? Colors.amber : null,
              ),
              onPressed: widget.onToggleFavorite,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.book, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 6),
                    Text(
                      item['amm'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const Divider(height: 20),
                GestureDetector(
                  onTap: _pickImage,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _imagePath != null
                        ? Image.file(
                            File(_imagePath!),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _photoPlaceholder(context, hasPhoto: false),
                          )
                        : _photoPlaceholder(context, hasPhoto: false),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.detailNotes,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.edit_note),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  onChanged: _onNotesChanged,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.rate_review_outlined, size: 16),
                  label: const Text(AppStrings.reportTitle,
                      style: TextStyle(fontSize: 12)),
                  onPressed: () => ReportSheet.show(
                    context,
                    itemId: widget.item['id'] as String,
                    itemRef: 'CB: ${widget.item['system']} (${widget.item['panel']})',
                    section: 'CB',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder(BuildContext context, {required bool hasPhoto}) {
    return Container(
      height: 150,
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.detailAddPhoto,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
```

---

### `lib/widgets/pn_item_card.dart`
```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_strings.dart';
import '../services/user_data_service.dart';
import 'report_sheet.dart';

class PnItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onDelete;

  const PnItemCard({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.onDelete,
  });

  @override
  State<PnItemCard> createState() => _PnItemCardState();
}

class _PnItemCardState extends State<PnItemCard> {
  String? _imagePath;
  late TextEditingController _notesCtrl;
  Timer? _debounce;

  bool get _isUserCreated => widget.item['userCreated'] == true;
  bool get _isVerified => widget.item['verified'] == true;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController();
    _loadExtras();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExtras() async {
    final extras =
        await UserDataService.getExtras(widget.item['id'] as String);
    if (mounted) {
      setState(() {
        _imagePath = extras['imagePath'] as String?;
        _notesCtrl.text = extras['notes'] as String? ?? '';
      });
    }
  }

  void _onNotesChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      UserDataService.setExtra(widget.item['id'] as String, 'notes', value);
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      await UserDataService.setExtra(
          widget.item['id'] as String, 'imagePath', picked.path);
      if (mounted) setState(() => _imagePath = picked.path);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.pnDelete),
        content: const Text(AppStrings.pnDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.delete,
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && widget.onDelete != null) widget.onDelete!();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.settings),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item['desc'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 4),
            if (_isVerified)
              Tooltip(
                message: AppStrings.verifiedTooltip,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, color: Colors.green, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      AppStrings.verifiedBadge,
                      style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            else if (_isUserCreated)
              Tooltip(
                message: AppStrings.unverifiedTooltip,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pending_outlined,
                        color: Colors.orange, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      AppStrings.unverifiedBadge,
                      style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Text('PN: ${item['pn'] ?? ''} | ATA: ${item['ata'] ?? ''}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                widget.isFavorite ? Icons.star : Icons.star_outline,
                color: widget.isFavorite ? Colors.amber : null,
              ),
              onPressed: widget.onToggleFavorite,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2,
                        size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 6),
                    Text(
                      '${AppStrings.pnQty}: ${item['qty'] ?? '—'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const Divider(height: 20),
                GestureDetector(
                  onTap: _pickImage,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _imagePath != null
                        ? Image.file(
                            File(_imagePath!),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _photoPlaceholder(context),
                          )
                        : _photoPlaceholder(context),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: AppStrings.detailNotes,
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.edit_note),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  onChanged: _onNotesChanged,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.rate_review_outlined, size: 16),
                      label: const Text(AppStrings.reportTitle,
                          style: TextStyle(fontSize: 12)),
                      onPressed: () => ReportSheet.show(
                        context,
                        itemId: item['id'] as String,
                        itemRef: 'PN: ${item['pn']} — ${item['desc']}',
                        section: 'PN',
                      ),
                    ),
                    if (_isUserCreated) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red)),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text(AppStrings.pnDelete,
                            style: TextStyle(fontSize: 12)),
                        onPressed: _confirmDelete,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder(BuildContext context) => Container(
        height: 150,
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(AppStrings.detailAddPhoto,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
}
```

---

### `lib/widgets/report_sheet.dart`  *(Bug #1 fixed)*
```dart
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/submissions_service.dart';

/// Shows a bottom sheet for submitting a report/contribution on any item.
/// Call [ReportSheet.show] from anywhere in the app.
class ReportSheet {
  static Future<void> show(
    BuildContext context, {
    required String itemId,
    required String itemRef,
    required String section,
  }) async {
    ReportType selectedType = ReportType.correction;
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.rate_review, color: Color(0xFF0033A0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            AppStrings.reportTitle,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            itemRef,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const Text(AppStrings.reportType,
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: ReportType.values.map((t) {
                    final selected = selectedType == t;
                    return ChoiceChip(
                      label: Text(t.label,
                          style: TextStyle(
                              fontSize: 12,
                              color: selected ? Colors.white : null)),
                      selected: selected,
                      selectedColor: const Color(0xFF0033A0),
                      onSelected: (_) =>
                          setSheetState(() => selectedType = t),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: AppStrings.reportDescription,
                    hintText: AppStrings.reportHint,
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? AppStrings.reportRequired
                      : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0033A0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.send),
                    label: const Text(AppStrings.reportSubmit),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      await SubmissionsService.add(
                        itemId: itemId,
                        itemRef: itemRef,
                        section: section,
                        type: selectedType,
                        description: descCtrl.text.trim(),
                      );
                      // FIX #1: use ctx (bottom sheet context) for both
                      // SnackBar and pop — never the outer context after await.
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(AppStrings.reportSent),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

### `lib/widgets/app_bar_actions.dart`
```dart
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../screens/contributions_screen.dart';
import '../screens/global_search_delegate.dart';

/// Shared AppBar actions used by all main screens:
///  - global search icon
///  - overflow menu with "Contribuciones"
List<Widget> buildAppBarActions(BuildContext context) {
  return [
    IconButton(
      icon: const Icon(Icons.search),
      tooltip: AppStrings.searchGlobal,
      onPressed: () =>
          showSearch(context: context, delegate: GlobalSearchDelegate()),
    ),
    PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'contributions') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ContributionsScreen(),
            ),
          );
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'contributions',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.rate_review),
            title: Text(AppStrings.contributionsMenuLabel),
          ),
        ),
      ],
    ),
  ];
}
```

---

### `lib/screens/disclaimer_screen.dart`
```dart
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import 'main_navigation_screen.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.disclaimerTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.disclaimerBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0033A0),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainNavigationScreen(),
                    ),
                  );
                },
                child: const Text(AppStrings.disclaimerButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### `lib/screens/main_navigation_screen.dart`
```dart
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import 'cb_search_screen.dart';
import 'fim_search_screen.dart';
import 'common_pn_screen.dart';
import 'revisions_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    CbSearchScreen(),
    FimSearchScreen(),
    CommonPnScreen(),
    RevisionsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.electrical_services),
            label: AppStrings.navBreakers,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: AppStrings.navFim,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_circle),
            label: AppStrings.navCommonPn,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: AppStrings.navRevisiones,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF0033A0),
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
```

---

### `lib/screens/cb_search_screen.dart`  *(Bug #4 fixed — unused import removed)*
```dart
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/data_cache.dart';
import '../widgets/cb_item_card.dart';
import '../widgets/searchable_list.dart';
import '../widgets/app_bar_actions.dart';

class CbSearchScreen extends StatefulWidget {
  const CbSearchScreen({super.key});

  @override
  State<CbSearchScreen> createState() => _CbSearchScreenState();
}

class _CbSearchScreenState extends State<CbSearchScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final items = await DataCache.instance.getCbItems();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.cbTitle),
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
        actions: buildAppBarActions(context),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SearchableList(
                items: _items,
                searchKeys: const ['system'],
                searchLabel: AppStrings.cbSearchHint,
                screenId: 'cb',
                itemBuilder: (context, item, isFav, onToggle) => CbItemCard(
                  item: item,
                  isFavorite: isFav,
                  onToggleFavorite: onToggle,
                ),
              ),
            ),
    );
  }
}
```

---

### `lib/screens/fim_search_screen.dart`  *(Bug #5 fixed — unused import removed)*
```dart
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/data_cache.dart';
import '../widgets/searchable_list.dart';
import '../widgets/app_bar_actions.dart';
import '../widgets/report_sheet.dart';
import 'item_detail_screen.dart';

class FimSearchScreen extends StatefulWidget {
  const FimSearchScreen({super.key});

  @override
  State<FimSearchScreen> createState() => _FimSearchScreenState();
}

class _FimSearchScreenState extends State<FimSearchScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final items = await DataCache.instance.getFimItems();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.fimTitle),
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
        actions: buildAppBarActions(context),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SearchableList(
                items: _items,
                searchKeys: const ['fault', 'desc'],
                searchLabel: AppStrings.fimSearchHint,
                screenId: 'fim',
                itemBuilder: (context, item, isFav, onToggle) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['fault'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isFav ? Icons.star : Icons.star_outline,
                            color: isFav ? Colors.amber : null,
                          ),
                          onPressed: onToggle,
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${item['desc'] ?? ''}\n'
                      '${AppStrings.fimAccion}: ${item['fix'] ?? ''}',
                    ),
                    isThreeLine: true,
                    onLongPress: () => ReportSheet.show(
                      context,
                      itemId: item['id'] as String,
                      itemRef: 'FIM: ${item['fault']} — ${item['desc']}',
                      section: 'FIM',
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemDetailScreen(
                            item: {...item, '_type': 'fim'}),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
```

---

### `lib/screens/common_pn_screen.dart`  *(Bug #6 fixed — unused import removed)*
```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_strings.dart';
import '../services/data_cache.dart';
import '../services/user_data_service.dart';
import '../widgets/pn_item_card.dart';
import '../widgets/searchable_list.dart';
import '../widgets/app_bar_actions.dart';

class CommonPnScreen extends StatefulWidget {
  const CommonPnScreen({super.key});

  @override
  State<CommonPnScreen> createState() => _CommonPnScreenState();
}

class _CommonPnScreenState extends State<CommonPnScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final items = await DataCache.instance.getAllPnItems();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _deleteUserPn(String id) async {
    await UserDataService.deleteUserPnItem(id);
    DataCache.instance.invalidatePn();
    await _loadData();
  }

  Future<void> _showAddPnDialog() async {
    final descCtrl = TextEditingController();
    final pnCtrl = TextEditingController();
    final ataCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    String? pickedImagePath;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> pickImage() async {
            final picked = await ImagePicker()
                .pickImage(source: ImageSource.gallery, imageQuality: 80);
            if (picked != null) {
              setSheetState(() => pickedImagePath = picked.path);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            AppStrings.pnAddTitle,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: AppStrings.pnFieldDesc,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: pnCtrl,
                      decoration: const InputDecoration(
                        labelText: AppStrings.pnFieldPn,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: ataCtrl,
                      decoration: const InputDecoration(
                        labelText: AppStrings.pnFieldAta,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: qtyCtrl,
                      decoration: const InputDecoration(
                        labelText: AppStrings.pnFieldQty,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: pickImage,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: pickedImagePath != null
                            ? Image.file(
                                File(pickedImagePath!),
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 100,
                                width: double.infinity,
                                color: Colors.grey.shade200,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 36, color: Colors.grey),
                                    SizedBox(height: 4),
                                    Text(AppStrings.detailAddPhoto,
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0033A0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.save),
                        label: const Text(AppStrings.save),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final id = 'user_pn_${DateTime.now().millisecondsSinceEpoch}';
                          final newItem = {
                            'id': id,
                            'desc': descCtrl.text.trim(),
                            'pn': pnCtrl.text.trim(),
                            'ata': ataCtrl.text.trim(),
                            'qty': qtyCtrl.text.trim().isEmpty ? '—' : qtyCtrl.text.trim(),
                            'userCreated': true,
                          };
                          await UserDataService.addUserPnItem(newItem);
                          if (pickedImagePath != null) {
                            await UserDataService.setExtra(id, 'imagePath', pickedImagePath);
                          }
                          DataCache.instance.invalidatePn();
                          if (ctx.mounted) Navigator.pop(ctx);
                          await _loadData();
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.pnTitle),
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
        actions: buildAppBarActions(context),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SearchableList(
                items: _items,
                searchKeys: const ['desc', 'pn', 'ata'],
                searchLabel: AppStrings.pnSearchHint,
                screenId: 'pn',
                itemBuilder: (context, item, isFav, onToggle) => PnItemCard(
                  item: item,
                  isFavorite: isFav,
                  onToggleFavorite: onToggle,
                  onDelete: item['userCreated'] == true
                      ? () => _deleteUserPn(item['id'] as String)
                      : null,
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.pnAddNew),
        onPressed: _showAddPnDialog,
      ),
    );
  }
}
```

---

### `lib/screens/revisions_screen.dart`  *(Bugs #2 & #7 fixed)*
```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import '../widgets/app_bar_actions.dart';

class RevisionsScreen extends StatefulWidget {
  const RevisionsScreen({super.key});

  @override
  State<RevisionsScreen> createState() => _RevisionsScreenState();
}

class _RevisionsScreenState extends State<RevisionsScreen> {
  static const _transitKey = 'transit_tasks';
  static const _dailyKey = 'daily_tasks';

  static const List<Map<String, dynamic>> _defaultTransit = [
    {"task": "Walkaround visual (Daños externos, fugas)", "isDone": false},
    {"task": "Revisar desgaste de frenos (Brake wear pins)", "isDone": false},
    {
      "task": "Comprobar nivel de aceite del motor (MCDU / FWD Panel)",
      "isDone": false
    },
  ];

  static const List<Map<String, dynamic>> _defaultDaily = [
    {"task": "Comprobar fluido hidráulico (Qty y estado)", "isDone": false},
    {
      "task": "Inspeccion visual APU (fugas, estado externo)",
      "isDone": false
    },
    {"task": "Verificar luces exteriores (NAV, STROBE, LOGO)", "isDone": false},
  ];

  List<Map<String, dynamic>> transitTasks = [];
  List<Map<String, dynamic>> dailyTasks = [];
  bool _loading = true;

  final TextEditingController _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final transitEncoded = prefs.getString(_transitKey);
    final dailyEncoded = prefs.getString(_dailyKey);
    if (mounted) {
      setState(() {
        transitTasks = transitEncoded != null
            ? (json.decode(transitEncoded) as List)
                .cast<Map<String, dynamic>>()
            : _defaultTransit.map((t) => Map<String, dynamic>.from(t)).toList();
        dailyTasks = dailyEncoded != null
            ? (json.decode(dailyEncoded) as List).cast<Map<String, dynamic>>()
            : _defaultDaily.map((t) => Map<String, dynamic>.from(t)).toList();
        _loading = false;
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_transitKey, json.encode(transitTasks));
    await prefs.setString(_dailyKey, json.encode(dailyTasks));
  }

  void _resetTasks() {
    setState(() {
      for (var item in transitTasks) {
        item["isDone"] = false;
      }
      for (var item in dailyTasks) {
        item["isDone"] = false;
      }
    });
    _saveTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.revisionsResetMsg)),
      );
    }
  }

  void _showAddTaskDialog(List<Map<String, dynamic>> targetList) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.revisionsAddTask),
        content: TextField(
          controller: _taskController,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: AppStrings.revisionsTaskHint),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _taskController.clear();
              Navigator.pop(context);
            },
            child: const Text(AppStrings.revisionsCancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (_taskController.text.isNotEmpty) {
                setState(() {
                  targetList
                      .add({"task": _taskController.text, "isDone": false});
                });
                _saveTasks();
                _taskController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text(AppStrings.revisionsAdd),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          'No hay tareas. Pulsa + para añadir.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Dismissible(
          key: ValueKey('${task['task']}_$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            final removed = task['task'] as String;
            setState(() => tasks.removeAt(index));
            _saveTasks();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$removed — ${AppStrings.revisionsDeletedMsg}'),
                  action: SnackBarAction(
                    label: 'Deshacer',
                    onPressed: () {
                      // FIX #2: clamp index to guard against concurrent dismissals
                      setState(() => tasks.insert(
                            index.clamp(0, tasks.length),
                            task,
                          ));
                      _saveTasks();
                    },
                  ),
                ),
              );
            }
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: CheckboxListTile(
              title: Text(
                task["task"] as String,
                style: TextStyle(
                  decoration: task["isDone"] as bool
                      ? TextDecoration.lineThrough
                      : null,
                  color: task["isDone"] as bool
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
              value: task["isDone"] as bool,
              activeColor: Colors.green,
              onChanged: (bool? newValue) {
                setState(() => task["isDone"] = newValue!);
                _saveTasks();
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.revisionsTitle),
          backgroundColor: const Color(0xFF0033A0),
          foregroundColor: Colors.white,
          actions: [
            ...buildAppBarActions(context),
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              tooltip: AppStrings.revisionsResetTooltip,
              onPressed: _resetTasks,
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: AppStrings.revisionsTransit),
              Tab(text: AppStrings.revisionsDaily),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Builder(
                builder: (context) => TabBarView(
                  children: [
                    _buildTaskList(transitTasks),
                    _buildTaskList(dailyTasks),
                  ],
                ),
              ),
        floatingActionButton: _loading
            ? null
            : Builder(
                builder: (context) {
                  final tabController = DefaultTabController.of(context);
                  return FloatingActionButton(
                    backgroundColor: const Color(0xFF0033A0),
                    foregroundColor: Colors.white,
                    onPressed: () {
                      final targetList = tabController.index == 0
                          ? transitTasks
                          : dailyTasks;
                      _showAddTaskDialog(targetList);
                    },
                    child: const Icon(Icons.add),
                  );
                },
              ),
      ),
    );
  }
}
```

---

### `lib/screens/global_search_delegate.dart`
```dart
import 'package:flutter/material.dart';
import '../services/data_cache.dart';
import 'item_detail_screen.dart';

class GlobalSearchDelegate extends SearchDelegate<void> {
  @override
  String get searchFieldLabel => 'Buscar en CB, FIM y PN…';

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) =>
      _SearchResults(query: query);

  @override
  Widget buildSuggestions(BuildContext context) =>
      _SearchResults(query: query);
}

class _SearchResults extends StatefulWidget {
  final String query;
  const _SearchResults({required this.query});

  @override
  State<_SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<_SearchResults> {
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _search(widget.query);
  }

  @override
  void didUpdateWidget(_SearchResults old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) _search(widget.query);
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      if (mounted) setState(() => _results = []);
      return;
    }
    if (mounted) setState(() => _loading = true);

    final lower = q.toLowerCase();
    final results = <Map<String, dynamic>>[];

    final cb = await DataCache.instance.getCbItems();
    for (final item in cb) {
      if (_matches(item, lower, ['system', 'amm', 'panel'])) {
        results.add({
          ...item,
          '_type': 'cb',
          '_label': item['system'],
          '_sub': 'Panel: ${item['panel']} | ${item['amm']}',
        });
      }
    }

    final fim = await DataCache.instance.getFimItems();
    for (final item in fim) {
      if (_matches(item, lower, ['fault', 'desc'])) {
        results.add({
          ...item,
          '_type': 'fim',
          '_label': item['fault'],
          '_sub': item['desc'],
        });
      }
    }

    final pn = await DataCache.instance.getAllPnItems();
    for (final item in pn) {
      if (_matches(item, lower, ['desc', 'pn', 'ata'])) {
        results.add({
          ...item,
          '_type': 'pn',
          '_label': item['desc'],
          '_sub': 'PN: ${item['pn']} | ATA ${item['ata']}',
        });
      }
    }

    if (mounted) setState(() {
      _results = results;
      _loading = false;
    });
  }

  bool _matches(Map<String, dynamic> item, String lower, List<String> keys) {
    return keys.any((k) =>
        (item[k] ?? '').toString().toLowerCase().contains(lower));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (widget.query.trim().isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Escribe para buscar en CB, FIM y PN',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text('Sin resultados', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (ctx, i) {
        final item = _results[i];
        final type = item['_type'] as String;
        return ListTile(
          leading: _TypeChip(type: type),
          title: Text(item['_label'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(item['_sub'] ?? ''),
          onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => ItemDetailScreen(item: item),
            ),
          ),
        );
      },
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      'cb'  => ('CB',  Colors.blueGrey),
      'fim' => ('FIM', Colors.orange),
      'pn'  => ('PN',  Colors.teal),
      _     => ('?',   Colors.grey),
    };
    return Container(
      width: 42,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
```

---

### `lib/screens/item_detail_screen.dart`
```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_strings.dart';
import '../services/user_data_service.dart';
import '../widgets/report_sheet.dart';

/// Full-screen detail for any item type (CB, FIM, PN).
/// [item] must include '_type': 'cb' | 'fim' | 'pn'
class ItemDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final type = item['_type'] as String? ?? '';
    return switch (type) {
      'cb'  => _CbDetail(item: item),
      'fim' => _FimDetail(item: item),
      'pn'  => _PnDetail(item: item),
      _     => Scaffold(appBar: AppBar(title: const Text('Detalle'))),
    };
  }
}

// ─── CB Detail ────────────────────────────────────────────────────────────────

class _CbDetail extends StatefulWidget {
  final Map<String, dynamic> item;
  const _CbDetail({required this.item});

  @override
  State<_CbDetail> createState() => _CbDetailState();
}

class _CbDetailState extends State<_CbDetail> {
  String? _imagePath;
  late TextEditingController _notesCtrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final extras =
        await UserDataService.getExtras(widget.item['id'] as String);
    if (mounted) {
      setState(() {
        _imagePath = extras['imagePath'] as String?;
        _notesCtrl.text = extras['notes'] as String? ?? '';
      });
    }
  }

  void _onNotesChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      UserDataService.setExtra(widget.item['id'] as String, 'notes', v);
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      await UserDataService.setExtra(
          widget.item['id'] as String, 'imagePath', picked.path);
      if (mounted) setState(() => _imagePath = picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(
        title: Text(item['system'] ?? ''),
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: AppStrings.reportTitle,
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
        onPressed: () => ReportSheet.show(
          context,
          itemId: item['id'] as String,
          itemRef: 'CB: ${item['system']} (${item['panel']})',
          section: 'CB',
        ),
        child: const Icon(Icons.rate_review_outlined),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(icon: Icons.electrical_services, label: 'Panel', value: item['panel'] ?? ''),
            _InfoRow(icon: Icons.grid_on,             label: 'Grid',  value: item['grid']  ?? ''),
            _InfoRow(icon: Icons.book,                label: 'AMM',   value: item['amm']   ?? ''),
            const Divider(height: 24),
            _PhotoSection(imagePath: _imagePath, onTap: _pickImage),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: AppStrings.detailNotes,
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.edit_note),
              ),
              maxLines: 4,
              onChanged: _onNotesChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FIM Detail ───────────────────────────────────────────────────────────────

class _FimDetail extends StatefulWidget {
  final Map<String, dynamic> item;
  const _FimDetail({required this.item});

  @override
  State<_FimDetail> createState() => _FimDetailState();
}

class _FimDetailState extends State<_FimDetail> {
  late TextEditingController _notesCtrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final extras =
        await UserDataService.getExtras(widget.item['id'] as String);
    if (mounted) _notesCtrl.text = extras['notes'] as String? ?? '';
  }

  void _onNotesChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      UserDataService.setExtra(widget.item['id'] as String, 'notes', v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(
        title: Text(item['fault'] ?? ''),
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: AppStrings.reportTitle,
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
        onPressed: () => ReportSheet.show(
          context,
          itemId: item['id'] as String,
          itemRef: 'FIM: ${item['fault']} — ${item['desc']}',
          section: 'FIM',
        ),
        child: const Icon(Icons.rate_review_outlined),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['desc'] ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.engineering,
                        color: Theme.of(context).colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.fimAccion,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onErrorContainer),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['fix'] ?? '',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: AppStrings.detailNotes,
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.edit_note),
              ),
              maxLines: 4,
              onChanged: _onNotesChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PN Detail ────────────────────────────────────────────────────────────────

class _PnDetail extends StatefulWidget {
  final Map<String, dynamic> item;
  const _PnDetail({required this.item});

  @override
  State<_PnDetail> createState() => _PnDetailState();
}

class _PnDetailState extends State<_PnDetail> {
  String? _imagePath;
  late TextEditingController _notesCtrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final extras =
        await UserDataService.getExtras(widget.item['id'] as String);
    if (mounted) {
      setState(() {
        _imagePath = extras['imagePath'] as String?;
        _notesCtrl.text = extras['notes'] as String? ?? '';
      });
    }
  }

  void _onNotesChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      UserDataService.setExtra(widget.item['id'] as String, 'notes', v);
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      await UserDataService.setExtra(
          widget.item['id'] as String, 'imagePath', picked.path);
      if (mounted) setState(() => _imagePath = picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(
        title: Text(item['desc'] ?? ''),
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: AppStrings.reportTitle,
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
        onPressed: () => ReportSheet.show(
          context,
          itemId: item['id'] as String,
          itemRef: 'PN: ${item['pn']} — ${item['desc']}',
          section: 'PN',
        ),
        child: const Icon(Icons.rate_review_outlined),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(icon: Icons.tag,         label: 'PN',             value: item['pn']  ?? ''),
            _InfoRow(icon: Icons.category,    label: 'ATA',            value: item['ata'] ?? ''),
            _InfoRow(icon: Icons.inventory_2, label: AppStrings.pnQty, value: item['qty'] ?? '—'),
            const Divider(height: 24),
            _PhotoSection(imagePath: _imagePath, onTap: _pickImage),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: AppStrings.detailNotes,
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.edit_note),
              ),
              maxLines: 4,
              onChanged: _onNotesChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;
  const _PhotoSection({this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: imagePath != null
            ? Image.file(
                File(imagePath!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(context),
              )
            : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
        height: 160,
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(AppStrings.detailAddPhoto,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
}
```

---

### `lib/screens/contributions_screen.dart`  *(Bug #3 fixed — Color.fromRGBO)*
```dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_strings.dart';
import '../services/submissions_service.dart';

class ContributionsScreen extends StatefulWidget {
  const ContributionsScreen({super.key});

  @override
  State<ContributionsScreen> createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends State<ContributionsScreen> {
  List<Map<String, dynamic>> _submissions = [];
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await SubmissionsService.getAll();
    if (mounted) {
      setState(() {
        _submissions = list.reversed.toList();
        _loading = false;
      });
    }
  }

  Future<void> _export() async {
    if (_submissions.isEmpty) return;
    setState(() => _exporting = true);
    try {
      final path = await SubmissionsService.exportToCsvFile();
      await Share.shareXFiles(
        [XFile(path, mimeType: 'text/csv')],
        subject: 'B737 Tools – Contribuciones de usuarios',
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _delete(String id) async {
    await SubmissionsService.delete(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.contributionsTitle),
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
        actions: [
          if (_submissions.isNotEmpty)
            _exporting
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: AppStrings.contributionsExport,
                    onPressed: _export,
                  ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _submissions.isEmpty
              ? _emptyState(context)
              : Column(
                  children: [
                    // Info banner — FIX #3: Color.fromRGBO replaces deprecated withOpacity
                    Container(
                      width: double.infinity,
                      color: Color.fromRGBO(0, 51, 160, 0.08),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: Color(0xFF0033A0)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_submissions.length} contribuciones guardadas. '
                              'Pulsa ↓ para exportar como CSV y abrir en Excel.',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF0033A0)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _submissions.length,
                        itemBuilder: (ctx, i) => _SubmissionTile(
                          submission: _submissions[i],
                          onDelete: () => _delete(_submissions[i]['id']),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            AppStrings.contributionsEmpty,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  final Map<String, dynamic> submission;
  final VoidCallback onDelete;
  const _SubmissionTile({required this.submission, required this.onDelete});

  Color get _sectionColor {
    switch (submission['section']) {
      case 'CB':  return Colors.blueGrey;
      case 'FIM': return Colors.orange;
      case 'PN':  return Colors.teal;
      default:    return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawDate = submission['date'] as String? ?? '';
    final date = rawDate.isNotEmpty ? rawDate.substring(0, 10) : '—';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SectionChip(
                    label: submission['section'] ?? '?',
                    color: _sectionColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    submission['type'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(date,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              submission['itemRef'] ?? '',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 6),
            Text(submission['description'] ?? ''),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Eliminar', style: TextStyle(fontSize: 12)),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Eliminar contribución'),
                      content: const Text('¿Eliminar este registro localmente?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Eliminar',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) onDelete();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}
```

---

## 6. Suggested Next Steps

Paste this document into a new Claude chat and then ask for any of:

| Feature | Prompt suggestion |
|---------|-------------------|
| More CB / FIM / PN data | "Amplía los JSON de datos con 20 circuit breakers reales del panel P6" |
| Fix SEC-1 (CSV injection) | "Implementa la función `_csvSafe()` en submissions_service.dart" |
| Fix SEC-2 (maxLength) | "Añade validación maxLength a los formularios de PN y contribuciones" |
| Offline PDF export | "Añade exportación a PDF del checklist de revisiones usando el paquete pdf" |
| Sync via QR | "Implementa exportación/importación del estado local mediante códigos QR" |
| AMM deep-links | "Añade un botón en cada CB card que abra el PDF del AMM correspondiente" |
| Unit tests | "Escribe tests unitarios para DataCache, FavoritesService y SubmissionsService" |
| Localisation (English) | "Añade soporte multilingüe (ES/EN) con flutter_localizations" |
| Authentication | "Añade un PIN de acceso opcional usando local_auth o flutter_secure_storage" |

