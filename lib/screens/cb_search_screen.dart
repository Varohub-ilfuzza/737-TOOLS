import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/data_cache.dart';
import '../widgets/cb_item_card.dart';
import '../widgets/searchable_list.dart';
import '../widgets/app_bar_actions.dart';

class CbSearchScreen extends StatefulWidget {
  const CbSearchScreen({super.key});

  @override
  State<CbSearchScreen> createState() => _CbSearchScreenState();
}

class _CbSearchScreenState extends State<CbSearchScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final items = await DataCache.instance.getCbItems();
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
        title: const Text(AppStrings.cbTitle),
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
                searchKeys: const ['system'],
                searchLabel: AppStrings.cbSearchHint,
                screenId: 'cb',
                itemBuilder: (context, item, isFav, onToggle) => CbItemCard(
                  item: item,
                  isFavorite: isFav,
                  onToggleFavorite: onToggle,
                ),
              ),
            ),
    );
  }
}
