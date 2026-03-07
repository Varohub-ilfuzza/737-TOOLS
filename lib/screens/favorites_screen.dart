import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/data_cache.dart';
import '../services/favorites_service.dart';
import '../widgets/app_bar_actions.dart';
import '../widgets/cb_item_card.dart';
import '../widgets/pn_item_card.dart';
import '../widgets/report_sheet.dart';
import 'item_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> _cbFavs = [];
  List<Map<String, dynamic>> _fimFavs = [];
  List<Map<String, dynamic>> _pnFavs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final cbIds = await FavoritesService.load('cb');
    final fimIds = await FavoritesService.load('fim');
    final pnIds = await FavoritesService.load('pn');

    final allCb = await DataCache.instance.getCbItems();
    final allFim = await DataCache.instance.getFimItems();
    final allPn = await DataCache.instance.getAllPnItems();

    if (mounted) {
      setState(() {
        _cbFavs = allCb.where((i) => cbIds.contains(i['id']?.toString())).toList();
        _fimFavs = allFim.where((i) => fimIds.contains(i['id']?.toString())).toList();
        _pnFavs = allPn.where((i) => pnIds.contains(i['id']?.toString())).toList();
        _loading = false;
      });
    }
  }

  Future<void> _removeCbFav(String id) async {
    await FavoritesService.toggle('cb', id);
    await _loadFavorites();
  }

  Future<void> _removeFimFav(String id) async {
    await FavoritesService.toggle('fim', id);
    await _loadFavorites();
  }

  Future<void> _removePnFav(String id) async {
    await FavoritesService.toggle('pn', id);
    await _loadFavorites();
  }

  bool get _isEmpty => _cbFavs.isEmpty && _fimFavs.isEmpty && _pnFavs.isEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navFavorites),
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
        actions: buildAppBarActions(context),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.noFavorites,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.favoritesHint,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (_cbFavs.isNotEmpty) ...[
                        _SectionHeader(label: AppStrings.navBreakers, icon: Icons.electrical_services),
                        ..._cbFavs.map((item) => CbItemCard(
                              item: item,
                              isFavorite: true,
                              onToggleFavorite: () => _removeCbFav(item['id'].toString()),
                            )),
                        const SizedBox(height: 8),
                      ],
                      if (_fimFavs.isNotEmpty) ...[
                        _SectionHeader(label: AppStrings.navFim, icon: Icons.menu_book),
                        ..._fimFavs.map((item) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.warning, color: Colors.orange),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['fault'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.star, color: Colors.amber),
                                      onPressed: () => _removeFimFav(item['id'].toString()),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  '${item['desc'] ?? ''}\n${AppStrings.fimAccion}: ${item['fix'] ?? ''}',
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
                                    builder: (_) =>
                                        ItemDetailScreen(item: {...item, '_type': 'fim'}),
                                  ),
                                ),
                              ),
                            )),
                        const SizedBox(height: 8),
                      ],
                      if (_pnFavs.isNotEmpty) ...[
                        _SectionHeader(label: AppStrings.navCommonPn, icon: Icons.build_circle),
                        ..._pnFavs.map((item) => PnItemCard(
                              item: item,
                              isFavorite: true,
                              onToggleFavorite: () => _removePnFav(item['id'].toString()),
                            )),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0033A0)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF0033A0),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
