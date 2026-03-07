import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../screens/contributions_screen.dart';
import '../screens/global_search_delegate.dart';

/// Shared AppBar actions used by all main screens:
///  - global search icon
///  - overflow menu with "Contribuciones"
List<Widget> buildAppBarActions(BuildContext context) {
  return [
    IconButton(
      icon: const Icon(Icons.search),
      tooltip: AppStrings.searchGlobal,
      onPressed: () =>
          showSearch(context: context, delegate: GlobalSearchDelegate()),
    ),
    PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'contributions') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ContributionsScreen(),
            ),
          );
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'contributions',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.rate_review),
            title: Text(AppStrings.contributionsMenuLabel),
          ),
        ),
      ],
    ),
  ];
}
