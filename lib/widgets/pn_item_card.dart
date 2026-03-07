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
            // ── Verification badge ──────────────────────────────────
            if (_isVerified)
              Tooltip(
                message: AppStrings.verifiedTooltip,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified,
                        color: Colors.green, size: 16),
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
                // Qty
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
                // Photo
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
                // Notes
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
                // Action row: report + (delete if user-created)
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
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
}
