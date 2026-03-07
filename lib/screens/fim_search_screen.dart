import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/data_cache.dart';
import '../widgets/searchable_list.dart';
import '../widgets/app_bar_actions.dart';
import '../widgets/report_sheet.dart';
import 'item_detail_screen.dart';

class FimSearchScreen extends StatefulWidget {
  const FimSearchScreen({super.key});

  @override
  State<FimSearchScreen> createState() => _FimSearchScreenState();
}

class _FimSearchScreenState extends State<FimSearchScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final items = await DataCache.instance.getFimItems();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.fimTitle),
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
                searchKeys: const ['fault', 'desc'],
                searchLabel: AppStrings.fimSearchHint,
                screenId: 'fim',
                itemBuilder: (context, item, isFav, onToggle) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['fault'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isFav ? Icons.star : Icons.star_outline,
                            color: isFav ? Colors.amber : null,
                          ),
                          onPressed: onToggle,
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${item['desc'] ?? ''}\n'
                      '${AppStrings.fimAccion}: ${item['fix'] ?? ''}',
                    ),
                    isThreeLine: true,
                    onLongPress: () => ReportSheet.show(
                      context,
                      itemId: item['id'] as String,
                      itemRef: 'FIM: ${item['fault']} — ${item['desc']}',
                      section: 'FIM',
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemDetailScreen(
                            item: {...item, '_type': 'fim'}),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
