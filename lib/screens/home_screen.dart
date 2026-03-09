import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'cb_search_screen.dart';
import 'fim_search_screen.dart';
import 'common_pn_screen.dart';
import 'revisions_screen.dart';
import 'favorites_screen.dart';
import 'schemas_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color _primary = Color(0xFF0033A0);
  static const Color _accent = Color(0xFFD4AF37); // Dorado aeronáutico

  static const List<_MenuSection> _sections = [
    _MenuSection(
      label: 'Circuit\nBreakers',
      icon: Icons.electrical_services,
      color: Color(0xFF1A237E),
      screen: CbSearchScreen(),
    ),
    _MenuSection(
      label: 'FIM /\nFallos',
      icon: Icons.menu_book,
      color: Color(0xFF0D47A1),
      screen: FimSearchScreen(),
    ),
    _MenuSection(
      label: 'Common\nPN',
      icon: Icons.build_circle,
      color: Color(0xFF1565C0),
      screen: CommonPnScreen(),
    ),
    _MenuSection(
      label: 'Revisiones',
      icon: Icons.checklist_rtl,
      color: Color(0xFF0277BD),
      screen: RevisionsScreen(),
    ),
    _MenuSection(
      label: 'Favoritos',
      icon: Icons.star_rounded,
      color: Color(0xFF00695C),
      screen: FavoritesScreen(),
    ),
    _MenuSection(
      label: 'Esquemas',
      icon: Icons.picture_as_pdf_rounded,
      color: Color(0xFF37474F),
      screen: SchemasScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sections.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) =>
                      _SectionCard(section: _sections[index]),
                ),
              ),
            ),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

// ── HEADER ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: HomeScreen._primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Boeing logo: texto blanco sobre fondo azul con borde
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                ),
                child: const Text(
                  'BOEING',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'B737 Tools',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Tools / AMT',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: HomeScreen._accent.withOpacity(0.6)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: HomeScreen._accent, size: 16),
                SizedBox(width: 8),
                Text(
                  'Selecciona una sección para continuar',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── FOOTER ───────────────────────────────────────────────────────────────────

class _Footer extends StatefulWidget {
  const _Footer();

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  String _dbDate = '—';

  @override
  void initState() {
    super.initState();
    _loadDbDate();
  }

  Future<void> _loadDbDate() async {
    try {
      final raw = await rootBundle.loadString('assets/data_version.json');
      final map = json.decode(raw) as Map<String, dynamic>;
      final date = map['updated'] as String? ?? '—';
      if (mounted) setState(() => _dbDate = date);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: HomeScreen._primary.withOpacity(0.07),
        border: Border(
          top: BorderSide(color: HomeScreen._primary.withOpacity(0.15)),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FooterChip(
                icon: Icons.info_outline,
                label: 'v0.5.0',
              ),
              _FooterChip(
                icon: Icons.update_rounded,
                label: 'BD: $_dbDate',
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Created by Varo · © 2026 Todos los derechos reservados',
            style: TextStyle(
              color: Color(0xFF0033A0),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FooterChip extends StatelessWidget {
  const _FooterChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF0033A0).withOpacity(0.6)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF0033A0).withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── TARJETA DE SECCIÓN ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});
  final _MenuSection section;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => section.screen),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: section.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: section.color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(section.icon, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 12),
              Text(
                section.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── MODELO INTERNO ────────────────────────────────────────────────────────────

class _MenuSection {
  const _MenuSection({
    required this.label,
    required this.icon,
    required this.color,
    required this.screen,
  });
  final String label;
  final IconData icon;
  final Color color;
  final Widget screen;
}
