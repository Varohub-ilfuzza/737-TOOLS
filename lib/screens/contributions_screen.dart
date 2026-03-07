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
        _submissions = list.reversed.toList(); // newest first
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
                    // Info banner
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
                        itemBuilder: (ctx, i) =>
                            _SubmissionTile(
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

  const _SubmissionTile(
      {required this.submission, required this.onDelete});

  Color get _sectionColor {
    switch (submission['section']) {
      case 'CB':
        return Colors.blueGrey;
      case 'FIM':
        return Colors.orange;
      case 'PN':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawDate = submission['date'] as String? ?? '';
    final date = rawDate.isNotEmpty
        ? rawDate.substring(0, 10) // YYYY-MM-DD
        : '—';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: section chip + type + date
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
            // Item reference
            Text(
              submission['itemRef'] ?? '',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 6),
            // Description
            Text(submission['description'] ?? ''),
            const SizedBox(height: 8),
            // Delete
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
                      content:
                          const Text('¿Eliminar este registro localmente?'),
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
