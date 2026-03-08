import '../models/schema_item.dart';

// ──────────────────────────────────────────────────────────────────────────────
// REGISTRO DE ESQUEMAS B737
// ──────────────────────────────────────────────────────────────────────────────
// Para añadir un esquema:
//   1. Coloca el PDF en assets/schemas/ataXX/nombre_archivo.pdf
//   2. Declara el asset en pubspec.yaml  →  - assets/schemas/ataXX/
//   3. Añade una SchemaEntry en la lista del ATA correspondiente.
//
// Ejemplo:
//   SchemaEntry(
//     id: 'ata21_pack_flow',          // identificador único (para guardar anotaciones)
//     subCode: '21-51',               // sub-ATA
//     title: 'Pack Flow Control',     // nombre visible
//     assetPath: 'assets/schemas/ata21/pack_flow_control.pdf',
//     totalPages: 3,                  // número total de páginas del PDF
//   ),
// ──────────────────────────────────────────────────────────────────────────────

const List<AtaChapter> kSchemaRegistry = [
  AtaChapter(
    ataCode: 'ATA 21',
    title: 'Air Conditioning',
    entries: [
      // Añade esquemas aquí
    ],
  ),
  AtaChapter(
    ataCode: 'ATA 22',
    title: 'Auto Flight',
    entries: [],
  ),
  AtaChapter(
    ataCode: 'ATA 24',
    title: 'Electrical Power',
    entries: [],
  ),
  AtaChapter(
    ataCode: 'ATA 26',
    title: 'Fire Protection',
    entries: [],
  ),
  AtaChapter(
    ataCode: 'ATA 27',
    title: 'Flight Controls',
    entries: [],
  ),
  AtaChapter(
    ataCode: 'ATA 28',
    title: 'Fuel',
    entries: [],
  ),
  AtaChapter(
    ataCode: 'ATA 29',
    title: 'Hydraulic Power',
    entries: [],
  ),
  AtaChapter(
    ataCode: 'ATA 30',
    title: 'Ice & Rain Protection',
    entries: [],
  ),
  AtaChapter(
    ataCode: 'ATA 31',
    title: 'Indicating / Recording',
    entries: [],
  ),
  AtaChapter(
    ataCode: 'ATA 32',
    title: 'Landing Gear',
    entries: [],
  ),
  AtaChapter(
    ataCode: 'ATA 33',
    title: 'Lights',
    entries: [],
  ),
  AtaChapter(
    ataCode: 'ATA 34',
    title: 'Navigation',
    entries: [],
  ),
  AtaChapter(
    ataCode: 'ATA 36',
    title: 'Pneumatic',
    entries: [],
  ),
  AtaChapter(
    ataCode: 'ATA 38',
    title: 'Water / Waste',
    entries: [],
  ),
  AtaChapter(
    ataCode: 'ATA 49',
    title: 'APU',
    entries: [],
  ),
];
