# Changelog — B737 Tools

Todos los cambios notables del proyecto se documentan en este archivo.
Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).

---

## [Beta 0.4] — 2026-03-09

### Añadido
- **Sistema OTA de actualización de datos** — los datos (CB, FIM, PN) se actualizan automáticamente desde GitHub sin requerir una nueva versión en la store.
  - `RemoteDataService`: al arrancar comprueba `data_version.json` en GitHub raw; si la versión remota es mayor, descarga los tres JSON y los persiste en el directorio de documentos del dispositivo.
  - `DataService` actualizado: lee primero del archivo OTA en disco; si no existe o falla, usa el asset bundled como fallback. La app siempre funciona offline.
  - `DataCache.invalidateAll()`: invalida la caché en memoria tras descarga OTA.
  - `assets/data_version.json`: fichero de control de versión en el repo. Para desplegar datos nuevos a todos los dispositivos basta incrementar `"version"` y hacer push.
  - `main.dart`: el chequeo OTA es completamente asíncrono y no bloquea el arranque.

### Flujo para actualizar datos sin tocar la store
```
1. Edita cb_data.json / fim_data.json / pn_data.json en el repo
2. Incrementa "version" en assets/data_version.json
3. Push a rama main
→ Todos los dispositivos descargan los datos en el próximo arranque
```

---

## [Beta 0.3] — 2026-03-08

### Añadido
- **Módulo Esquemas (tab 6):** Nueva pantalla `SchemasScreen` con listado de todos los capítulos ATA del B737 (ATA 21 al 49). Cada ATA es expandible y muestra sus sub-ATAs con título, código y número de páginas.
- **Visor de esquemas `SchemaViewerScreen`:** Visualizador de PDFs con zoom/pan mediante `pdfx`. Navegación página a página con botones prev/next y contador de página actual.
- **Herramienta de dibujo y anotación sobre PDF:**
  - **Modo Dibujo** activable/desactivable desde la AppBar (ícono lápiz / ojo).
  - Herramienta **Lápiz** — trazo libre con curva suavizada (Bézier cuadrático).
  - Herramienta **Flecha** — arrastra para dibujar una flecha con cabeza.
  - **3 grosores** de trazo (fino, medio, grueso).
  - **5 colores** de paleta (azul, rojo, verde, ámbar, blanco).
  - **Undo** — deshace el último trazo de la página actual.
  - **Borrar página** — elimina anotaciones de la página actual.
  - **Borrar todo** — elimina todas las anotaciones del esquema (con confirmación).
- **Persistencia de anotaciones:** `AnnotationsService` serializa y guarda cada trazo por esquema + página en `SharedPreferences` como JSON. Las anotaciones sobreviven al cierre de la app hasta que el usuario las borra explícitamente.
- **`AnnotationPainter`** (`CustomPainter`): renderizado eficiente de trazos con `shouldRepaint` selectivo.
- **Registro de esquemas `schemas_registry.dart`:** Lista de ATAs lista para ser poblada; incluye instrucciones en comentarios de cómo añadir nuevos PDFs.
- `app_strings.dart`: 20+ cadenas nuevas para el módulo Esquemas.
- `pubspec.yaml`: dependencia `pdfx ^2.6.0`; directorio de assets `assets/schemas/`.

### Técnico
- Modelo de datos `AtaChapter` / `SchemaEntry` en `lib/models/schema_item.dart`.
- Separación limpia entre capa de datos (`schemas_registry.dart`), capa de servicio (`annotations_service.dart`) y capa de UI (`schemas_screen.dart`, `schema_viewer_screen.dart`).

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
