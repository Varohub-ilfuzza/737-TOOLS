class AtaChapter {
  final String ataCode;
  final String title;
  final List<SchemaEntry> entries;

  const AtaChapter({
    required this.ataCode,
    required this.title,
    required this.entries,
  });
}

class SchemaEntry {
  final String id;
  final String subCode;
  final String title;
  final String assetPath;
  final int totalPages;

  const SchemaEntry({
    required this.id,
    required this.subCode,
    required this.title,
    required this.assetPath,
    this.totalPages = 1,
  });
}
