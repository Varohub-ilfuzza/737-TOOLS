import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../models/schema_item.dart';
import '../services/annotations_service.dart';
import '../widgets/drawing_canvas.dart';
import '../l10n/app_strings.dart';

class SchemaViewerScreen extends StatefulWidget {
  final SchemaEntry entry;

  const SchemaViewerScreen({super.key, required this.entry});

  @override
  State<SchemaViewerScreen> createState() => _SchemaViewerScreenState();
}

class _SchemaViewerScreenState extends State<SchemaViewerScreen> {
  late PdfControllerPinch _pdfController;

  int _currentPage = 1;
  bool _isDrawingMode = false;

  DrawingTool _activeTool = DrawingTool.pen;
  Color _activeColor = Colors.blue;
  double _strokeWidth = 3.0;

  // strokes stored per page number
  final Map<int, List<AnnotationStroke>> _strokesMap = {};
  AnnotationStroke? _currentStroke;
  Offset? _arrowStart;

  static const _palette = <Color>[
    Color(0xFF1565C0), // blue
    Color(0xFFC62828), // red
    Color(0xFF2E7D32), // green
    Color(0xFFF57F17), // amber
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openAsset(widget.entry.assetPath),
    );
    _loadPage(1);
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  // ── Annotation persistence ────────────────────────────────────────────────

  Future<void> _loadPage(int page) async {
    if (_strokesMap.containsKey(page)) return;
    final strokes = await AnnotationsService.load(widget.entry.id, page);
    if (mounted) setState(() => _strokesMap[page] = strokes);
  }

  List<AnnotationStroke> get _currentStrokes => _strokesMap[_currentPage] ?? [];

  Future<void> _saveCurrentPage() async {
    await AnnotationsService.save(
        widget.entry.id, _currentPage, _currentStrokes);
  }

