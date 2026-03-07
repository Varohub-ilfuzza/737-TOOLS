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
                      maxLength: 200,
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
                      maxLength: 30,
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
                      maxLength: 10,
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
