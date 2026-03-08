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
  static const navFavorites = 'Favoritos';

  // CB screen
  static const cbTitle = 'Circuit Breakers';
  static const cbSearchHint = 'Buscar sistema, panel, grid o AMM';

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
  static const favoritesHint = 'Toca la estrella ★ en cualquier elemento\npara añadirlo aquí.';

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

  // Schemas
  static const navSchemas = 'Esquemas';
  static const schemasTitle = 'Esquemas B737';
  static const schemasEmpty = 'Aún no hay esquemas cargados';
  static const schemasEmptyHint =
      'Añade PDFs organizados por ATA en assets/schemas/\ny regístralos en lib/data/schemas_registry.dart';
  static const schemasPending = 'Sin esquemas';
  static const schemasFilterAll = 'Mostrar todos los ATAs';
  static const schemasFilterActive = 'Solo ATAs con esquemas';
  static const schemasPage = 'Pág.';
  static const schemasPages = 'págs.';
  static const schemasDrawMode = 'Modo dibujo';
  static const schemasViewMode = 'Modo vista';
  static const schemasDrawingActive = 'Modo dibujo activo';
  static const schemasUndo = 'Deshacer último trazo';
  static const schemasClearPage = 'Borrar anotaciones de esta página';
  static const schemasClearPageSub = 'Elimina los trazos solo de la página actual';
  static const schemasClearAll = 'Borrar todas las anotaciones';
  static const schemasClearAllSub = 'Elimina los trazos de todas las páginas del esquema';
  static const schemasClearAllConfirm =
      '¿Eliminar todas las anotaciones de este esquema?\nNo se puede deshacer.';
  static const schemasPen = 'Lápiz';
  static const schemasArrow = 'Flecha';

  // General
  static const loading = 'Cargando...';
  static const cancel = 'Cancelar';
  static const save = 'Guardar';
  static const delete = 'Eliminar';
  static const confirm = 'Confirmar';
}