  // ── Drawing gestures ──────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    final pos = d.localPosition;
    if (_activeTool == DrawingTool.arrow) {
      _arrowStart = pos;
      setState(() {
        _currentStroke = AnnotationStroke(
          tool: DrawingTool.arrow,
          colorValue: _activeColor.value,
          strokeWidth: _strokeWidth,
          points: [pos, pos],
        );
      });
    } else {
      setState(() {
        _currentStroke = AnnotationStroke(
          tool: DrawingTool.pen,
          colorValue: _activeColor.value,
          strokeWidth: _strokeWidth,
          points: [pos],
        );
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_currentStroke == null) return;
    final pos = d.localPosition;
    setState(() {
      if (_activeTool == DrawingTool.arrow) {
        _currentStroke = AnnotationStroke(
          tool: DrawingTool.arrow,
          colorValue: _activeColor.value,
          strokeWidth: _strokeWidth,
          points: [_arrowStart!, pos],
        );
      } else {
        _currentStroke = AnnotationStroke(
          tool: DrawingTool.pen,
          colorValue: _activeColor.value,
          strokeWidth: _strokeWidth,
          points: [..._currentStroke!.points, pos],
        );
      }
    });
  }

  void _onPanEnd(DragEndDetails _) {
    if (_currentStroke == null) return;
    final updated = [..._currentStrokes, _currentStroke!];
    setState(() {
      _strokesMap[_currentPage] = updated;
      _currentStroke = null;
      _arrowStart = null;
    });
    AnnotationsService.save(widget.entry.id, _currentPage, updated);
  }

  // ── Undo / clear ─────────────────────────────────────────────────────────

  void _undo() {
    final s = _currentStrokes;
    if (s.isEmpty) return;
    final updated = s.sublist(0, s.length - 1);
    setState(() => _strokesMap[_currentPage] = updated);
    AnnotationsService.save(widget.entry.id, _currentPage, updated);
  }

  Future<void> _clearPage() async {
    setState(() => _strokesMap[_currentPage] = []);
    await AnnotationsService.clearPage(widget.entry.id, _currentPage);
  }

  Future<void> _clearAll() async {
    for (int p = 1; p <= widget.entry.totalPages; p++) {
      await AnnotationsService.clearPage(widget.entry.id, p);
    }
    setState(_strokesMap.clear);
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showClearMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.orange),
              title: Text(AppStrings.schemasClearPage),
              subtitle: Text(AppStrings.schemasClearPageSub),
              onTap: () {
                Navigator.pop(ctx);
                _clearPage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: Text(AppStrings.schemasClearAll),
              subtitle: Text(AppStrings.schemasClearAllSub),
              onTap: () {
                Navigator.pop(ctx);
                _confirmClearAll();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.schemasClearAll),
        content: Text(AppStrings.schemasClearAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearAll();
            },
            child: const Text(AppStrings.delete,
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.entry.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.entry.subCode,
                style: const TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
        actions: [
          if (_isDrawingMode) ...[
            if (_currentStrokes.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: AppStrings.schemasUndo,
                onPressed: _undo,
              ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: AppStrings.schemasClearPage,
              onPressed: _showClearMenu,
            ),
          ],
          IconButton(
            icon: Icon(_isDrawingMode ? Icons.visibility : Icons.edit),
            tooltip: _isDrawingMode
                ? AppStrings.schemasViewMode
                : AppStrings.schemasDrawMode,
            onPressed: () =>
                setState(() => _isDrawingMode = !_isDrawingMode),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── PDF + Drawing canvas ─────────────────────────────────────────
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // PDF layer (disabled when drawing)
                IgnorePointer(
                  ignoring: _isDrawingMode,
                  child: PdfViewPinch(
                    controller: _pdfController,
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                      _loadPage(page);
                    },
                    builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                      options: const DefaultBuilderOptions(),
                      documentLoaderBuilder: (_) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      pageLoaderBuilder: (_) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorBuilder: (_, error) => Center(
                        child: Text('Error: $error',
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  ),
                ),

                // Annotation canvas layer
                IgnorePointer(
                  ignoring: !_isDrawingMode,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      painter: AnnotationPainter(
                        strokes: _currentStrokes,
                        currentStroke: _currentStroke,
                      ),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),

                // Drawing mode badge
                if (_isDrawingMode)
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.88),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit, color: Colors.white, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              AppStrings.schemasDrawingActive,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Drawing toolbar ───────────────────────────────────────────────
          if (_isDrawingMode) _buildDrawingToolbar(),

          // ── Page navigation bar ───────────────────────────────────────────
          _buildPageBar(),
        ],
      ),
    );
  }

  // ── Toolbar ───────────────────────────────────────────────────────────────

  Widget _buildDrawingToolbar() {
    return Container(
      color: const Color(0xFF12122A),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Tools
          _ToolButton(
            icon: Icons.edit,
            label: AppStrings.schemasPen,
            isActive: _activeTool == DrawingTool.pen,
            onTap: () => setState(() => _activeTool = DrawingTool.pen),
          ),
          const SizedBox(width: 4),
          _ToolButton(
            icon: Icons.arrow_forward,
            label: AppStrings.schemasArrow,
            isActive: _activeTool == DrawingTool.arrow,
            onTap: () => setState(() => _activeTool = DrawingTool.arrow),
          ),
          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
                height: 30,
                child: VerticalDivider(color: Colors.white24, width: 1)),
          ),
          // Stroke width
          _StrokeBtn(
            size: 2,
            isActive: _strokeWidth == 2.0,
            color: _activeColor,
            onTap: () => setState(() => _strokeWidth = 2.0),
          ),
          const SizedBox(width: 4),
          _StrokeBtn(
            size: 5,
            isActive: _strokeWidth == 5.0,
            color: _activeColor,
            onTap: () => setState(() => _strokeWidth = 5.0),
          ),
          const SizedBox(width: 4),
          _StrokeBtn(
            size: 9,
            isActive: _strokeWidth == 9.0,
            color: _activeColor,
            onTap: () => setState(() => _strokeWidth = 9.0),
          ),
          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
                height: 30,
                child: VerticalDivider(color: Colors.white24, width: 1)),
          ),
          // Color palette
          ..._palette.map((c) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _ColorDot(
                  color: c,
                  isActive: _activeColor.value == c.value,
                  onTap: () => setState(() => _activeColor = c),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPageBar() {
    return Container(
      color: const Color(0xFF0033A0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            padding: EdgeInsets.zero,
            onPressed: _currentPage > 1
                ? () => _pdfController.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            '${AppStrings.schemasPage} $_currentPage / ${widget.entry.totalPages}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            padding: EdgeInsets.zero,
            onPressed: _currentPage < widget.entry.totalPages
                ? () => _pdfController.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    )
                : null,
          ),
        ],
      ),
    );
  }
}

// ── Toolbar sub-widgets ───────────────────────────────────────────────────────

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? Colors.orange : Colors.white12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _StrokeBtn extends StatelessWidget {
  final double size;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _StrokeBtn({
    required this.size,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? Colors.white12 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isActive
              ? Border.all(color: Colors.orange, width: 1.5)
              : null,
        ),
        child: Center(
          child: Container(
            width: size * 3,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(size),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? Colors.orange : Colors.white30,
            width: isActive ? 2.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: Colors.orange.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1)
                ]
              : null,
        ),
      ),
    );
  }
}
