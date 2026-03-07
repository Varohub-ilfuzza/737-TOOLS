import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../services/search_history_service.dart';
import '../l10n/app_strings.dart';

/// Generic search list with integrated favorites and search history.
/// Each item in [items] must have an 'id' String field.
class SearchableList extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  /// Map keys used for filtering (e.g. ['system'] or ['fault', 'desc'])
  final List<String> searchKeys;

  /// Builder for each list item. Receives the item, favorite state,
  /// and a callback to toggle the favorite.
  final Widget Function(
    BuildContext context,
    Map<String, dynamic> item,
    bool isFavorite,
    VoidCallback onToggleFavorite,
  ) itemBuilder;

  final String searchLabel;

  /// Unique identifier for this screen's favorites & history in SharedPreferences
  final String screenId;

  const SearchableList({
    super.key,
    required this.items,
    required this.searchKeys,
    required this.itemBuilder,
    required this.searchLabel,
    required this.screenId,
  });

  @override
  State<SearchableList> createState() => _SearchableListState();
}

class _SearchableListState extends State<SearchableList> {
  List<Map<String, dynamic>> _filtered = [];
  Set<String> _favorites = {};
  List<String> _history = [];
  bool _onlyFavorites = false;
  bool _showHistory = false;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _filtered = List.from(widget.items);
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    _init();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final favs = await FavoritesService.load(widget.screenId);
    final hist = await SearchHistoryService.load(widget.screenId);
    if (mounted) {
      setState(() {
        _favorites = favs;
        _history = hist;
      });
    }
  }

  void _onTextChanged() {
    _applyFilter(_controller.text);
    _updateHistoryVisibility();
  }

  void _onFocusChanged() {
    _updateHistoryVisibility();
  }

  void _updateHistoryVisibility() {
    if (mounted) {
      setState(() {
        _showHistory =
            _focusNode.hasFocus &&
            _controller.text.isEmpty &&
            _history.isNotEmpty;
      });
    }
  }

  void _applyFilter(String keyword) {
    if (!mounted) return;
    setState(() {
      if (keyword.isEmpty) {
        _filtered = _onlyFavorites
            ? widget.items
                .where((i) => _favorites.contains((i['id'] ?? '').toString()))
                .toList()
            : List.from(widget.items);
      } else {
        _filtered = widget.items.where((i) {
          final matchSearch = widget.searchKeys.any(
            (k) => (i[k] ?? '')
                .toString()
                .toLowerCase()
                .contains(keyword.toLowerCase()),
          );
          final matchFav =
              !_onlyFavorites ||
              _favorites.contains((i['id'] ?? '').toString());
          return matchSearch && matchFav;
        }).toList();
      }
    });

    if (keyword.isNotEmpty) {
      SearchHistoryService.add(widget.screenId, keyword).then((_) async {
        final hist = await SearchHistoryService.load(widget.screenId);
        if (mounted) setState(() => _history = hist);
      });
    }
  }

  void _selectFromHistory(String term) {
    _controller.text = term;
    _controller.selection =
        TextSelection.fromPosition(TextPosition(offset: term.length));
    _applyFilter(term);
    _focusNode.unfocus();
  }

  Future<void> _toggleFavorite(String id) async {
    await FavoritesService.toggle(widget.screenId, id);
    final favs = await FavoritesService.load(widget.screenId);
    if (mounted) {
      setState(() => _favorites = favs);
      // Re-apply filter so the item disappears from list if "only favorites" is active
      if (_onlyFavorites) _applyFilter(_controller.text);
    }
  }

  void _toggleFavoritesFilter() {
    setState(() => _onlyFavorites = !_onlyFavorites);
    _applyFilter(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search field ──────────────────────────────────────────────
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.searchLabel,
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Borrar',
                    onPressed: () {
                      _controller.clear();
                      _applyFilter('');
                    },
                  ),
                IconButton(
                  icon: Icon(
                    _onlyFavorites ? Icons.star : Icons.star_outline,
                    color: _onlyFavorites ? Colors.amber : null,
                  ),
                  tooltip: AppStrings.favoritesFilter,
                  onPressed: _toggleFavoritesFilter,
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.search),
                ),
              ],
            ),
          ),
        ),

        // ── Search history ────────────────────────────────────────────
        if (_showHistory)
          Card(
            margin: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    AppStrings.searchHistoryLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ..._history.map(
                  (term) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.history, size: 18),
                    title: Text(term),
                    onTap: () => _selectFromHistory(term),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 10),

        // ── List ──────────────────────────────────────────────────────
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(
                    _onlyFavorites
                        ? AppStrings.noFavorites
                        : AppStrings.noResults,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (ctx, i) {
                    final item = _filtered[i];
                    final id = (item['id'] ?? '').toString();
                    final isFav = _favorites.contains(id);
                    return widget.itemBuilder(
                      ctx,
                      item,
                      isFav,
                      () => _toggleFavorite(id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
