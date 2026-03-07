# Changelog — B737 Tools

Todos los cambios notables del proyecto se documentan en este archivo.
Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).

---

## [Beta 0.2] — 2026-03-07

### Seguridad
- **SEC-1 (Medium):** Añadida función `_csvSafe()` en `submissions_service.dart` para neutralizar inyección de fórmulas CSV. Los caracteres de inicio de fórmula (`=`, `+`, `-`, `@`) al comienzo de los campos `ref`, `type` y `desc` se prefijan con una comilla simple antes de escribir en el CSV exportado.
- **SEC-2 (Low):** Aplicados límites de longitud a campos de entrada de usuario:
  - `common_pn_screen.dart`: descripción máx. 200 chars, número de parte máx. 30 chars, referencia ATA máx. 10 chars.
  - `report_sheet.dart`: campo de descripción del reporte máx. 1000 chars.

### Añadido
- **Tab Favoritos (tab 5):** Nueva pantalla `FavoritesScreen` que muestra todos los items marcados como favoritos de los módulos CB, FIM y PN, agrupados por módulo con cabecera de sección. Permite eliminar favoritos directamente con swipe y soporta pull-to-refresh.
- **`main_navigation_screen.dart`:** Integración del tab Favoritos en la barra de navegación principal.
- **`app_strings.dart`:** Añadidas cadenas de localización para la pantalla de Favoritos (`favorites`, `noFavorites`, `favoritesHint`).

### Mejorado
- **CB Search (`cb_search_screen.dart`):** Ampliadas las claves de búsqueda (`searchKeys`) para incluir `system`, `panel`, `grid` y `amm`, mejorando la capacidad de filtrado. Actualizado el texto de hint del campo de búsqueda para reflejar los nuevos campos consultables.

---

## [Beta 0.1] — 2026-03-07

### Añadido
- Proyecto Flutter inicial — B737 Tools.
- **Tab CB (Breakers):** Búsqueda de interruptores de circuito con referencia de panel, grid y AMM.
- **Tab FIM:** Consulta rápida del Fault Isolation Manual.
- **Tab Common PN:** Referencia de números de parte con posibilidad de añadir PNs personalizados.
- **Tab Revisiones:** Checklists de Transit Check y Daily Check con undo por deslizamiento.
- `DisclaimerScreen` mostrada en cada inicio (aviso de seguridad reglamentario).
- `ItemDetailScreen` para vista de detalle completo de items CB / FIM / PN.
- `ContributionsScreen` con lista y exportación CSV de reportes enviados por el usuario.
- `GlobalSearchDelegate` para búsqueda cruzada entre módulos CB, FIM y PN en una sola consulta.
- Sistema de favoritos (`FavoritesService`) con persistencia local mediante `SharedPreferences`.
- Sistema de historial de búsquedas (`SearchHistoryService`).
- Caché de datos en memoria (`DataCache`) para carga eficiente de assets JSON.
- `DataService` para lectura de los archivos JSON de datos (`cb_data.json`, `fim_data.json`, `pn_data.json`).
- `UserDataService` para gestión de PNs personalizados añadidos por el usuario.
- `SubmissionsService` para almacenamiento y exportación CSV de reportes.
- `ReportSheet` — bottom sheet para envío de reportes de incidencias.
- Widgets reutilizables: `SearchableList`, `CbItemCard`, `PnItemCard`, `AppBarActions`.
- Internacionalización básica mediante `app_strings.dart`.
- Arquitectura 100% offline — cero peticiones de red.
