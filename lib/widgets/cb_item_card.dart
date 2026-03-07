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
                // AMM reference
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
                                _photoPlaceholder(context, hasPhoto: false),
                          )
                        : _photoPlaceholder(context, hasPhoto: false),
                  ),
                ),
                const SizedBox(height: 12),
                // Notes
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
