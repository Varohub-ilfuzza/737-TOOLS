import 'package:flutter/material.dart';
import '../data/schemas_registry.dart';
import '../models/schema_item.dart';
import '../l10n/app_strings.dart';
import 'schema_viewer_screen.dart';

class SchemasScreen extends StatefulWidget {
  const SchemasScreen({super.key});

  @override
  State<SchemasScreen> createState() => _SchemasScreenState();
}

class _SchemasScreenState extends State<SchemasScreen> {
  int? _expandedIndex;

  // Show only ATAs that have entries, or all? Toggle:
  bool _showAll = true;

  List<AtaChapter> get _visible => _showAll
      ? kSchemaRegistry
      : kSchemaRegistry.where((a) => a.entries.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.schemasTitle),
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
        actions: [
          Tooltip(
            message: _showAll
                ? AppStrings.schemasFilterActive
                : AppStrings.schemasFilterAll,
            child: IconButton(
              icon: Icon(
                _showAll ? Icons.filter_list_off : Icons.filter_list,
              ),
              onPressed: () {
                setState(() {
                  _showAll = !_showAll;
                  _expandedIndex = null;
                });
              },
            ),
          ),
        ],
      ),
      body: _visible.isEmpty
          ? _buildEmptyAll()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _visible.length,
              itemBuilder: (context, index) =>
                  _buildAtaCard(context, _visible[index], index),
            ),
    );
  }

  Widget _buildAtaCard(BuildContext context, AtaChapter chapter, int index) {
    final isExpanded = _expandedIndex == index;
    final hasEntries = chapter.entries.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          ListTile(
            leading: _AtaBadge(code: chapter.ataCode.split(' ').last),
            title: Text(
              chapter.ataCode,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              chapter.title,
              style: const TextStyle(fontSize: 13),
            ),
            trailing: hasEntries
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CountBadge(count: chapter.entries.length),
                      const SizedBox(width: 4),
                      Icon(isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more),
                    ],
                  )
                : _PendingBadge(),
            onTap: hasEntries
                ? () => setState(
                      () => _expandedIndex = isExpanded ? null : index,
                    )
                : null,
          ),
          if (isExpanded && hasEntries)
            ...chapter.entries.map((e) => _buildEntryTile(context, e)),
        ],
      ),
    );
  }

  Widget _buildEntryTile(BuildContext context, SchemaEntry entry) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SchemaViewerScreen(entry: entry)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black12)),
          color: Color(0xFFF8F9FF),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.only(left: 68, right: 12, top: 2, bottom: 2),
          leading: const Icon(Icons.picture_as_pdf,
              color: Color(0xFF0033A0), size: 22),
          title: Text(
            entry.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            '${entry.subCode}  ·  ${entry.totalPages} ${entry.totalPages == 1 ? AppStrings.schemasPage : AppStrings.schemasPages}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildEmptyAll() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schema_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              AppStrings.schemasEmpty,
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.schemasEmptyHint,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _AtaBadge extends StatelessWidget {
  final String code;
  const _AtaBadge({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0033A0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          code,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0033A0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Text(
        AppStrings.schemasPending,
        style: TextStyle(fontSize: 10, color: Colors.orange.shade800),
      ),
    );
  }
}
