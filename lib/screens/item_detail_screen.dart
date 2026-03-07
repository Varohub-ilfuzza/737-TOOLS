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
      'cb' => _CbDetail(item: item),
      'fim' => _FimDetail(item: item),
      'pn' => _PnDetail(item: item),
      _ => Scaffold(appBar: AppBar(title: const Text('Detalle'))),
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
            _InfoRow(icon: Icons.electrical_services,
                label: 'Panel', value: item['panel'] ?? ''),
            _InfoRow(icon: Icons.grid_on,
                label: 'Grid', value: item['grid'] ?? ''),
            _InfoRow(icon: Icons.book,
                label: 'AMM', value: item['amm'] ?? ''),
            const Divider(height: 24),
            _PhotoSection(
                imagePath: _imagePath, onTap: _pickImage),
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['fix'] ?? '',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer),
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
            _InfoRow(
                icon: Icons.tag, label: 'PN', value: item['pn'] ?? ''),
            _InfoRow(
                icon: Icons.category, label: 'ATA', value: item['ata'] ?? ''),
            _InfoRow(
                icon: Icons.inventory_2,
                label: AppStrings.pnQty,
                value: item['qty'] ?? '—'),
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

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
}
