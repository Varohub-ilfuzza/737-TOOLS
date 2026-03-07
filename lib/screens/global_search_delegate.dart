import 'package:flutter/material.dart';
import '../services/data_cache.dart';
import 'item_detail_screen.dart';

class GlobalSearchDelegate extends SearchDelegate<void> {
  @override
  String get searchFieldLabel => 'Buscar en CB, FIM y PN…';

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) =>
      _SearchResults(query: query);

  @override
  Widget buildSuggestions(BuildContext context) =>
      _SearchResults(query: query);
}

// ─────────────────────────────────────────────────────────────────────────────

class _SearchResults extends StatefulWidget {
  final String query;
  const _SearchResults({required this.query});

  @override
  State<_SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<_SearchResults> {
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _search(widget.query);
  }

  @override
  void didUpdateWidget(_SearchResults old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) _search(widget.query);
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      if (mounted) setState(() => _results = []);
      return;
    }
    if (mounted) setState(() => _loading = true);

    final lower = q.toLowerCase();
    final results = <Map<String, dynamic>>[];

    final cb = await DataCache.instance.getCbItems();
    for (final item in cb) {
      if (_matches(item, lower, ['system', 'amm', 'panel'])) {
        results.add({
          ...item,
          '_type': 'cb',
          '_label': item['system'],
          '_sub': 'Panel: ${item['panel']} | ${item['amm']}',
        });
      }
    }

    final fim = await DataCache.instance.getFimItems();
    for (final item in fim) {
      if (_matches(item, lower, ['fault', 'desc'])) {
        results.add({
          ...item,
          '_type': 'fim',
          '_label': item['fault'],
          '_sub': item['desc'],
        });
      }
    }

    final pn = await DataCache.instance.getAllPnItems();
    for (final item in pn) {
      if (_matches(item, lower, ['desc', 'pn', 'ata'])) {
        results.add({
          ...item,
          '_type': 'pn',
          '_label': item['desc'],
          '_sub': 'PN: ${item['pn']} | ATA ${item['ata']}',
        });
      }
    }

    if (mounted) setState(() {
      _results = results;
      _loading = false;
    });
  }

  bool _matches(
      Map<String, dynamic> item, String lower, List<String> keys) {
    return keys.any((k) =>
        (item[k] ?? '').toString().toLowerCase().contains(lower));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (widget.query.trim().isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Escribe para buscar en CB, FIM y PN',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text('Sin resultados', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (ctx, i) {
        final item = _results[i];
        final type = item['_type'] as String;
        return ListTile(
          leading: _TypeChip(type: type),
          title: Text(item['_label'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(item['_sub'] ?? ''),
          onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => ItemDetailScreen(item: item),
            ),
          ),
        );
      },
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      'cb' => ('CB', Colors.blueGrey),
      'fim' => ('FIM', Colors.orange),
      'pn' => ('PN', Colors.teal),
      _ => ('?', Colors.grey),
    };
    return Container(
      width: 42,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
