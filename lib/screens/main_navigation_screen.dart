import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import 'cb_search_screen.dart';
import 'fim_search_screen.dart';
import 'common_pn_screen.dart';
import 'revisions_screen.dart';
import 'favorites_screen.dart';
import 'schemas_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    CbSearchScreen(),
    FimSearchScreen(),
    CommonPnScreen(),
    RevisionsScreen(),
    FavoritesScreen(),
    SchemasScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.electrical_services),
            label: AppStrings.navBreakers,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: AppStrings.navFim,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_circle),
            label: AppStrings.navCommonPn,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: AppStrings.navRevisiones,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: AppStrings.navFavorites,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schema),
            label: AppStrings.navSchemas,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF0033A0),
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
