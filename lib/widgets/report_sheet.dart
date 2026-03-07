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
                // Header
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

                // Type selector
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

                // Description
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

                // Submit
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
